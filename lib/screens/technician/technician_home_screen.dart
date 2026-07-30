import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../models/incoming_request_model.dart';
import '../../models/technician_model.dart';
import '../../models/worker_dashboard_response.dart';
import '../../services/location/location_service.dart';
import '../../services/incoming_requests_store.dart';
import '../../services/worker_dashboard_service.dart';

import '../../widgets/technician/dashboard_appbar.dart';
import '../../widgets/technician/incoming_request_card.dart';
import '../../widgets/technician/profile_header.dart';
import '../../widgets/technician/stat_card.dart';
import '../../widgets/technician/pro_tip_card.dart';
import '../notifications_screen.dart';
import 'incoming_request_details_loader.dart';
import 'incoming_requests_screen.dart';
import 'profile_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({
    super.key,
    this.initialTechnician,
    this.signupSelectedSkills,
  });

  final TechnicianModel? initialTechnician;
  final List<String>? signupSelectedSkills;

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  final WorkerDashboardService _dashboardService = WorkerDashboardService();
  final LocationService _locationService = const LocationService();

  WorkerDashboardResponse? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  late bool isOnline;
  late TechnicianModel _profile;

  // ── Location reporting state ──────────────────────────────────────────────

  /// Drives the periodic location upload while the worker is online.
  Timer? _locationTimer;

  /// How often the worker's location is sent to the backend while online.
  ///
  /// This is a fixed time interval, not a distance trigger: the worker's
  /// position is reported every 30 seconds whether or not they have moved.
  static const Duration _locationUpdateInterval = Duration(seconds: 30);

  /// Guards against overlapping uploads if one tick's request has not finished
  /// before the next timer tick fires.
  bool _isSendingLocation = false;

  /// True while an async permission-check + backend toggle round-trip is
  /// in progress — prevents double-taps and shows a loading indicator.
  bool _isTogglingStatus = false;

  /// Consecutive location-upload failures while online.
  /// After [_maxLocationFailures] failures we auto-toggle offline.
  int _locationFailureCount = 0;
  static const int _maxLocationFailures = 5;

  /// The last reported location — used to compute distance travelled between
  /// consecutive uploads for debug logging.
  CurrentDeviceLocation? _previousLocation;

  @override
  void initState() {
    super.initState();
    // Set safe defaults before the API responds.
    isOnline = false;
    _profile =
        widget.initialTechnician ??
        TechnicianModel(
          fullName: '',
          phone: '',
          email: '',
          about: '',
          selectedSkills: widget.signupSelectedSkills ?? const [],
        );
    _loadDashboard();
    // The "New requests near you" preview reads from the shared
    // IncomingRequestsStore (also used by IncomingRequestsScreen's "View
    // All") rather than fetching its own copy — see that file for why.
    IncomingRequestsStore.instance.attach();
    IncomingRequestsStore.instance.refreshNow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationOnStartup();
    });
  }

  /// Opens the detail page for a pending offer. It pops `true` after a
  /// successful accept, which makes the shared list stale until refreshed.
  Future<void> _openRequestDetails(IncomingRequest request) async {
    IncomingRequestsStore.instance.markViewed(request.id);
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingRequestDetailsLoader(offerId: request.id),
      ),
    );
    if (accepted == true) await IncomingRequestsStore.instance.refreshNow();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    IncomingRequestsStore.instance.detach();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _dashboardService.fetchDashboard();
      final profile = await _dashboardService.getProfile();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
        isOnline = dashboard.worker.isOnline;
        // Merge the complete profile data with dashboard skills/verification.
        //
        // verificationStatus resolution:
        //   • dashboard.worker.verified == true  → admin-verified; always use verified
        //   • dashboard.worker.verified == false → use the status fromProfileJson
        //     computed from citizenship_front / citizenship_back URL presence:
        //       - both URLs present  → pending (docs submitted, awaiting admin)
        //       - URLs absent        → incomplete (worker hasn't uploaded docs yet)
        //
        // This is the ONLY correct way to persist "pending" across refreshes,
        // because the dashboard "verified" field is a binary true/false and
        // cannot distinguish the three states on its own.
        _profile = profile.copyWith(
          selectedSkills: List<String>.from(dashboard.worker.skills),
          verificationStatus: dashboard.worker.verified
              ? TechnicianVerificationStatus.verified
              : profile.verificationStatus, // pending or incomplete from getProfile()
        );
      });

      // If the worker was online when they last closed the app, resume the
      // periodic location updates after verifying permission is still granted.
      if (dashboard.worker.isOnline) {
        final permission = await _locationService.checkPermission();
        final serviceEnabled = await _locationService.isLocationServiceEnabled();
        if (permission == AppLocationPermission.granted && serviceEnabled) {
          _startLocationUpdates();
        } else {
          // Permission revoked or service disabled since last session — force offline.
          _forceToggleOffline(
            reason: 'Location access was lost. You have been set to Offline.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkLocationOnStartup() async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      final permission = await _locationService.checkPermission();

      if (!serviceEnabled || permission != AppLocationPermission.granted) {
        if (mounted) {
          _showLocationPermissionDialog();
        }
      }
    } catch (e) {
      debugPrint('Error checking location status on startup: $e');
    }
  }

  /// Shows the custom location permission dialog.
  /// Returns [true] if permission was ultimately granted, [false] otherwise.
  Future<bool> _showLocationPermissionDialog() async {
    final completer = Completer<bool>();
    if (!mounted) return false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _LocationPermissionDialog(
          onAllowWhileUsing: () async {
            Navigator.pop(context);
            final granted = await _handleRequestPermission();
            completer.complete(granted);
          },
          onAllowThisTime: () async {
            Navigator.pop(context);
            final granted = await _handleRequestPermission();
            completer.complete(granted);
          },
          onDeny: () {
            Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location permission is required to go online and receive job requests.',
                  ),
                  backgroundColor: AppColors.red,
                ),
              );
            }
            completer.complete(false);
          },
        );
      },
    );
    return completer.future;
  }

  /// Triggers the OS permission request and returns whether access was granted.
  Future<bool> _handleRequestPermission() async {
    try {
      setState(() => _isTogglingStatus = true);
      final permission = await _locationService.requestPermission();
      if (!mounted) return false;

      if (permission == AppLocationPermission.granted) {
        final serviceEnabled = await _locationService.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showServiceDisabledSnackbar();
          return false;
        }
        return true;
      } else if (permission == AppLocationPermission.blocked) {
        _showPermissionBlockedDialog();
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission was denied.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  void _showServiceDisabledSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Device location service is disabled. Please turn it on in system settings.',
        ),
        backgroundColor: AppColors.orange,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => _locationService.openLocationSettings(),
        ),
      ),
    );
  }

  void _showPermissionBlockedDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location Permission Blocked',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Location permission has been permanently denied. Please enable it in device app settings to receive job requests.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _locationService.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // ── Toggle handlers ────────────────────────────────────────────────────────

  /// Called when the worker taps the toggle towards **Online**.
  Future<void> _handleToggleOnline() async {
    if (_isTogglingStatus) return;

    // 1. Check if location service is enabled and permission already granted.
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    final permission = await _locationService.checkPermission();

    bool locationReady =
        serviceEnabled && permission == AppLocationPermission.granted;

    // 2. If not ready, show the permission dialog and await result.
    if (!locationReady) {
      setState(() => _isTogglingStatus = true);
      locationReady = await _showLocationPermissionDialog();
      if (mounted) setState(() => _isTogglingStatus = false);
    }

    if (!locationReady || !mounted) return;

    // 3. Optimistic UI update.
    setState(() {
      isOnline = true;
      _isTogglingStatus = true;
    });

    try {
      // 4. Inform backend of the new status.
      await _dashboardService.updateOnlineStatus(true);
      // 5. Start streaming location to the backend.
      _startLocationUpdates();
    } catch (e) {
      // 6. Rollback on failure.
      if (!mounted) return;
      setState(() => isOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  /// Called when the worker taps the toggle towards **Offline**.
  Future<void> _handleToggleOffline() async {
    if (_isTogglingStatus) return;

    // 1. Stop streaming immediately.
    _stopLocationUpdates();

    // 2. Optimistic UI update.
    setState(() {
      isOnline = false;
      _isTogglingStatus = true;
    });

    try {
      await _dashboardService.updateOnlineStatus(false);
    } catch (e) {
      // Rollback: if the API failed the worker might still be online on the
      // backend, but we keep them offline locally and show the error.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  /// Forces the worker offline — used when location access is revoked while
  /// the worker is online, or on session restore when permission was lost.
  Future<void> _forceToggleOffline({required String reason}) async {
    _stopLocationUpdates();
    if (!mounted) return;
    setState(() => isOnline = false);
    try {
      await _dashboardService.updateOnlineStatus(false);
    } catch (_) {
      // Best-effort — log silently; UI is already showing offline.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  // ── Location reporting lifecycle ────────────────────────────────────────────

  /// Starts reporting the worker's location every [_locationUpdateInterval].
  ///
  /// The first report is sent immediately so the backend is not blind for the
  /// first interval after the worker goes online.
  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationFailureCount = 0;

    _sendLocationUpdate();
    _locationTimer = Timer.periodic(
      _locationUpdateInterval,
      (_) => _sendLocationUpdate(),
    );
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationFailureCount = 0;
    _isSendingLocation = false;
    _previousLocation = null;
  }

  /// Reads one GPS fix and PATCHes it to /api/auth/worker/location/.
  ///
  /// Runs on a fixed 30-second timer rather than per metre travelled, so the
  /// worker is reported at a steady cadence regardless of movement.
  Future<void> _sendLocationUpdate() async {
    // A slow request must not let ticks pile up on top of each other, which
    // could land older fixes after newer ones.
    if (_isSendingLocation) {
      debugPrint('[Location] Skipped tick — previous upload still in flight.');
      return;
    }
    _isSendingLocation = true;

    try {
      final CurrentDeviceLocation location;
      try {
        location = await _locationService.getCurrentLocation();
      } catch (e) {
        // Could not obtain a fix. Only force the worker offline when the cause
        // is permanent — location switched off or permission revoked — so a
        // transient GPS failure just waits for the next tick.
        debugPrint('[Location] ✗ Could not get a fix: $e');
        final serviceEnabled = await _locationService.isLocationServiceEnabled();
        final permission = await _locationService.checkPermission();
        if ((!serviceEnabled || permission != AppLocationPermission.granted) &&
            mounted) {
          _forceToggleOffline(
            reason:
                'Location service was turned off. You have been set to Offline.',
          );
        }
        return;
      }

      // ── Debug: print distance since the last reported location ───────────
      if (_previousLocation != null) {
        final distanceMetres = Geolocator.distanceBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          location.latitude,
          location.longitude,
        );
        debugPrint(
          '[Location] Moved ${distanceMetres.toStringAsFixed(2)} m '
          'since last report → (${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)})',
        );
      } else {
        debugPrint(
          '[Location] First fix: '
          '(${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)})',
        );
      }
      _previousLocation = location;
      // ─────────────────────────────────────────────────────────────────────

      debugPrint(
        '[Location] → Sending PATCH to backend: '
        '(${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)})',
      );

      try {
        await _dashboardService.updateWorkerLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        // Reset only on a successful upload — this counter tracks consecutive
        // upload failures, so resetting it merely because a fix was obtained
        // would stop it ever reaching _maxLocationFailures.
        _locationFailureCount = 0;
        debugPrint('[Location] ✓ PATCH sent successfully.');
      } catch (e) {
        _locationFailureCount++;
        debugPrint('[Location] ✗ Upload failed (#$_locationFailureCount): $e');
        if (_locationFailureCount >= _maxLocationFailures && mounted) {
          _forceToggleOffline(
            reason:
                'Could not send your location to the server. You have been set to Offline.',
          );
        }
      }
    } finally {
      _isSendingLocation = false;
    }
  }

  /// Resolves a profile photo URL/path from the API into a usable URL string.
  /// Returns null when the backend sends null (no photo uploaded yet).
  String? _resolvePhotoUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // Relative path from Django media — prefix with base URL.
    final base = ApiUrls.baseUrl.replaceFirst('/api', '');
    return '$base$raw';
  }

  TechnicianModel _buildProfileFromDashboard(WorkerDashboardResponse d) {
    final verification = d.worker.verified
        ? TechnicianVerificationStatus.verified
        : TechnicianVerificationStatus.incomplete;

    return TechnicianModel(
      fullName: d.worker.fullName,
      phone: d.worker.phoneNumber,
      email: '',
      about: '',
      profileImageUrl: _resolvePhotoUrl(d.worker.profilePhoto),
      selectedSkills: d.worker.skills,
      verificationStatus: verification,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorBody(message: _errorMessage!, onRetry: _loadDashboard)
            : ValueListenableBuilder<List<IncomingRequest>>(
                valueListenable: IncomingRequestsStore.instance.requests,
                builder: (context, requests, _) => _DashboardBody(
                  dashboard: _dashboard!,
                  profile: _profile,
                  isOnline: isOnline,
                  requests: requests,
                  onRequestTap: _openRequestDetails,
                  onCheckIncomingRequests:
                      IncomingRequestsStore.instance.refreshNow,
                  onStatusChanged: (newStatus) {
                    if (_isTogglingStatus) return; // debounce double-taps
                    if (newStatus) {
                      _handleToggleOnline();
                    } else {
                      _handleToggleOffline();
                    }
                  },
                  isTogglingStatus: _isTogglingStatus,
                  onProfileUpdated: (updatedProfile) {
                    setState(() => _profile = updatedProfile);
                  },
                  onMenuTap: () async {
                    final updatedProfile =
                        await Navigator.push<TechnicianModel>(
                          context,
                          MaterialPageRoute<TechnicianModel>(
                            builder: (_) => TechnicianProfileScreen(
                              initialSelectedSkills: _profile.selectedSkills,
                              dashboardResponse: _dashboard,
                            ),
                          ),
                        );
                    if (!mounted || updatedProfile == null) return;
                    setState(() {
                      _profile = updatedProfile;
                      // The dashboard body reads the avatar/name from
                      // _dashboard.worker, not from _profile, so without this
                      // the Home screen keeps showing the pre-edit photo and
                      // name until the dashboard is next reloaded from
                      // scratch (e.g. app restart).
                      if (_dashboard != null) {
                        _dashboard = WorkerDashboardResponse(
                          worker: _dashboard!.worker.copyWith(
                            fullName: updatedProfile.fullName,
                            profilePhoto: updatedProfile.profileImageUrl,
                          ),
                          notifications: _dashboard!.notifications,
                          messages: _dashboard!.messages,
                          incomingRequestCount:
                              _dashboard!.incomingRequestCount,
                        );
                      }
                    });
                  },
                  resolvePhotoUrl: _resolvePhotoUrl,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted stateless body — keeps the build method lean.
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.profile,
    required this.isOnline,
    required this.requests,
    required this.onRequestTap,
    required this.onCheckIncomingRequests,
    required this.onStatusChanged,
    required this.onProfileUpdated,
    required this.onMenuTap,
    required this.resolvePhotoUrl,
    required this.isTogglingStatus,
  });

  final WorkerDashboardResponse dashboard;
  final TechnicianModel profile;
  final bool isOnline;
  final List<IncomingRequest> requests;
  final ValueChanged<IncomingRequest> onRequestTap;
  final VoidCallback onCheckIncomingRequests;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<TechnicianModel> onProfileUpdated;
  final VoidCallback onMenuTap;
  final String? Function(String?) resolvePhotoUrl;
  final bool isTogglingStatus;

  @override
  Widget build(BuildContext context) {
    final w = dashboard.worker;
    final stats = w.stats;
    final avatarUrl = resolvePhotoUrl(w.profilePhoto);
    final avatarImage = avatarUrl ?? 'assets/images/technician_avatar.png';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 0),

          Transform.translate(
            offset: const Offset(0, -3),
            child: DashboardAppbar(
              messageCount: dashboard.messages,
              notificationCount: dashboard.notifications,
              onMenuTap: onMenuTap,
              onMessageTap: () {
                // NAVIGATION PLACE:
                // Later create messages page and use:
                // Navigator.pushNamed(context, AppRoutes.messages);
                debugPrint('Messages clicked');
              },
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: ProfileHeader(
              name: w.fullName.trim().split(RegExp(r'\s+')).first,
              rating: stats.rating,
              yearsOfExperience: w.yearsOfExperience,
              isVerified: w.verified,
              avatarImage: avatarImage,
              avatarBytes: profile.localProfileImageBytes,
              isOnline: isOnline,
              onStatusChanged: onStatusChanged,
              isTogglingStatus: isTogglingStatus,
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(12, 5, 12, 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xffEEEEEE)),
            ),
            child: Row(
              children: [
                StatCard(
                  number: stats.jobsDone.toString(),
                  title: 'Jobs Done',
                  subtitle: 'This Month',
                  icon: Icons.work_outline,
                  iconColor: const Color(0xff6A35FF),
                  bgColor: const Color(0xffF4EEFF),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.skills.toString(),
                  title: 'Skills',
                  subtitle: 'Registered',
                  icon: Icons.sync,
                  iconColor: const Color(0xff246BFD),
                  bgColor: const Color(0xffEDF4FF),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.reviews.toString(),
                  title: 'Reviews',
                  subtitle: 'This Week',
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xffFF8C1A),
                  bgColor: const Color(0xffFFF1E6),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.rating.toStringAsFixed(1),
                  title: 'Avg Rating',
                  subtitle: 'Out of 5',
                  icon: Icons.star_border,
                  iconColor: const Color(0xff246BFD),
                  bgColor: const Color(0xffEDF4FF),
                ),
              ],
            ),
          ),

          _IncomingRequestsSection(
            requests: requests,
            onRequestTap: onRequestTap,
            // The real count of currently-loaded requests, not the
            // dashboard's separate incoming_request_count field — that value
            // comes from a different endpoint and can drift out of sync with
            // what this section actually has to show.
            incomingCount: requests.length,
          ),

          ProTipCard(
            onTap: () {
              // NAVIGATION PLACE:
              // Later create profile tips page and use:
              // Navigator.pushNamed(context, AppRoutes.profileTips);
              debugPrint('Pro Tip clicked');
            },
          ),

          // TEMPORARY — REMOVE ONCE PUSH/REALTIME EXISTS:
          // There's currently no push notification, WebSocket, or polling
          // mechanism to tell the app when a new offer has come in, so the
          // worker has no way to know without manually asking. This button
          // is that manual ask. Delete it once the app can learn about new
          // incoming requests on its own.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckIncomingRequests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Check for any incoming request'),
              ),
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incoming requests section
// ---------------------------------------------------------------------------

class _IncomingRequestsSection extends StatelessWidget {
  const _IncomingRequestsSection({
    required this.requests,
    required this.onRequestTap,
    required this.incomingCount,
  });

  final List<IncomingRequest> requests;
  final ValueChanged<IncomingRequest> onRequestTap;
  final int incomingCount;

  /// The newest [_maxPreviewRequests] requests, regardless of the order the
  /// backend returned them in. IncomingRequestsScreen ("View All") shows
  /// every request; this preview only ever shows the latest couple.
  List<IncomingRequest> get _previewRequests {
    final sorted = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(_maxPreviewRequests).toList();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewRequests;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xffEFE6FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xffFCFAFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Incoming Requests',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 7),

                          // Badge driven by API incoming_request_count.
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                incomingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'New requests near you',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xff5F6A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IncomingRequestsScreen(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (requests.isEmpty)
            const _IncomingRequestsEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Preview shows only the latest two requests; the full set
              // (however many the backend returned) is available from
              // "View All" on IncomingRequestsScreen.
              itemCount: preview.length,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = preview[index];
                return IncomingRequestCard(
                  request: request,
                  style: IncomingRequestCardStyle.compact,
                  onTap: () => onRequestTap(request),
                );
              },
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const int _maxPreviewRequests = 2;
}

/// Shown in place of the request list when there are no pending offers.
///
/// Sized to occupy roughly the same vertical space as the two-card preview so
/// the section doesn't visually collapse when empty.
class _IncomingRequestsEmptyState extends StatelessWidget {
  const _IncomingRequestsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 28, 12, 32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 46, color: Color(0xffBFC4D2)),
          SizedBox(height: 10),
          Text(
            'No incoming requests right now.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff6E7191),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPermissionDialog extends StatelessWidget {
  const _LocationPermissionDialog({
    required this.onAllowWhileUsing,
    required this.onAllowThisTime,
    required this.onDeny,
  });

  final VoidCallback onAllowWhileUsing;
  final VoidCallback onAllowThisTime;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header location icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              "Allow 'Rojgari' to access this device's location?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            const Text(
              "This app requires location services to match you with job requests near you, display distances, and navigate to client sites.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),
            // Button 1: Allow while using the app
            ElevatedButton(
              onPressed: onAllowWhileUsing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Allow while using the app",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            // Button 2: Allow this time
            OutlinedButton(
              onPressed: onAllowThisTime,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Allow this time",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            // Button 3: Deny
            TextButton(
              onPressed: onDeny,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.grey,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                "Deny",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
