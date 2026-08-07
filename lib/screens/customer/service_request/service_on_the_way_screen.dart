import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:latlong2/latlong.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_request/accepted_worker_ui_model.dart';
import '../../../models/service_request/request_search_status.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/service_booking_demo_config.dart';
import '../../../models/service_request/service_category.dart';
import '../../../models/service_request/service_category_presentation.dart';
import '../../../models/service_request/worker_tracking_ui_state.dart';
import '../../../core/constants/api_urls.dart';
import '../../../services/api_service.dart';
import '../../../services/app_web_socket.dart';
import '../../../services/booking_history_store.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/customer/service_request/horizontal_service_status_tracker.dart';
import '../../../widgets/customer/service_request/service_search_map.dart';
import '../../chat/booking_chat_screen.dart';
import 'rate_your_experience_screen.dart';

typedef TrackingCancelCallback = Future<bool> Function();

class ServiceOnTheWayScreen extends StatefulWidget {
  const ServiceOnTheWayScreen({
    required this.requestId,
    required this.category,
    required this.serviceLocation,
    required this.requestDescription,
    required this.requestedAt,
    required this.worker,
    this.visitCharge,
    this.initialStatus = RequestSearchStatus.workerOnTheWay,
    this.statusListenable,
    this.trackingListenable,
    this.enableDemoFlow = ServiceBookingDemoConfig.enableDemoBookingFlow,
    this.demoArrivalDuration = ServiceBookingDemoConfig.workerArrivalDuration,
    this.demoTrackingInterval = ServiceBookingDemoConfig.trackingUpdateInterval,
    this.trackingSnapshotInterpolationDuration =
        ServiceBookingDemoConfig.trackingSnapshotInterpolationDuration,
    this.arrivedAcknowledgementDuration =
        ServiceBookingDemoConfig.arrivedAcknowledgementDuration,
    this.workingPreviewDuration =
        ServiceBookingDemoConfig.workingPreviewDuration,
    this.completedDisplayDuration =
        ServiceBookingDemoConfig.completedDisplayDuration,
    this.enableLocationPolling = true,
    this.onCancelRequested,
    this.onChat,
    this.onCall,
    this.onSubmitReview,
    this.onBackToHome,
    this.onRatingNavigation,
    super.key,
  });

  final String requestId;
  final ServiceCategory category;
  final SelectedServiceLocation serviceLocation;
  final String requestDescription;
  final DateTime requestedAt;
  final AcceptedWorkerUiModel worker;

  // What the worker will charge just for this visit — null until the
  // backend has an accepted offer to compute it from (BookingDetailSerializer
  // .get_visit_charge). Hidden on screen when absent rather than showing 0.
  final double? visitCharge;
  final RequestSearchStatus initialStatus;
  final ValueListenable<RequestSearchStatus>? statusListenable;
  final ValueListenable<WorkerTrackingUiState>? trackingListenable;
  final bool enableDemoFlow;
  final Duration demoArrivalDuration;
  final Duration demoTrackingInterval;
  final Duration trackingSnapshotInterpolationDuration;
  final Duration arrivedAcknowledgementDuration;
  final Duration workingPreviewDuration;
  final Duration completedDisplayDuration;

  /// Whether to connect to `ws/bookings/<id>/` for the worker's live
  /// location and job-progress updates while en route. Defaults to true for
  /// production use. Ignored when [trackingListenable] or [statusListenable]
  /// is supplied (an external source already drives tracking — tests and
  /// preview routes use this).
  final bool enableLocationPolling;

  final TrackingCancelCallback? onCancelRequested;
  final VoidCallback? onChat;
  final VoidCallback? onCall;
  final SubmitServiceReviewCallback? onSubmitReview;
  final VoidCallback? onBackToHome;
  final VoidCallback? onRatingNavigation;

  @override
  State<ServiceOnTheWayScreen> createState() => _ServiceOnTheWayScreenState();
}

