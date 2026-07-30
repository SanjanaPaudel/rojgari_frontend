import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_urls.dart';
import '../screens/notifications_screen.dart';
import '../widgets/notification_permission_dialog.dart';
import 'api_service.dart';
import 'navigation_service.dart';

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
/// Call [initialize] once after a successful login, and again on app start
/// when a session is already valid (see LoginScreen and SplashScreen) — the
/// backend note asks for the token to be (re)sent on every login.
class FcmService {
  FcmService._();

  static bool _listenersRegistered = false;

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

    // Only show the custom "priming" dialog when the real permission hasn't
    // been decided yet — once the user (or a past visit) has already
    // answered the native prompt, there's nothing left to prime.
    final currentSettings = await messaging.getNotificationSettings();
    if (currentSettings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      final dialogContext = NavigationService.navigatorKey.currentContext;
      if (dialogContext != null) {
        final wantsNotifications = await NotificationPermissionDialog.show(
          dialogContext,
        );
        // "Not now" leaves the real permission untouched (never called
        // requestPermission), so this dialog can simply be shown again on
        // a later visit — no permission was burned.
        if (!wantsNotifications) return;
      }
    }

    await messaging.requestPermission();

    final token = await messaging.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    if (token != null) {
      await _registerToken(token);
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

  static Future<void> _registerToken(String token) async {
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
    } catch (_) {
      // Best-effort — a failed registration here shouldn't block app usage;
      // it retries next time initialize() runs (next login/app start).
    }
  }

  // Both live notification types (booking_accepted, booking_rejected) carry
  // a booking_id, but there's no screen yet that can open a specific booking
  // from just its id — the existing tracking screens (ServiceOnTheWayScreen
  // etc.) require the full booking context built up during the create/poll
  // flow, not just an id. Land on the notifications list until that exists.
  static void _handleTap(RemoteMessage message) {
    NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
