import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/service_category_icon_resolver.dart';
import '../../dev_testing/fake_worker_movement.dart';
import '../../models/technician/technician_active_job_model.dart';
import '../../models/technician/technician_job_status.dart';
import '../../repositories/technician_job/technician_job_repository.dart';
import '../../repositories/technician_job/technician_job_repository_provider.dart';
import '../../services/app_web_socket.dart';
import '../../services/location/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/technician_job/technician_route_service.dart';
import '../../widgets/technician/technician_route_map.dart';
import 'incoming_requests_screen.dart';
import 'technician_home_screen.dart';
import 'technician_work_completed_screen.dart';

typedef TechnicianCompletionScreenBuilder =
    Widget Function(
      BuildContext context,
      TechnicianActiveJobModel completedJob,
    );

class TechnicianActiveJobScreen extends StatefulWidget {
  const TechnicianActiveJobScreen({
    required this.job,
    this.repository,
    this.routeService,
    this.statusListenable,
    this.locationService = const LocationService(),
    this.enableDemoFlow = true,
    this.enableDeviceLocation = false,
    this.showMapTiles = true,
    this.acceptedDisplayDuration = const Duration(milliseconds: 900),
    this.demoTravelDuration = const Duration(seconds: 45),
    this.demoLocationInterval = const Duration(milliseconds: 250),
    this.arrivedDisplayDuration = const Duration(seconds: 2),
    this.onCallCustomer,
    this.onBackToHome,
    this.completionScreenBuilder,
    super.key,
  });

  static const double arrivalThresholdMeters = 50;
  static const double rerouteDistanceMeters = 30;
  static const Duration rerouteMinimumInterval = Duration(seconds: 10);
  // How often to re-read the device's own position for this screen's own
  // local map. Not sent to the backend from here — TechnicianHomeScreen's
  // own timer already owns publishing the worker's location for the whole
  // time they're online, regardless of which screen is showing.
  static const Duration locationPollInterval = Duration(seconds: 5);

  final TechnicianActiveJobModel job;
  final TechnicianJobRepository? repository;
  final TechnicianRouteService? routeService;
  final ValueListenable<TechnicianJobStatus>? statusListenable;
  final LocationService locationService;
  final bool enableDemoFlow;
  final bool enableDeviceLocation;
  final bool showMapTiles;
  final Duration acceptedDisplayDuration;
  final Duration demoTravelDuration;
  final Duration demoLocationInterval;
  final Duration arrivedDisplayDuration;
  final VoidCallback? onCallCustomer;
  final VoidCallback? onBackToHome;
  final TechnicianCompletionScreenBuilder? completionScreenBuilder;

  @override
  State<TechnicianActiveJobScreen> createState() =>
      _TechnicianActiveJobScreenState();
}

enum _TechnicianLocationViewState {
  idle,
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionBlocked,
  unavailable,
}

