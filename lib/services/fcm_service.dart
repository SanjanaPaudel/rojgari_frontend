import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_urls.dart';
import '../screens/notifications_screen.dart';
import '../screens/technician/profile_screen.dart';
import '../widgets/notification_permission_dialog.dart';
import 'api_service.dart';
import 'navigation_service.dart';

// The FCM `data` payload's `type` values that carry an admin worker-
// verification decision. The backend sends these on approve/reject
// (NotificationService.send_to_user → data: {"type": ..., "worker_id": ...}).
const Set<String> _verificationDataTypes = {
  'worker_verification_approved',
  'worker_verification_rejected',
};

bool _isVerificationMessage(RemoteMessage message) =>
    _verificationDataTypes.contains(message.data['type']);

// Generated in Firebase console > Project settings > Cloud Messaging > Web
// Push certificates. Required by getToken() on web only; native platforms
// ignore it.
const String _webVapidKey =
    'BFrAbxwY4VCqHMucWg_KNwQQll64R6mptIQwQKflG9Du51saXlm8SZX3cyJJXPZlqIc5NjjeqoYqaq9AKJZloRE';

// Must be a top-level function — FCM invokes this in a separate isolate when
// a message arrives while the app is backgrounded/terminated. Android/iOS
// already show the system tray notification from the payload's
// `notification` block automatically for both types the backend sends
// today, so there's nothing else to do here yet.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Wires up push notifications: permission request, registering this
/// device's token with the backend, and routing a notification tap.
///
/// [initialize] is called from both CustomerHomeScreen's and
/// TechnicianHomeScreen's initState — safe to call on every mount, since
/// [_registeredThisSession] makes repeat calls within the same login a
/// no-op. Call [resetSession] right after clearing local auth state on
/// logout so the next login (same device, possibly a different account)
/// registers the token again — the backend associates each token with
/// whichever user last registered it.
class FcmService {
  FcmService._();

  /// Bumped every time an admin worker-verification decision (approved or
  /// rejected) arrives while the app is running, or is tapped to open the
  /// app. Screens that display the worker's verification status (the
  /// technician home dashboard) listen to this and re-fetch their status so
  /// the badge flips live, without the worker needing to pull-to-refresh.
  ///
  /// A process-lifetime [ValueNotifier] rather than a stream so late
  /// listeners (a home screen mounted after the message arrived) simply read
  /// the current value; it is never disposed because it lives as long as the
  /// app. Listeners must still remove themselves in their own dispose().
  static final ValueNotifier<int> verificationStatusChanged =
      ValueNotifier<int>(0);

  static bool _listenersRegistered = false;

  // Guards the priming-dialog/permission/getToken/register block, not just
  // the listener subscriptions below — initialize() is called from both
  // home screens' initState, which reruns on every fresh mount (re-login,
  // navigating back to home, etc.), not just once per app process. Without
  // this, the same token gets POSTed to the backend again on every mount,
  // which is what was producing duplicate device rows (and duplicate Chrome
  // notifications) server-side.
  static bool _registeredThisSession = false;

  /// Call right after clearing local auth state on logout. The backend
  /// associates a device token with whichever user last registered it
  /// (DeviceTokenService.register_device), so if a different account logs
  /// in on the same device within the same app process, it needs its own
  /// fresh registration — without this reset, the token would stay silently
  /// tied to the previous account.
  static void resetSession() {
    _registeredThisSession = false;
  }

  static Future<void> initialize() async {
    try {
      await _doInitialize();
    } catch (error) {
      // Notifications are a best-effort feature, not a login requirement —
      // a blocked permission (getToken() throws when denied), a missing
      // service worker, or any other setup failure here must never break
      // login or splash-screen navigation.
      debugPrint('FcmService.initialize failed: $error');
    }
  }