class _ServiceOnTheWayScreenState extends State<ServiceOnTheWayScreen>
    with TickerProviderStateMixin {
  late RequestSearchStatus _status;
  late WorkerTrackingUiState _trackingState;
  late final ValueNotifier<WorkerTrackingUiState> _trackingNotifier;
  late final AnimationController _arrivalAnimationController;

  /// Drives the one-shot "pop" entrance of the arrived status tracker —
  /// separate from [_arrivalAnimationController], which only pulses the
  /// pre-arrival card and reverses back down afterward.
  late final AnimationController _arrivedPopController;
  Timer? _trackingDemoTimer;
  Timer? _snapshotInterpolationTimer;
  Timer? _workingTransitionTimer;
  Timer? _completionDemoTimer;
  Timer? _ratingNavigationTimer;
  AppWebSocket? _socket;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  int _trackingDemoStep = 0;
  bool _cancellationInFlight = false;
  bool _dialogOpen = false;
  bool _allowRoutePop = false;
  bool _ratingNavigationTriggered = false;
  DateTime? _arrivedAt;

  /// True once arrival has been detected, so a worker who lingers at ~0 km
  /// doesn't re-trigger the transition on every subsequent poll.
  bool _arrivalReported = false;

  bool get _hasReachedService => _status.hasReachedService;
  bool get _canCancel =>
      !_hasReachedService && _status == RequestSearchStatus.workerOnTheWay;
  bool get _usesExternalStatusSource =>
      widget.statusListenable != null || widget.trackingListenable != null;

  @override
  void initState() {
    super.initState();
    _status =
        widget.trackingListenable?.value.status ??
        widget.statusListenable?.value ??
        widget.initialStatus;
    _trackingState =
        widget.trackingListenable?.value ?? _initialTrackingState(_status);
    _trackingNotifier = ValueNotifier(_trackingState);
    _arrivalAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _arrivedPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      // Starting already arrived (e.g. a rebuild, or a preview route) should
      // show the tracker at rest, not replay the pop-in every time.
      value: _status.hasReachedService ? 1 : 0,
    );
    widget.statusListenable?.addListener(_handleExternalStatusChanged);
    widget.trackingListenable?.addListener(_handleExternalTrackingChanged);
    if (_status.hasReachedService) {
      _arrivedAt = widget.worker.arrivedAt ?? DateTime.now();
      _arrivalReported = true;
    }
    _startArrivalDemoIfNeeded();
    unawaited(_startTrackingSocket());
    _handleLifecycleStatus(_status);
  }

  @override
  void didUpdateWidget(covariant ServiceOnTheWayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackingListenable != widget.trackingListenable) {
      oldWidget.trackingListenable?.removeListener(
        _handleExternalTrackingChanged,
      );
      widget.trackingListenable?.addListener(_handleExternalTrackingChanged);
      final next = widget.trackingListenable?.value;
      if (next != null) _applyTrackingState(next);
    }
    if (oldWidget.statusListenable != widget.statusListenable) {
      oldWidget.statusListenable?.removeListener(_handleExternalStatusChanged);
      widget.statusListenable?.addListener(_handleExternalStatusChanged);
      final next = widget.statusListenable?.value ?? widget.initialStatus;
      _setTrackingStatus(next);
    } else if (widget.statusListenable == null &&
        oldWidget.initialStatus != widget.initialStatus) {
      _setTrackingStatus(widget.initialStatus);
    }
  }

  @override
  void dispose() {
    _trackingDemoTimer?.cancel();
    _snapshotInterpolationTimer?.cancel();
    _workingTransitionTimer?.cancel();
    _completionDemoTimer?.cancel();
    _ratingNavigationTimer?.cancel();
    _disconnectSocket();
    widget.statusListenable?.removeListener(_handleExternalStatusChanged);
    widget.trackingListenable?.removeListener(_handleExternalTrackingChanged);
    _trackingNotifier.dispose();
    _arrivalAnimationController.dispose();
    _arrivedPopController.dispose();
    super.dispose();
  }

  void _handleExternalStatusChanged() {
    final next = widget.statusListenable?.value;
    if (next != null) _setTrackingStatus(next);
  }

  void _handleExternalTrackingChanged() {
    final next = widget.trackingListenable?.value;
    if (next != null) _interpolateToTrackingSnapshot(next);
  }

  void _interpolateToTrackingSnapshot(WorkerTrackingUiState snapshot) {
    _snapshotInterpolationTimer?.cancel();
    final duration = widget.trackingSnapshotInterpolationDuration;
    if (duration <= Duration.zero) {
      _applyTrackingState(snapshot);
      return;
    }

    final customer = LatLng(
      widget.serviceLocation.latitude,
      widget.serviceLocation.longitude,
    );
    final route = buildDemoServiceTrackingRoute(
      widget.worker.coordinate,
      customer,
    );
    final projectedProgress = serviceTrackingProgressForCoordinate(
      route,
      snapshot.coordinate,
    );
    final targetProgress = snapshot.status.hasReachedService
        ? 1.0
        : math.max(snapshot.routeProgress, projectedProgress);
    final start = _trackingState;
    final intervalMicros = math.max(
      1,
      ServiceBookingDemoConfig.trackingUpdateInterval.inMicroseconds,
    );
    final interval = Duration(microseconds: intervalMicros);
    final totalSteps = math.max(
      1,
      (duration.inMicroseconds / intervalMicros).ceil(),
    );
    var step = 0;

    // BACKEND INTEGRATION:
    // The backend only needs to provide periodic location snapshots at the
    // final approved cadence; it does not need to send a coordinate every UI
    // frame or every second. This frontend interpolation estimates the points
    // between snapshots. Each new server snapshot corrects the estimate and
    // remains the source of truth.
    _snapshotInterpolationTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      final progress = math.min(1.0, step / totalSteps);
      final routeProgress =
          start.routeProgress +
          (targetProgress - start.routeProgress) * progress;
      final reachedSnapshot = progress >= 1;
      // Nothing sensible to interpolate from an unknown starting value —
      // jump straight to the snapshot's value (itself possibly still
      // unknown/null) instead of crashing or fabricating a number.
      final startDistance = start.distanceKm;
      final snapshotDistance = snapshot.distanceKm;
      final startEta = start.estimatedArrivalMinutes;
      final snapshotEta = snapshot.estimatedArrivalMinutes;
      _applyTrackingState(
        WorkerTrackingUiState(
          coordinate: serviceTrackingCoordinateAt(route, routeProgress),
          distanceKm: (startDistance == null || snapshotDistance == null)
              ? snapshotDistance
              : startDistance + (snapshotDistance - startDistance) * progress,
          estimatedArrivalMinutes: (startEta == null || snapshotEta == null)
              ? snapshotEta
              : (startEta + (snapshotEta - startEta) * progress).round(),
          status: reachedSnapshot ? snapshot.status : start.status,
          updatedAt: reachedSnapshot ? snapshot.updatedAt : DateTime.now(),
          routeProgress: routeProgress,
        ),
      );
      if (reachedSnapshot) timer.cancel();
    });
  }

  WorkerTrackingUiState _initialTrackingState(RequestSearchStatus status) {
    final customer = LatLng(
      widget.serviceLocation.latitude,
      widget.serviceLocation.longitude,
    );
    return WorkerTrackingUiState(
      coordinate: status.hasReachedService
          ? customer
          : widget.worker.coordinate,
      distanceKm: status.hasReachedService ? 0 : widget.worker.distanceKm,
      estimatedArrivalMinutes: status.hasReachedService
          ? 0
          : widget.worker.estimatedArrivalMinutes,
      status: status,
      updatedAt: DateTime.now(),
      routeProgress: status.hasReachedService ? 1 : 0,
    );
  }

  void _startArrivalDemoIfNeeded() {
    if (!widget.enableDemoFlow ||
        widget.statusListenable != null ||
        widget.trackingListenable != null ||
        _status != RequestSearchStatus.workerOnTheWay) {
      return;
    }

    // FRONTEND DEMO ONLY:
    // These periodic positions simulate a worker travelling toward the
    // customer so the tracking UI can be reviewed without a worker app.
    // Remove this timer when real live-location updates are connected.
    final intervalMicros = math.max(
      1,
      widget.demoTrackingInterval.inMicroseconds,
    );
    final effectiveInterval = Duration(microseconds: intervalMicros);
    final totalSteps = math.max(
      1,
      (widget.demoArrivalDuration.inMicroseconds / intervalMicros).ceil(),
    );
    final start = widget.worker.coordinate;
    final customer = LatLng(
      widget.serviceLocation.latitude,
      widget.serviceLocation.longitude,
    );
    final initialDistance = widget.worker.distanceKm ?? 1.2;
    final initialEta = widget.worker.estimatedArrivalMinutes ?? 2;
    final route = buildDemoServiceTrackingRoute(start, customer);

    _trackingDemoTimer = Timer.periodic(effectiveInterval, (timer) {
      if (!mounted || _hasReachedService) {
        timer.cancel();
        return;
      }
      _trackingDemoStep++;
      final progress = math.min(1.0, _trackingDemoStep / totalSteps);
      final coordinate = serviceTrackingCoordinateAt(route, progress);
      final arrived = progress >= 1;
      _applyTrackingState(
        WorkerTrackingUiState(
          coordinate: coordinate,
          distanceKm: arrived ? 0 : initialDistance * (1 - progress),
          estimatedArrivalMinutes: arrived
              ? 0
              : math.max(1, (initialEta * (1 - progress)).ceil()),
          status: arrived
              ? RequestSearchStatus.arrived
              : RequestSearchStatus.workerOnTheWay,
          updatedAt: DateTime.now(),
          routeProgress: progress,
        ),
      );
    });
  }

  /// Connects to `ws/bookings/<id>/` for the worker's live location and
  /// job-progress updates. One socket replaces what used to be two separate
  /// timers polling the same REST endpoint for different fields —
  /// [_handleSocketMessage] dispatches on whichever keys each message
  /// carries. Skipped when [ServiceOnTheWayScreen.enableLocationPolling] is
  /// false or once already completed.
  ///
  /// Deliberately NOT skipped when an external tracking source is supplied
  /// (e.g. FindingServicePersonScreen's TEMP TEST-ONLY fake-walk stub) —
  /// [_handleSocketMessage] itself ignores location-only messages in that
  /// case, but status messages still need to get through, since
  /// this socket is the only way this screen learns the worker tapped Start
  /// or Complete on their own screen. The old polling implementation ran
  /// job-progress checks on a separate timer specifically so a fake/external
  /// location source couldn't block real status updates too — collapsing
  /// both into one socket connection must not lose that distinction.
  Future<void> _startTrackingSocket() async {
    if (!widget.enableLocationPolling || _status.isCompleted) {
      return;
    }

    final token = await StorageService.getAccessToken();
    if (token == null || !mounted || _status.isCompleted) return;

    final socket = AppWebSocket(ApiUrls.bookingSocket(widget.requestId, token));
    _socket = socket;
    _socketSubscription = socket.connect().listen(
      _handleSocketMessage,
      onDone: () => _handleSocketClosed(socket),
    );
  }

  /// Reconnects after the socket closes, mirroring IncomingRequestsStore's
  /// pattern: refresh the session first on an expired token (4001) before
  /// retrying, give up entirely on "not authorized" (4003), otherwise just
  /// reconnect.
  ///
  /// Unlike FindingServicePersonScreen, this doesn't also re-fetch status
  /// over REST on reconnect — there's no catch-up read wired in here yet, so
  /// a job-progress/location change that happened entirely during the
  /// disconnected gap won't be seen until the next push after reconnecting.
  Future<void> _handleSocketClosed(AppWebSocket closedSocket) async {
    if (_socket != closedSocket) return; // already superseded — ignore
    _socket = null;
    _socketSubscription = null;
    if (!mounted || _status.isCompleted) return;

    if (closedSocket.closeCode == 4003) return;

    if (closedSocket.closeCode == 4001) {
      final refreshed = await ApiService().checkAndRefreshSession();
      if (!refreshed || !mounted || _status.isCompleted) return;
    }

    await _startTrackingSocket();
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    if (!mounted || _status.isCompleted) return;

    if (message['status'] == 'completed') {
      if (!_status.isCompleted) {
        _setTrackingStatus(RequestSearchStatus.completed);
      }
      _disconnectSocket();
      return;
    }

    if (message['status'] == 'working') {
      if (!_status.isWorking) _setTrackingStatus(RequestSearchStatus.working);
      return; // Keep listening — still want the eventual "completed".
    }

    // Otherwise, a location update: {latitude, longitude}, both strings.
    // Skip it when an external source (fake-walk stub, tests) is already
    // driving location instead — only the status check above should
    // still get through in that case.
    if (_usesExternalStatusSource) return;
    if (_hasReachedService) return; // Nothing left to track once arrived.
    final latitude = double.tryParse('${message['latitude']}');
    final longitude = double.tryParse('${message['longitude']}');
    if (latitude == null || longitude == null) return;
    _handleWorkerLocation(LatLng(latitude, longitude));
  }

  void _handleWorkerLocation(LatLng coordinate) {
    final customer = LatLng(
      widget.serviceLocation.latitude,
      widget.serviceLocation.longitude,
    );
    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      coordinate,
      customer,
    );

    if (distanceKm <= _arrivalDistanceThresholdKm) {
      unawaited(_reportArrivalIfNeeded(coordinate));
      return;
    }

    _interpolateToTrackingSnapshot(
      WorkerTrackingUiState(
        coordinate: coordinate,
        distanceKm: distanceKm,
        estimatedArrivalMinutes: _trackingState.estimatedArrivalMinutes,
        status: _status,
        updatedAt: DateTime.now(),
        routeProgress: _trackingState.routeProgress,
      ),
    );
  }

  void _disconnectSocket() {
    _socketSubscription?.cancel();
    _socket?.disconnect();
    _socket = null;
    _socketSubscription = null;
  }

  /// Distance at which the worker is considered to have physically reached
  /// the customer. Matches the ~50 m precision the UI already rounds
  /// distance display to (`toStringAsFixed(1)` on km), rather than requiring
  /// an exact 0.0 that GPS coordinates will rarely produce.
  static const double _arrivalDistanceThresholdKm = 0.05;

  /// Flips the UI to "Arrived" — with its pop + haptic effect — once the
  /// worker has physically reached the customer (~0 km away). This is a
  /// client-side transition detected purely from the tracked distance.
  Future<void> _reportArrivalIfNeeded(LatLng coordinate) async {
    if (_arrivalReported) return;
    _arrivalReported = true;
    _applyTrackingState(
      _trackingState.copyWith(
        coordinate: coordinate,
        distanceKm: 0,
        estimatedArrivalMinutes: 0,
        status: RequestSearchStatus.arrived,
        updatedAt: DateTime.now(),
        routeProgress: 1,
      ),
    );
  }

  void _setTrackingStatus(RequestSearchStatus next) {
    final customer = LatLng(
      widget.serviceLocation.latitude,
      widget.serviceLocation.longitude,
    );
    _applyTrackingState(
      _trackingState.copyWith(
        coordinate: next.hasReachedService ? customer : null,
        distanceKm: next.hasReachedService ? 0 : null,
        estimatedArrivalMinutes: next.hasReachedService ? 0 : null,
        status: next,
        updatedAt: DateTime.now(),
        routeProgress: next.hasReachedService ? 1 : null,
      ),
    );
  }

  void _applyTrackingState(WorkerTrackingUiState next) {
    if (!mounted) return;
    final newlyArrived =
        next.status.hasReachedService && !_status.hasReachedService;
    if (next == _trackingState) return;
    setState(() {
      _trackingState = next;
      _status = next.status;
      if (newlyArrived ||
          (_arrivedAt == null && next.status.hasReachedService)) {
        _arrivedAt = widget.worker.arrivedAt ?? DateTime.now();
      }
    });
    _trackingNotifier.value = next;
    if (newlyArrived) {
      _trackingDemoTimer?.cancel();
      _snapshotInterpolationTimer?.cancel();
      unawaited(_playArrivalAnimation());
      HapticFeedback.mediumImpact();
      _arrivedPopController.forward(from: 0);
    }
    _handleLifecycleStatus(next.status);

    // BACKEND INTEGRATION:
    // Replace frontend demo transitions with the real service-request status.
    // Map backend accepted, on_the_way, arrived, working, and completed values
    // to RequestSearchStatus through polling, WebSocket, SSE, or the project's
    // final realtime approach. Do not run demo timers after real integration.
    // This single point drives badge, map, tracker, cancellation, and rating.
  }

  void _handleLifecycleStatus(RequestSearchStatus status) {
    if (status.isArrived) {
      _startWorkingTransitionIfNeeded();
    } else if (status.isWorking) {
      _workingTransitionTimer?.cancel();
      _startCompletionDemoIfNeeded();
    } else if (status.isCompleted) {
      _workingTransitionTimer?.cancel();
      _completionDemoTimer?.cancel();
      _scheduleRatingNavigation();
      // Single funnel point for "this booking just turned out to be
      // completed" — reached both by a live ws/bookings/<id>/ "completed"
      // message (via _setTrackingStatus/_applyTrackingState above) and by
      // CustomerBookingTrackingLoader constructing this screen with
      // initialStatus already completed (a customer re-opening an "In
      // Progress" history card for a job that finished while they were
      // away from this screen — nothing else would have refreshed the
      // list for that case). Covering both here means the WS handler
      // doesn't need its own separate call.
      BookingHistoryStore.instance.refreshNow();
    }
  }

  void _startWorkingTransitionIfNeeded() {
    if (!widget.enableDemoFlow ||
        _usesExternalStatusSource ||
        _workingTransitionTimer != null) {
      return;
    }
    _workingTransitionTimer = Timer(widget.arrivedAcknowledgementDuration, () {
      if (!mounted || !_status.isArrived) return;
      _setTrackingStatus(RequestSearchStatus.working);
    });
  }

  void _startCompletionDemoIfNeeded() {
    if (!widget.enableDemoFlow ||
        _usesExternalStatusSource ||
        _completionDemoTimer != null) {
      return;
    }

    // FRONTEND DEMO ONLY:
    // This delay simulates the technician pressing Complete on the worker
    // side. Remove it when backend status updates are connected. Production
    // must navigate to rating only after the backend reports completed.
    _completionDemoTimer = Timer(widget.workingPreviewDuration, () {
      if (!mounted || !_status.isWorking) return;
      _setTrackingStatus(RequestSearchStatus.completed);
    });

    // BACKEND INTEGRATION:
    // Keep the customer UI in Working until the worker-side app marks this
    // request completed. After the worker presses Complete, the backend should
    // publish completed status; then update the tracker and open rating once.
  }

  void _scheduleRatingNavigation() {
    if (_ratingNavigationTriggered || _ratingNavigationTimer != null) return;
    _ratingNavigationTimer = Timer(
      widget.completedDisplayDuration,
      _openRatingOnce,
    );
  }

  void _openRatingOnce() {
    if (!mounted || _ratingNavigationTriggered || !_status.isCompleted) return;
    _ratingNavigationTriggered = true;
    final callback = widget.onRatingNavigation;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RateYourExperienceScreen(
          requestId: widget.requestId,
          category: widget.category,
          worker: widget.worker,
          onSubmitReview: widget.onSubmitReview,
          onBackToHome: widget.onBackToHome,
        ),
      ),
    );
  }

  Future<void> _playArrivalAnimation() async {
    await _arrivalAnimationController.forward(from: 0);
    if (!mounted) return;
    await _arrivalAnimationController.reverse();
  }

  Future<void> _handleBack() async {
    if (_cancellationInFlight) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave tracking screen?'),
        content: const Text(
          'Your service request will remain active. You can return to tracking '
          'from the active booking area when it is connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave Screen'),
          ),
        ],
      ),
    );
    if (!mounted || leave != true) return;
    // TODO(PRODUCT NAVIGATION): Confirm the final active-booking back behavior.
    _popTrackingRoute();
  }

  void _handleChat() {
    if (widget.onChat != null) {
      widget.onChat!.call();
      return;
    }
    // Chat rides the same ws/bookings/<id>/ socket as tracking; requestId is
    // the booking id here (it's what _startTrackingSocket connects with).
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingChatScreen(
          bookingId: widget.requestId,
          title: widget.worker.name.trim().isEmpty
              ? 'Service professional'
              : widget.worker.name,
          subtitle: ServiceCategoryPresentation.serviceTitleFor(
            widget.category,
          ),
          avatarUrl: widget.worker.profileImageUrl,
          avatarAsset: widget.worker.profileImageAsset,
        ),
      ),
    );
  }

  void _handleCall() {
    if (widget.onCall != null) {
      widget.onCall!.call();
      return;
    }
    // NAVIGATION / PLATFORM INTEGRATION:
    // Connect this action to the approved call flow. Use the backend-provided
    // safe/contact number or masked calling method. Do not hardcode a number.
    _showPlaceholder('Call will be connected here.');
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmCancellation() async {
    if (!_canCancel || _dialogOpen || _cancellationInFlight) return;
    final resumeDemoTracking =
        widget.enableDemoFlow && (_trackingDemoTimer?.isActive ?? false);
    if (resumeDemoTracking) _trackingDemoTimer?.cancel();
    _dialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .52),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _TrackingCancelDialog(
          onKeepTracking: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;
    if (confirmed != true) {
      if (resumeDemoTracking) _startArrivalDemoIfNeeded();
      return;
    }
    if (!_canCancel) return;
    await _cancelRequest();
  }

  Future<void> _cancelRequest() async {
    if (!_canCancel || _cancellationInFlight) return;
    setState(() => _cancellationInFlight = true);
    try {
      // Cancellation is allowed only while the backend status permits it
      // (see _canCancel — locked out again once arrived/working/completed).
      // widget.onCancelRequested is wired to the real cancel-booking endpoint
      // by FindingServicePersonScreen when it constructs this screen; the
      // `true` fallback below only matters for tests/preview routes that
      // construct this screen directly without a handler.
      final handler = widget.onCancelRequested;
      final cancelled = handler == null ? true : await handler();
      if (!mounted) return;
      if (!cancelled) {
        setState(() => _cancellationInFlight = false);
        _showPlaceholder('Could not cancel the request. Please try again.');
        return;
      }

      // NAVIGATION INTEGRATION:
      // After the backend confirms cancellation, pop this route to reveal the
      // existing service-request/problem-description screen underneath. Do
      // not push a new form, so the customer's draft remains preserved.
      _popTrackingRoute();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancellationInFlight = false);
      _showPlaceholder('Could not cancel the request. Please try again.');
    }
  }

  void _popTrackingRoute() {
    if (!mounted || _allowRoutePop) return;
    if (!Navigator.canPop(context)) {
      setState(() => _cancellationInFlight = false);

      // TODO(CANCELLED-REQUEST NAVIGATION):
      // The direct frontend preview has no previous route underneath it, so
      // popping would show a blank page. Connect the final cancelled-request
      // destination here when that product route exists, for example:
      // Navigator.pushReplacement(context, cancelledRequestRoute);
      _showPlaceholder(
        'Cancellation confirmed. Return navigation will be connected here.',
      );
      return;
    }
    setState(() => _allowRoutePop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: PopScope<void>(
        canPop: _allowRoutePop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_handleBack());
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFBF9FF),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  sliver: SliverList.list(
                    children: [
                      _TrackingHeader(
                        category: widget.category,
                        onBack: _handleBack,
                      ),
                      const SizedBox(height: 16),
                      _TrackingRequestSummary(
                        requestId: widget.requestId,
                        category: widget.category,
                        status: _status,
                      ),
                      const SizedBox(height: 12),
                      ServiceTrackingMap(
                        location: widget.serviceLocation,
                        worker: widget.worker,
                        trackingListenable: _trackingNotifier,
                      ),
                      const SizedBox(height: 12),
                      WorkerInformationCard(
                        worker: widget.worker,
                        onCall: _handleCall,
                      ),
                      if (widget.visitCharge != null) ...[
                        const SizedBox(height: 12),
                        VisitChargeInfoCard(amount: widget.visitCharge!),
                      ],
                      const SizedBox(height: 12),
                      if (!_hasReachedService)
                        ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.035).animate(
                            CurvedAnimation(
                              parent: _arrivalAnimationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: ArrivalStatusCard(
                            tracking: _trackingState,
                            arrivedAt: _arrivedAt,
                          ),
                        )
                      else
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.82, end: 1).animate(
                            CurvedAnimation(
                              parent: _arrivedPopController,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: HorizontalServiceStatusTracker(
                            status: _status,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ServiceTrackingRequestDetails(
                        location: widget.serviceLocation,
                        requestedAt: widget.requestedAt,
                      ),
                      const SizedBox(height: 12),
                      BookingActionButtons(
                        cancelEnabled: _canCancel && !_cancellationInFlight,
                        onChat: _handleChat,
                        onCall: _handleCall,
                        onCancel: _confirmCancellation,
                      ),
                      const SizedBox(height: 12),
                      const _SafetyBanner(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.category, required this.onBack});

  final ServiceCategory category;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service on the Way',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ServiceCategoryPresentation.serviceTitleFor(category),
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingRequestSummary extends StatelessWidget {
  const _TrackingRequestSummary({
    required this.requestId,
    required this.category,
    required this.status,
  });

  final String requestId;
  final ServiceCategory category;
  final RequestSearchStatus status;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      RequestSearchStatus.arrived => 'Arrived',
      RequestSearchStatus.working => 'Working',
      RequestSearchStatus.completed => 'Completed',
      _ => 'In Progress',
    };
    final isSuccessStatus = status.hasReachedService;
    return _TrackingCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ServiceCategoryPresentation.iconFor(category.slug),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID: #${requestId.trim().isEmpty ? 'Pending' : requestId.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ServiceCategoryPresentation.issueLabelFor(category),
                  style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('tracking-request-status-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSuccessStatus
                  ? AppColors.green.withValues(alpha: .12)
                  : AppColors.lightPurple,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: isSuccessStatus ? AppColors.green : AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerInformationCard extends StatelessWidget {
  const WorkerInformationCard({
    required this.worker,
    required this.onCall,
    super.key,
  });

  final AcceptedWorkerUiModel worker;
  final VoidCallback onCall;

  String? get _workerMeta {
    final parts = <String>[];
    if (worker.rating != null && worker.rating! > 0) {
      parts.add(worker.rating!.toStringAsFixed(1));
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String? get _profileDescription {
    final description = worker.profileDescription?.trim();
    return description == null || description.isEmpty ? null : description;
  }

  @override
  Widget build(BuildContext context) {
    return _TrackingCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _WorkerProfileImage(worker: worker, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name.trim().isEmpty
                      ? 'Assigned professional'
                      : worker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_workerMeta != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    key: const ValueKey('worker-rating'),
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _workerMeta!,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_profileDescription != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _profileDescription!,
                    key: const ValueKey('worker-profile-description'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton.filled(
            key: const ValueKey('worker-call-button'),
            tooltip: 'Call professional',
            onPressed: onCall,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.call_rounded),
          ),
        ],
      ),
    );
  }
}

/// Tells the customer what this visit will cost before the worker arrives,
/// so it's never a surprise. Deliberately worded as a fixed visit-only
/// charge — any extra material/service cost is a separate, later
/// conversation with the worker, not something this screen quotes.
class VisitChargeInfoCard extends StatelessWidget {
  const VisitChargeInfoCard({required this.amount, super.key});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return _TrackingCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.red,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visit Charge: Rs. ${amount.toStringAsFixed(0)}',
                  key: const ValueKey('visit-charge-amount'),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Fixed charge for the visit. Any material or extra service '
                  'costs will be discussed with the professional separately.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArrivalStatusCard extends StatelessWidget {
  const ArrivalStatusCard({
    required this.tracking,
    required this.arrivedAt,
    super.key,
  });

  final WorkerTrackingUiState tracking;
  final DateTime? arrivedAt;

  @override
  Widget build(BuildContext context) {
    final arrived = tracking.hasArrived;
    final time = _formatClock(arrivedAt ?? DateTime.now());
    return Container(
      key: const ValueKey('arrival-status-card'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: arrived
            ? AppColors.green.withValues(alpha: .09)
            : AppColors.lightPurple.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: arrived ? AppColors.green : AppColors.primary,
                width: 2,
              ),
            ),
            child: Icon(
              arrived ? Icons.check_rounded : Icons.timer_outlined,
              color: arrived ? AppColors.green : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arrived ? 'Arrived' : 'Arriving in',
                  style: TextStyle(
                    color: arrived ? AppColors.green : AppColors.grey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  arrived ? '0 km away' : _distanceEtaLabel(tracking),
                  key: const ValueKey('arrival-distance-text'),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (arrived)
                  Text(
                    'Arrived at $time',
                    style: const TextStyle(color: AppColors.grey, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceTrackingRequestDetails extends StatelessWidget {
  const ServiceTrackingRequestDetails({
    required this.location,
    required this.requestedAt,
    super.key,
  });

  final SelectedServiceLocation location;
  final DateTime requestedAt;

  @override
  Widget build(BuildContext context) {
    final address = location.landmark?.trim();
    return _TrackingCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Details',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          _TrackingDetailRow(
            icon: Icons.location_on_outlined,
            title: address == null || address.isEmpty
                ? 'Selected service location'
                : address,
            subtitle:
                '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 12),
          _TrackingDetailRow(
            icon: Icons.calendar_today_outlined,
            title: 'Requested at',
            subtitle: _formatRequestDateTime(requestedAt),
          ),
        ],
      ),
    );
  }
}

class BookingActionButtons extends StatelessWidget {
  const BookingActionButtons({
    required this.cancelEnabled,
    required this.onChat,
    required this.onCall,
    required this.onCancel,
    super.key,
  });

  final bool cancelEnabled;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BookingActionButton(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: onChat,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BookingActionButton(
            label: 'Call',
            icon: Icons.call_outlined,
            onPressed: onCall,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BookingActionButton(
            key: const ValueKey('tracking-cancel-button'),
            label: 'Cancel Request',
            icon: Icons.cancel_outlined,
            destructive: true,
            onPressed: cancelEnabled ? onCancel : null,
          ),
        ),
      ],
    );
  }
}

class _BookingActionButton extends StatelessWidget {
  const _BookingActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = destructive ? AppColors.red : AppColors.primary;
    return SizedBox(
      height: 70,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? color : const Color(0xFFB9B7C2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          side: BorderSide(
            color: enabled ? const Color(0xFFE2DEEB) : const Color(0xFFEAE8EE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingDetailRow extends StatelessWidget {
  const _TrackingDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.grey, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightPurple.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your safety is our priority',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'All professionals are verified and background checked.',
                  style: TextStyle(color: AppColors.grey, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCancelDialog extends StatelessWidget {
  const _TrackingCancelDialog({
    required this.onKeepTracking,
    required this.onConfirm,
  });

  final VoidCallback onKeepTracking;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.red, size: 42),
            const SizedBox(height: 14),
            const Text(
              'Cancel service request?',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your professional is on the way. Are you sure you want to cancel?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onKeepTracking,
                child: const Text('Keep Tracking'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('confirm-tracking-cancellation'),
                onPressed: onConfirm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.red),
                ),
                child: const Text(
                  'Yes, Cancel Request',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerProfileImage extends StatelessWidget {
  const _WorkerProfileImage({required this.worker, required this.size});

  final AcceptedWorkerUiModel worker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = worker.profileImageAsset?.trim();
    final network = worker.profileImageUrl?.trim();
    Widget fallback() =>
        const Icon(Icons.engineering_rounded, color: AppColors.primary);
    Widget child = fallback();
    // BACKEND INTEGRATION:
    // Prefer the accepted-worker profile URL supplied by the backend. The
    // local asset is demo-only; the icon is the safe missing/error fallback.
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
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: child,
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.child,
    required this.padding,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor ?? const Color(0xFFE8E3F0)),
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
}

/// Distance/ETA line for [ArrivalStatusCard] — the real tracking flow may
/// not have either value yet (no GPS update received) or ever (nothing
/// computes a real ETA today), so each half degrades independently instead
/// of falling back to a fabricated number.
String _distanceEtaLabel(WorkerTrackingUiState tracking) {
  final eta = tracking.estimatedArrivalMinutes;
  final distance = tracking.distanceKm;
  if (eta != null && distance != null) {
    return '$eta min (${distance.toStringAsFixed(1)} km away)';
  }
  if (distance != null) return '${distance.toStringAsFixed(1)} km away';
  if (eta != null) return '$eta min away';
  return 'Calculating distance…';
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _formatRequestDateTime(DateTime value) {
  final local = value.toLocal();
  return 'Today, ${_formatClock(local)}';
}