class _TechnicianActiveJobScreenState extends State<TechnicianActiveJobScreen> {
  late TechnicianActiveJobModel _job;
  late final TechnicianJobRepository _repository;
  late final TechnicianRouteService _routeService;
  late LatLng _technician;
  late final LatLng _customer;
  TechnicianRouteResult? _route;
  List<LatLng> _visibleRoute = const [];
  bool _routeLoading = true;
  String? _routeError;
  double _distanceMeters = 0;
  double _durationSeconds = 0;
  _TechnicianLocationViewState _locationState =
      _TechnicianLocationViewState.idle;
  Timer? _locationPollTimer;
  Timer? _acceptedTimer;
  Timer? _demoTravelTimer;
  Timer? _workingTimer;
  Timer? _arrivedIntroTimer;
  // Whether the brief plain "Arrived" card has already been shown for
  // arrivedDisplayDuration and the screen can move on to StartWorkIndicator.
  // Defaults to true unless the job is starting out already arrived — see
  // initState — so the intro only plays once, right at the moment arrival
  // is actually detected (_markArrived), not on every rebuild/resume.
  late bool _arrivedIntroComplete;
  int _demoStep = 0;
  bool _completionInFlight = false;
  bool _completionNavigationTriggered = false;
  bool _mapFullScreen = false;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteAt;
  AppWebSocket? _bookingSocket;
  StreamSubscription<Map<String, dynamic>>? _bookingSocketSubscription;
  bool _bookingCancelledDialogShown = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _arrivedIntroComplete = _job.currentStatus != TechnicianJobStatus.arrived;
    _repository = widget.repository ?? technicianJobRepository;
    _routeService = widget.routeService ?? const MockTechnicianRouteService();
    _technician = LatLng(_job.technicianLatitude, _job.technicianLongitude);
    _customer = LatLng(_job.customerLatitude, _job.customerLongitude);
    _distanceMeters = _distanceBetween(_technician, _customer);
    _lastRouteOrigin = _technician;
    _lastRouteAt = DateTime.now();
    widget.statusListenable?.addListener(_handleExternalStatusChanged);
    if (widget.statusListenable != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleExternalStatusChanged();
      });
    }
    unawaited(_loadRoute());
    // TEMP TEST-ONLY: registers this screen's fake coordinate source (if
    // any) so TechnicianHomeScreen's background PATCH timer publishes the
    // same walk instead of real GPS — see ActiveFakeWorkerSession.
    final locationService = widget.locationService;
    if (locationService is FakeWorkerLocationService) {
      ActiveFakeWorkerSession.current = locationService;
    }
    unawaited(_startBookingStatusSocket());
    if (widget.enableDeviceLocation) {
      unawaited(_initializeDeviceLocation());
    } else {
      _startLifecycleForCurrentStatus();
    }
  }

  @override
  void didUpdateWidget(covariant TechnicianActiveJobScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusListenable != widget.statusListenable) {
      oldWidget.statusListenable?.removeListener(_handleExternalStatusChanged);
      widget.statusListenable?.addListener(_handleExternalStatusChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleExternalStatusChanged();
      });
    }
    if (oldWidget.job == widget.job) return;
    _acceptedTimer?.cancel();
    _demoTravelTimer?.cancel();
    _workingTimer?.cancel();
    _job = widget.job;
    _technician = LatLng(_job.technicianLatitude, _job.technicianLongitude);
    _distanceMeters = _distanceBetween(_technician, _customer);
    _startLifecycleForCurrentStatus();
  }

  @override
  void dispose() {
    _acceptedTimer?.cancel();
    _demoTravelTimer?.cancel();
    _workingTimer?.cancel();
    _locationPollTimer?.cancel();
    _arrivedIntroTimer?.cancel();
    _bookingSocketSubscription?.cancel();
    _bookingSocket?.disconnect();
    widget.statusListenable?.removeListener(_handleExternalStatusChanged);
    _routeService.dispose();
    // Only clear if this screen instance is still the registered one — a
    // newer TechnicianActiveJobScreen instance (didUpdateWidget with a
    // different job, or a fresh push) may have already superseded it.
    if (identical(ActiveFakeWorkerSession.current, widget.locationService)) {
      ActiveFakeWorkerSession.current = null;
    }
    super.dispose();
  }

  /// Connects to `ws/bookings/<id>/` — the same booking-status socket the
  /// customer's screens use — purely to detect a customer-initiated
  /// cancellation (the only backend push this screen currently reacts to).
  /// Skipped when an external statusListenable drives status instead (tests,
  /// mock flows), or when bookingId is unavailable (only the
  /// fromIncomingRequest UI-model path lacks it — see
  /// TechnicianActiveJobModel.bookingId).
  Future<void> _startBookingStatusSocket() async {
    if (widget.statusListenable != null || _job.bookingId.isEmpty) return;

    final token = await StorageService.getAccessToken();
    if (token == null || !mounted) return;

    final socket = AppWebSocket(ApiUrls.bookingSocket(_job.bookingId, token));
    _bookingSocket = socket;
    _bookingSocketSubscription = socket.connect().listen(
      _handleBookingSocketMessage,
    );
  }

  void _handleBookingSocketMessage(Map<String, dynamic> message) {
    if (!mounted || _bookingCancelledDialogShown) return;
    if (message['status'] == 'cancelled') {
      unawaited(_handleBookingCancelled());
    }
  }

  /// Shows a popup the worker must dismiss with "OK", then clears back to
  /// the incoming-requests list — mirrors
  /// IncomingRequestDetailsLoader._showOfferGoneDialogThenGoToList, the same
  /// pattern used when a pending offer goes stale before it's even accepted.
  Future<void> _handleBookingCancelled() async {
    if (!mounted || _bookingCancelledDialogShown) return;
    _bookingCancelledDialogShown = true;
    _bookingSocketSubscription?.cancel();
    _bookingSocket?.disconnect();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Booking cancelled'),
        content: const Text('The customer has cancelled this request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const IncomingRequestsScreen()),
      (route) => route.isFirst,
    );
  }

  void _startLifecycleForCurrentStatus() {
    if (_job.currentStatus == TechnicianJobStatus.accepted) {
      if (!widget.enableDemoFlow ||
          widget.statusListenable != null ||
          _acceptedTimer != null) {
        return;
      }
      _acceptedTimer = Timer(widget.acceptedDisplayDuration, () {
        if (!mounted || _job.currentStatus != TechnicianJobStatus.accepted) {
          return;
        }
        _setStatus(TechnicianJobStatus.enRoute);
        _startDemoTravelIfReady();
      });
    } else if (_job.currentStatus == TechnicianJobStatus.enRoute) {
      _startDemoTravelIfReady();
    } else if (_job.currentStatus == TechnicianJobStatus.arrived) {
      _scheduleWorkingTransition();
    }
  }

  Future<void> _loadRoute({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _routeLoading = true;
        _routeError = null;
      });
    }
    try {
      final result = await _routeService.getRoute(
        technician: _technician,
        customer: _customer,
      );
      if (!mounted) return;
      setState(() {
        _route = result;
        _visibleRoute = result.points;
        _distanceMeters = result.distanceMeters;
        _durationSeconds = result.durationSeconds;
        _routeLoading = false;
        _routeError = null;
        _lastRouteOrigin = _technician;
        _lastRouteAt = DateTime.now();
      });
      _startDemoTravelIfReady();
    } catch (_) {
      if (!mounted) return;
      final fallback = TechnicianRouteResult(
        points: [_technician, _customer],
        distanceMeters: _distanceBetween(_technician, _customer),
        durationSeconds: math.max(
          60,
          _distanceBetween(_technician, _customer) / 6.5,
        ),
        isFallback: true,
      );
      setState(() {
        _route = fallback;
        _visibleRoute = fallback.points;
        _distanceMeters = fallback.distanceMeters;
        _durationSeconds = fallback.durationSeconds;
        _routeLoading = false;
        _routeError =
            'Driving directions are unavailable. Showing a direct preview.';
      });
      _startDemoTravelIfReady();
    }
  }

  void _startDemoTravelIfReady() {
    final route = _route;
    if (!widget.enableDemoFlow ||
        widget.statusListenable != null ||
        widget.enableDeviceLocation ||
        route == null ||
        _job.currentStatus != TechnicianJobStatus.enRoute ||
        _demoTravelTimer != null) {
      return;
    }
    final intervalMicros = math.max(
      1,
      widget.demoLocationInterval.inMicroseconds,
    );
    final totalSteps = math.max(
      1,
      (widget.demoTravelDuration.inMicroseconds / intervalMicros).ceil(),
    );
    final originalPoints = List<LatLng>.of(route.points);
    final originalDistance = route.distanceMeters;
    final originalDuration = route.durationSeconds;

    // FRONTEND DEMO ONLY:
    // This timer simulates GPS travel so the UI works without a technician
    // device or backend. Disable it when live LocationService/backend status
    // updates are connected. Timers are never created from build().
    _demoTravelTimer = Timer.periodic(Duration(microseconds: intervalMicros), (
      timer,
    ) {
      if (!mounted || _job.currentStatus != TechnicianJobStatus.enRoute) {
        timer.cancel();
        return;
      }
      _demoStep++;
      final progress = math.min(1.0, _demoStep / totalSteps);
      final coordinate = technicianRoutePointAt(originalPoints, progress);
      setState(() {
        _technician = coordinate;
        _visibleRoute = remainingTechnicianRoute(originalPoints, progress);
        _distanceMeters = originalDistance * (1 - progress);
        _durationSeconds = originalDuration * (1 - progress);
        _job = _job.copyWith(
          technicianLatitude: coordinate.latitude,
          technicianLongitude: coordinate.longitude,
        );
      });
      if (_distanceMeters <= TechnicianActiveJobScreen.arrivalThresholdMeters ||
          progress >= 1) {
        timer.cancel();
        _markArrived();
      }
    });
  }

  Future<void> _initializeDeviceLocation() async {
    if (!mounted) return;
    setState(() => _locationState = _TechnicianLocationViewState.loading);
    try {
      final enabled = await widget.locationService.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(
            () => _locationState = _TechnicianLocationViewState.serviceDisabled,
          );
        }
        return;
      }
      var permission = await widget.locationService.checkPermission();
      if (permission == AppLocationPermission.notRequested ||
          permission == AppLocationPermission.denied) {
        permission = await widget.locationService.requestPermission();
      }
      if (!mounted) return;
      if (permission == AppLocationPermission.blocked) {
        setState(
          () => _locationState = _TechnicianLocationViewState.permissionBlocked,
        );
        return;
      }
      if (permission != AppLocationPermission.granted) {
        setState(
          () => _locationState = _TechnicianLocationViewState.permissionDenied,
        );
        return;
      }
      final current = await widget.locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _locationState = _TechnicianLocationViewState.ready);
      debugPrint(
        '[ActiveJobLocation] First fix: '
        '(${current.latitude}, ${current.longitude})',
      );
      _handleLiveLocation(LatLng(current.latitude, current.longitude));
      // Re-reads the device's position on a timer rather than subscribing to
      // a continuous position stream. Both read the same real device GPS —
      // this is not a demo/mock substitute — but a fresh read each tick is
      // what's proven to reliably reflect location changes in this project's
      // Chrome-based test setup, where a long-lived stream subscription
      // wasn't being renotified. TechnicianHomeScreen's own location timer
      // uses this same repeated-read approach successfully. Unlike that
      // timer, this one does not publish to the backend — see
      // _handleLiveLocation for why.
      _locationPollTimer?.cancel();
      _locationPollTimer = Timer.periodic(
        TechnicianActiveJobScreen.locationPollInterval,
        (_) async {
          if (!mounted) return;
          try {
            final position = await widget.locationService.getCurrentLocation();
            if (!mounted) return;
            debugPrint(
              '[ActiveJobLocation] Tick: '
              '(${position.latitude}, ${position.longitude})',
            );
            _handleLiveLocation(LatLng(position.latitude, position.longitude));
          } catch (e) {
            debugPrint('[ActiveJobLocation] ✗ Could not get a fix: $e');
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationState = _TechnicianLocationViewState.unavailable,
        );
      }
    }
  }

  void _handleLiveLocation(LatLng coordinate) {
    if (!mounted || _job.currentStatus == TechnicianJobStatus.completed) return;
    final distanceToCustomer = _distanceBetween(coordinate, _customer);
    setState(() {
      _technician = coordinate;
      _distanceMeters = distanceToCustomer;
      if (_visibleRoute.length > 1) {
        _visibleRoute = [coordinate, ..._visibleRoute.skip(1)];
      }
      _job = _job.copyWith(
        technicianLatitude: coordinate.latitude,
        technicianLongitude: coordinate.longitude,
      );
    });
    if (_job.currentStatus == TechnicianJobStatus.accepted) {
      _setStatus(TechnicianJobStatus.enRoute);
    }
    // Not publishing this coordinate to the backend here — TechnicianHomeScreen
    // already runs its own independent location timer for the entire time the
    // worker is online, regardless of which screen is showing. Having this
    // screen also publish created two uncoordinated writers racing to update
    // the same backend value, which could overwrite a fresher reading with a
    // stale one. This screen's own polling only drives its local map now.
    _rerouteIfNeeded(coordinate);
    if (distanceToCustomer <=
        TechnicianActiveJobScreen.arrivalThresholdMeters) {
      _markArrived();
    }
  }

  void _rerouteIfNeeded(LatLng coordinate) {
    final origin = _lastRouteOrigin;
    final at = _lastRouteAt;
    if (origin == null || at == null) return;
    final moved = _distanceBetween(origin, coordinate);
    if (moved < TechnicianActiveJobScreen.rerouteDistanceMeters ||
        DateTime.now().difference(at) <
            TechnicianActiveJobScreen.rerouteMinimumInterval) {
      return;
    }
    unawaited(_loadRoute(showLoading: false));
  }

  void _markArrived() {
    if (_job.currentStatus.index >= TechnicianJobStatus.arrived.index) return;
    _demoTravelTimer?.cancel();
    setState(() {
      _technician = _customer;
      _visibleRoute = [_customer];
      _distanceMeters = 0;
      _durationSeconds = 0;
      _job = _job.copyWith(
        currentStatus: TechnicianJobStatus.arrived,
        arrivedAt: DateTime.now(),
        technicianLatitude: _customer.latitude,
        technicianLongitude: _customer.longitude,
      );
      _arrivedIntroComplete = false;
    });
    unawaited(_persistStatus(TechnicianJobStatus.arrived));
    _arrivedIntroTimer?.cancel();
    _arrivedIntroTimer = Timer(widget.arrivedDisplayDuration, () {
      if (!mounted) return;
      setState(() => _arrivedIntroComplete = true);
    });

    // BACKEND INTEGRATION:
    // Client GPS proximity is useful for preview UX, but production arrival
    // may require server-side verification. Persist "arrived" and notify the
    // customer screen; do not rely only on this 50 m client threshold.
    _scheduleWorkingTransition();
  }

  void _scheduleWorkingTransition() {
    if (!widget.enableDemoFlow ||
        widget.statusListenable != null ||
        _workingTimer != null) {
      return;
    }
    _workingTimer = Timer(widget.arrivedDisplayDuration, () {
      if (!mounted || _job.currentStatus != TechnicianJobStatus.arrived) return;
      _setStatus(TechnicianJobStatus.working, workStartedAt: DateTime.now());
    });

    // BACKEND INTEGRATION:
    // Replace this mock delay with the backend job-status response. The same
    // "working" state must be delivered to the customer-side request screen.
  }

  /// Manually moves the job from "arrived" to "working" — the worker
  /// confirms this in person by tapping Start, since the backend has no
  /// arrival concept of its own to trigger it automatically. Reuses the
  /// same _setStatus -> _persistStatus path the (now-disabled) demo timer
  /// used, which calls the real POST .../start/ endpoint via the
  /// repository.
  void _handleStartWork() {
    if (_job.currentStatus != TechnicianJobStatus.arrived) return;
    _setStatus(TechnicianJobStatus.working, workStartedAt: DateTime.now());
  }

  void _setStatus(TechnicianJobStatus status, {DateTime? workStartedAt}) {
    if (!mounted || _job.currentStatus == status) return;
    setState(() {
      _job = _job.copyWith(currentStatus: status, workStartedAt: workStartedAt);
    });
    unawaited(_persistStatus(status));
  }

  Future<void> _persistStatus(TechnicianJobStatus status) async {
    try {
      await _repository.updateJobStatus(_job.requestId, status);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update the job status. Please retry.'),
        ),
      );
    }
  }

  void _handleExternalStatusChanged() {
    if (!mounted || widget.statusListenable == null) return;
    final status = widget.statusListenable!.value;
    if (_job.currentStatus == status) return;

    // BACKEND INTEGRATION:
    // Connect this listenable to the final realtime job source (WebSocket,
    // SSE, Firebase, push-assisted refresh, or controlled polling). Map the
    // backend values accepted/en_route/arrived/working/completed through
    // TechnicianJobStatus.fromBackendValue before publishing them here. The
    // customer and technician screens must consume the same server-owned job
    // state. Handle disconnection/retry in that repository/controller layer.
    _acceptedTimer?.cancel();
    _workingTimer?.cancel();
    if (status.index >= TechnicianJobStatus.arrived.index) {
      _demoTravelTimer?.cancel();
    }

    final now = DateTime.now();
    setState(() {
      if (status == TechnicianJobStatus.arrived) {
        _technician = _customer;
        _visibleRoute = [_customer];
        _distanceMeters = 0;
        _durationSeconds = 0;
      }
      _job = _job.copyWith(
        currentStatus: status,
        arrivedAt: status == TechnicianJobStatus.arrived ? now : _job.arrivedAt,
        workStartedAt: status == TechnicianJobStatus.working
            ? now
            : _job.workStartedAt,
        completedAt: status == TechnicianJobStatus.completed
            ? now
            : _job.completedAt,
        technicianLatitude: status == TechnicianJobStatus.arrived
            ? _customer.latitude
            : _technician.latitude,
        technicianLongitude: status == TechnicianJobStatus.arrived
            ? _customer.longitude
            : _technician.longitude,
      );
    });

    if (status == TechnicianJobStatus.completed) {
      _stopTracking();
      unawaited(_openCompletionScreen(_job));
    }
  }

  Future<void> _confirmWorkDone() async {
    if (_completionInFlight ||
        _job.currentStatus != TechnicianJobStatus.working) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _WorkCompletionDialog(
        onKeepWorking: () => Navigator.pop(dialogContext, false),
        onComplete: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _completeWork();
  }

  Future<void> _completeWork() async {
    if (_completionInFlight || _completionNavigationTriggered) return;
    setState(() => _completionInFlight = true);
    try {
      // BACKEND INTEGRATION:
      // Replace the mock call with POST /technician/jobs/{requestId}/complete
      // or PATCH status {"status":"completed"}. Navigate only after server
      // success. On failure keep Working active. The backend must persist the
      // completion timestamp and notify the customer so rating can begin.
      await _repository.completeJob(_job.requestId);
      if (!mounted) return;
      _stopTracking();
      final completedJob = _job.copyWith(
        currentStatus: TechnicianJobStatus.completed,
        completedAt: DateTime.now(),
      );
      setState(() => _job = completedJob);
      await _openCompletionScreen(completedJob);
    } catch (_) {
      if (!mounted) return;
      setState(() => _completionInFlight = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to complete the work. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openCompletionScreen(
    TechnicianActiveJobModel completedJob,
  ) async {
    if (!mounted || _completionNavigationTriggered) return;
    _completionNavigationTriggered = true;
    final builder = widget.completionScreenBuilder;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (context) => builder != null
            ? builder(context, completedJob)
            : TechnicianWorkCompletedScreen(
                // widget.onBackToHome was captured way up in the accept/
                // active-job navigation chain, several pushReplacements
                // before this route exists — by the time "Back to Home" is
                // actually tapped here, that captured context would already
                // be deactivated. Falls back to a fresh callback built from
                // *this* builder's own context, which stays valid for as
                // long as this completion route is on screen.
                onBackToHome:
                    widget.onBackToHome ??
                    () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const TechnicianHomeScreen(),
                      ),
                      (route) => false,
                    ),
              ),
      ),
    );
  }

  void _stopTracking() {
    _acceptedTimer?.cancel();
    _demoTravelTimer?.cancel();
    _workingTimer?.cancel();
    _locationPollTimer?.cancel();
    _arrivedIntroTimer?.cancel();
  }

  void _handleCall() {
    final callback = widget.onCallCustomer;
    if (callback != null) {
      callback();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call customer action is ready for integration.'),
      ),
    );

    // PLATFORM / BACKEND INTEGRATION:
    // Use the backend-provided customer contact or approved masked-call flow.
    // Never hard-code or expose a private phone number in this UI.
  }

  void _handleChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer chat is ready for integration.')),
    );

    // NAVIGATION INTEGRATION:
    // Open the established request chat using this job's request/customer ID.
    // Keep this action clickable while the messaging page is connected.
  }

  void _handleMore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('More job actions are ready for integration.'),
      ),
    );

    // NAVIGATION INTEGRATION:
    // Open the final technician job-actions sheet for support/report actions.
    // Do not expose customer-private data in the placeholder menu.
  }

  Future<void> _handleLocationAction() async {
    if (_locationState == _TechnicianLocationViewState.serviceDisabled) {
      await widget.locationService.openLocationSettings();
    } else if (_locationState ==
        _TechnicianLocationViewState.permissionBlocked) {
      await widget.locationService.openAppSettings();
    }
    if (mounted) unawaited(_initializeDeviceLocation());
  }

  @override
  Widget build(BuildContext context) {
    if (_mapFullScreen) {
      return Theme(
        data: AppTheme.lightTheme,
        child: PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && mounted) setState(() => _mapFullScreen = false);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFBF9FF),
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    _buildRouteMap(constraints.maxHeight, fullScreen: true),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: const ValueKey(
                            'close-technician-fullscreen-map',
                          ),
                          tooltip: 'Close full screen map',
                          onPressed: () =>
                              setState(() => _mapFullScreen = false),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9FF),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActiveJobHeader(categoryName: _job.categoryName),
                const SizedBox(height: 16),
                TechnicianJobHeaderCard(job: _job),
                const SizedBox(height: 12),
                if (widget.enableDeviceLocation &&
                    _locationState != _TechnicianLocationViewState.ready)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LocationStateCard(
                      state: _locationState,
                      onAction: _handleLocationAction,
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final height = (constraints.maxWidth * .76)
                        .clamp(260.0, 325.0)
                        .toDouble();
                    return _buildRouteMap(height);
                  },
                ),
                if (_routeError != null) ...[
                  const SizedBox(height: 8),
                  _RouteErrorCard(
                    message: _routeError!,
                    onRetry: () => unawaited(_loadRoute()),
                  ),
                ],
                const SizedBox(height: 12),
                CustomerRequestProfileCard(job: _job, onCall: _handleCall),
                const SizedBox(height: 12),
                _buildStatusCard(),
                const SizedBox(height: 12),
                _TechnicianCustomerActions(
                  onChat: _handleChat,
                  onCall: _handleCall,
                  onMore: _handleMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteMap(double height, {bool fullScreen = false}) {
    return Stack(
      children: [
        TechnicianRouteMap(
          technician: _technician,
          customer: _customer,
          routePoints: _visibleRoute,
          distanceMeters: _distanceMeters,
          durationSeconds: _durationSeconds,
          status: _job.currentStatus,
          height: height,
          showTiles: widget.showMapTiles,
          borderRadius: fullScreen ? BorderRadius.zero : null,
          showFullScreenButton: !fullScreen,
          onFullScreen: () => setState(() => _mapFullScreen = true),
        ),
        if (_routeLoading)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusCard() {
    switch (_job.currentStatus) {
      case TechnicianJobStatus.accepted:
        return const _TravelStatusCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Accepted',
          detail: 'Preparing live travel tracking…',
        );
      case TechnicianJobStatus.enRoute:
        final minutes = (_durationSeconds / 60).ceil().clamp(1, 999);
        final km = (_distanceMeters / 1000).toStringAsFixed(1);
        return _TravelStatusCard(
          icon: Icons.timer_outlined,
          title: 'Arriving in',
          detail: '$minutes min ($km km away)',
        );
      case TechnicianJobStatus.arrived:
        if (!_arrivedIntroComplete) {
          return _ArrivalStatusCard(arrivedAt: _job.arrivedAt ?? DateTime.now());
        }
        return StartWorkIndicator(onStart: _handleStartWork);
      case TechnicianJobStatus.working:
        return WorkingStatusIndicator(
          completing: _completionInFlight,
          onWorkDone: _confirmWorkDone,
        );
      case TechnicianJobStatus.completed:
        return const _TravelStatusCard(
          icon: Icons.check_circle_rounded,
          title: 'Completed',
          detail: 'The work has been completed.',
          success: true,
        );
    }
  }

  double _distanceBetween(LatLng first, LatLng second) =>
      const Distance().as(LengthUnit.Meter, first, second);
}

class _ActiveJobHeader extends StatelessWidget {
  const _ActiveJobHeader({required this.categoryName});
  final String categoryName;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Service Job',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class TechnicianJobHeaderCard extends StatelessWidget {
  const TechnicianJobHeaderCard({required this.job, super.key});
  final TechnicianActiveJobModel job;

  @override
  Widget build(BuildContext context) => _JobCard(
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.lightPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(
            ServiceCategoryIconResolver.resolve(
              slug: job.categorySlug,
              name: job.categoryName,
            ),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request ID: #${job.requestId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                job.issueTitle.trim().isEmpty
                    ? job.categoryName
                    : job.issueTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
              ),
            ],
          ),
        ),
        Container(
          key: const ValueKey('technician-job-status-chip'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: job.currentStatus.index >= TechnicianJobStatus.arrived.index
                ? AppColors.green.withValues(alpha: .12)
                : AppColors.lightPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            job.currentStatus.displayLabel,
            style: TextStyle(
              color:
                  job.currentStatus.index >= TechnicianJobStatus.arrived.index
                  ? AppColors.green
                  : AppColors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class CustomerRequestProfileCard extends StatelessWidget {
  const CustomerRequestProfileCard({
    required this.job,
    required this.onCall,
    super.key,
  });

  final TechnicianActiveJobModel job;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => _JobCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomerAvatar(job: job),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.customerName.trim().isEmpty ? 'Customer' : job.customerName,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              _ProfileDetail(
                icon: Icons.location_on_outlined,
                text: job.customerAddress.trim().isEmpty
                    ? 'Customer service location'
                    : job.customerAddress,
              ),
              const SizedBox(height: 5),
              _ProfileDetail(
                icon: Icons.schedule_rounded,
                text: 'Requested at ${_formatJobTime(job.requestedAt)}',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.lightPurple,
          shape: const CircleBorder(),
          child: IconButton(
            key: const ValueKey('profile-call-customer-button'),
            tooltip: 'Call customer',
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

class _TechnicianCustomerActions extends StatelessWidget {
  const _TechnicianCustomerActions({
    required this.onChat,
    required this.onCall,
    required this.onMore,
  });

  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _CustomerActionButton(
          key: const ValueKey('chat-customer-button'),
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          onPressed: onChat,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _CustomerActionButton(
          key: const ValueKey('call-customer-button'),
          icon: Icons.call_outlined,
          label: 'Call',
          onPressed: onCall,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _CustomerActionButton(
          key: const ValueKey('more-job-actions-button'),
          icon: Icons.more_horiz_rounded,
          label: 'More',
          onPressed: onMore,
        ),
      ),
    ],
  );
}

class _CustomerActionButton extends StatelessWidget {
  const _CustomerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 66,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.job});
  final TechnicianActiveJobModel job;

  @override
  Widget build(BuildContext context) {
    final network = job.customerProfileImageUrl?.trim();
    final asset = job.customerProfileImageAsset?.trim();
    Widget fallback() => Center(
      child: Text(
        job.customerName.trim().isEmpty
            ? 'C'
            : job.customerName.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    Widget child;
    if (network != null && network.isNotEmpty) {
      child = Image.network(
        network,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      child = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      child = fallback();
    }
    return Container(
      key: const ValueKey('customer-profile-avatar'),
      width: 54,
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: child,
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.grey),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

class _TravelStatusCard extends StatelessWidget {
  const _TravelStatusCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.success = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('technician-travel-status-card'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: success
          ? AppColors.green.withValues(alpha: .1)
          : AppColors.lightPurple.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: success ? AppColors.green : AppColors.primary,
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: success ? AppColors.green : AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WorkCompletionDialog extends StatelessWidget {
  const _WorkCompletionDialog({
    required this.onKeepWorking,
    required this.onComplete,
  });

  final VoidCallback onKeepWorking;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Complete this work?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Are you sure the requested job has been completed?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('confirm-work-completed-button'),
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Yes, Work Completed'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              key: const ValueKey('keep-working-button'),
              onPressed: onKeepWorking,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('No, Keep Working'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArrivalStatusCard extends StatelessWidget {
  const _ArrivalStatusCard({required this.arrivedAt});
  final DateTime arrivedAt;

  @override
  Widget build(BuildContext context) => _TravelStatusCard(
    icon: Icons.check_circle_rounded,
    title: 'Arrived',
    detail: '0 km away • ${_formatJobTime(arrivedAt)}',
    success: true,
  );
}

/// Separate, standalone widget for the "arrived" state — deliberately not
/// sharing implementation with [WorkingStatusIndicator] (own animation
/// controller, own timer, own class). Visually identical to it except for
/// the animated message and the button label/action: "Start Work?" / tap
/// [onStart] to persist the real transition to working, instead of
/// "Working..." / [WorkingStatusIndicator]'s "Work Done".
class StartWorkIndicator extends StatefulWidget {
  const StartWorkIndicator({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  State<StartWorkIndicator> createState() => _StartWorkIndicatorState();
}

class _StartWorkIndicatorState extends State<StartWorkIndicator> {
  static const _startWorkMessage = 'Start Work?';

  Timer? _typingTimer;
  int _visibleCharacters = 1;
  int _completedPauseTicks = 0;

  @override
  void initState() {
    super.initState();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      setState(() {
        if (_visibleCharacters < _startWorkMessage.length) {
          _visibleCharacters++;
          return;
        }
        if (_completedPauseTicks < 5) {
          _completedPauseTicks++;
          return;
        }
        _visibleCharacters = 1;
        _completedPauseTicks = 0;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('technician-start-work-status'),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .05),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.lightPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: _startWorkMessage,
                child: SizedBox(
                  height: 22,
                  child: Text(
                    _startWorkMessage.substring(0, _visibleCharacters),
                    key: const ValueKey('start-work-typing-text'),
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Service is currently in progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.grey, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: FilledButton(
            key: const ValueKey('start-work-button'),
            onPressed: widget.onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start'),
          ),
        ),
      ],
    ),
  );
}

class WorkingStatusIndicator extends StatefulWidget {
  const WorkingStatusIndicator({
    required this.completing,
    required this.onWorkDone,
    super.key,
  });

  final bool completing;
  final VoidCallback onWorkDone;

  @override
  State<WorkingStatusIndicator> createState() => _WorkingStatusIndicatorState();
}

class _WorkingStatusIndicatorState extends State<WorkingStatusIndicator>
    with SingleTickerProviderStateMixin {
  static const _workingMessage = 'Working...';

  late final AnimationController _rotationController;
  Timer? _typingTimer;
  int _visibleCharacters = 1;
  int _completedPauseTicks = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      setState(() {
        if (_visibleCharacters < _workingMessage.length) {
          _visibleCharacters++;
          return;
        }
        if (_completedPauseTicks < 5) {
          _completedPauseTicks++;
          return;
        }
        _visibleCharacters = 1;
        _completedPauseTicks = 0;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('technician-working-status'),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .05),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.lightPurple,
            shape: BoxShape.circle,
          ),
          child: RotationTransition(
            turns: _rotationController,
            child: const Icon(
              Icons.settings_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: _workingMessage,
                child: SizedBox(
                  height: 22,
                  child: Text(
                    _workingMessage.substring(0, _visibleCharacters),
                    key: const ValueKey('working-typing-text'),
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Service is currently in progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.grey, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: FilledButton(
            key: const ValueKey('work-done-button'),
            onPressed: widget.completing ? null : widget.onWorkDone,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Work Done'),
          ),
        ),
      ],
    ),
  );
}

class _LocationStateCard extends StatelessWidget {
  const _LocationStateCard({required this.state, required this.onAction});
  final _TechnicianLocationViewState state;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final (message, action) = switch (state) {
      _TechnicianLocationViewState.loading => (
        'Getting your current location…',
        '',
      ),
      _TechnicianLocationViewState.serviceDisabled => (
        'Turn on device location to start live travel tracking.',
        'Open settings',
      ),
      _TechnicianLocationViewState.permissionBlocked => (
        'Location permission is blocked for Rojgari.',
        'App settings',
      ),
      _TechnicianLocationViewState.permissionDenied => (
        'Location permission is needed for travel tracking.',
        'Try again',
      ),
      _TechnicianLocationViewState.unavailable => (
        'Current location is unavailable. Please try again.',
        'Retry',
      ),
      _ => ('', ''),
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (state == _TechnicianLocationViewState.loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.location_off_outlined, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.grey, fontSize: 11),
            ),
          ),
          if (action.isNotEmpty)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _RouteErrorCard extends StatelessWidget {
  const _RouteErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.route_outlined, color: AppColors.orange, size: 18),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
        ),
      ),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8E3F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C1A1233),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

String _formatJobTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final now = DateTime.now();
  final isToday =
      now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;
  return '${isToday ? 'Today' : '${local.day}/${local.month}/${local.year}'}, '
      '$hour:$minute $period';
}