  static Future<void> _doInitialize() async {
    final messaging = FirebaseMessaging.instance;

    if (!_registeredThisSession) {
      // Only show the custom "priming" dialog when the real permission
      // hasn't been decided yet — once the user (or a past visit) has
      // already answered the native prompt, there's nothing left to prime.
      final currentSettings = await messaging.getNotificationSettings();
      if (currentSettings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        final dialogContext = NavigationService.navigatorKey.currentContext;
        if (dialogContext != null) {
          final wantsNotifications = await NotificationPermissionDialog.show(
            dialogContext,
          );
          // "Not now" leaves the real permission untouched (never called
          // requestPermission) and _registeredThisSession stays false, so
          // this dialog can simply be shown again on a later visit — no
          // permission was burned, and no retry is lost.
          if (!wantsNotifications) return;
        }
      }

      await messaging.requestPermission();

      final token = await messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      if (token != null) {
        // Only latch the guard on a real success — a failed POST (network
        // hiccup, backend down) must still be retried on the next mount,
        // same as before this guard existed.
        _registeredThisSession = await _registerToken(token);
      }
    }

    if (_listenersRegistered) return;
    _listenersRegistered = true;

    messaging.onTokenRefresh.listen(_registerToken);

    // Foreground delivery: Android/iOS do NOT show a system tray banner for
    // a message received while the app is in the foreground, so without a
    // local-notifications package this only reaches app logs, not the user.
    // Fine for now since the two live types are single fire-and-forget
    // events, but worth adding flutter_local_notifications later if an
    // in-app banner is wanted while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground message: ${message.notification?.title} — '
        '${message.notification?.body}',
      );
      // A verification decision that lands while the worker is actively using
      // the app: nudge any status-showing screen to re-fetch so the badge
      // updates live (they won't see the system tray banner in the
      // foreground). Safe for non-worker/customer sessions too — nothing is
      // listening there, so the bump is simply ignored.
      if (_isVerificationMessage(message)) {
        verificationStatusChanged.value++;
      }
    });

    // App was in the background (not terminated) when the notification was
    // tapped.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App was terminated and opened by tapping the notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTap(initialMessage);
    }
  }

  /// Returns whether the POST actually succeeded, so [_doInitialize] knows
  /// whether it's safe to latch [_registeredThisSession]. Also used
  /// directly as the `onTokenRefresh` listener below — a `bool`-returning
  /// function is still assignable there since Dart discards the return
  /// value for a `void Function(T)` callback.
  static Future<bool> _registerToken(String token) async {
    try {
      await ApiService().post(ApiUrls.deviceToken, {
        "device_token": token,
        // Backend only accepts "android"/"ios" (DeviceTokenSerializer
        // ChoiceField) — there's no "web" option, so web sessions are
        // labeled "android" here. The token itself is still a real FCM
        // token either way; only this informational label is approximated.
        "device_type": !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? "ios"
            : "android",
      });
      return true;
    } catch (_) {
      // Best-effort — a failed registration here shouldn't block app usage;
      // it retries next time initialize() runs (next login/app start).
      return false;
    }
  }

  // Booking types (booking_accepted, booking_rejected) carry a booking_id,
  // but there's no screen yet that can open a specific booking from just its
  // id — the existing tracking screens (ServiceOnTheWayScreen etc.) require
  // the full booking context built up during the create/poll flow, not just
  // an id. Land on the notifications list for those.
  //
  // A worker-verification decision, though, is about the worker's own
  // account, so a tap opens their profile screen where the verification
  // badge now reflects the admin's decision. TechnicianProfileScreen fetches
  // its own profile on open, so it needs no arguments here. We also bump
  // [verificationStatusChanged] so the home dashboard behind it refreshes,
  // and the badge is already correct when the worker pops back.
  static void _handleTap(RemoteMessage message) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    if (_isVerificationMessage(message)) {
      verificationStatusChanged.value++;
      navigator.push(
        MaterialPageRoute(builder: (_) => const TechnicianProfileScreen()),
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
