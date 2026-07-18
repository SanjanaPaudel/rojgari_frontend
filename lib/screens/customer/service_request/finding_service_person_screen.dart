import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_request/accepted_worker_ui_model.dart';
import '../../../models/service_request/booking_status_response.dart';
import '../../../models/service_request/request_search_status.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/service_booking_demo_config.dart';
import '../../../models/service_request/service_category.dart';
import '../../../models/service_request/service_category_presentation.dart';
import '../../../services/service_request/booking_status_service.dart';
import '../../../widgets/customer/service_request/service_search_map.dart';
import 'service_on_the_way_screen.dart';
import 'rate_your_experience_screen.dart';

typedef CancelServiceRequestCallback = Future<bool> Function();

class FindingServicePersonScreen extends StatefulWidget {
  const FindingServicePersonScreen({
    required this.requestId,
    required this.category,
    required this.serviceLocation,
    required this.requestDescription,
    required this.requestedAt,
    this.initialStatus = RequestSearchStatus.searching,
    this.addressText,
    this.offersSent,
    this.statusListenable,
    this.workerCoordinates,
    this.onWorkerFound,
    this.onCancelRequested,
    this.acceptedWorker,
    this.onSubmitReview,
    this.onBackToHome,
    this.enableDemoFlow = ServiceBookingDemoConfig.enableDemoBookingFlow,
    this.demoSearchDuration = ServiceBookingDemoConfig.searchingDuration,
    this.acceptedDisplayDuration =
        ServiceBookingDemoConfig.acceptedDisplayDuration,
    this.enableStatusPolling = true,
    this.statusPollInterval = const Duration(seconds: 5),
    this.debugMockWorkerAssignment = false,
    super.key,
  });

  final String requestId;
  final ServiceCategory category;
  final SelectedServiceLocation serviceLocation;
  final String requestDescription;
  final DateTime requestedAt;
  final RequestSearchStatus initialStatus;

  /// Backend-resolved address from the create-booking response
  /// (`address_text`). Null falls back to the locally-selected landmark.
  final String? addressText;

  /// Number of technicians already notified about this booking
  /// (`offers_sent`). Null/0 hides the "X professionals notified" line.
  final int? offersSent;
  final ValueListenable<RequestSearchStatus>? statusListenable;
  final List<LatLng>? workerCoordinates;
  final VoidCallback? onWorkerFound;
  final CancelServiceRequestCallback? onCancelRequested;
  final AcceptedWorkerUiModel? acceptedWorker;
  final SubmitServiceReviewCallback? onSubmitReview;
  final VoidCallback? onBackToHome;
  final bool enableDemoFlow;
  final Duration demoSearchDuration;
  final Duration acceptedDisplayDuration;

  /// Whether to poll `GET /api/services/bookings/<id>/status/` for real
  /// worker assignment. Defaults to true for production use; the debug-only
  /// [FindingServicePersonPreview] route sets this to false so it never hits
  /// the network with its fake preview request id.
  final bool enableStatusPolling;

  /// How often to poll while [enableStatusPolling] is true and no
  /// [statusListenable] is supplied.
  final Duration statusPollInterval;

  /// TEMP DEBUG ONLY — backend for `GET /api/services/bookings/{id}/status/`
  /// is not deployed yet. While true (and [enableStatusPolling] is true),
  /// every poll skips the real network call and feeds a canned "worker
  /// assigned" response through the exact same parsing + navigation path a
  /// real assignment would use: `BookingStatusResponse.fromJson` ->
  /// `hasAssignedWorker` -> `AcceptedWorkerUiModel.fromAssignedWorker` ->
  /// `pushReplacement` to [ServiceOnTheWayScreen]. Only the HTTP call itself
  /// is skipped, so this is proof the real contract works end to end.
  ///
  /// >>> WHEN THE BACKEND IS READY, set this default to false (or delete
  /// this field and `_buildDebugWorkerAssignedResponse`, and the branch that
  /// uses them inside `_pollBookingStatusOnce`). Nothing else needs to
  /// change — the real call is already wired to the documented contract. <<<
  ///
  /// Callers that need deterministic "still searching" behavior (tests,
  /// the cancellation flow) pass false explicitly, the same way they
  /// already override [enableStatusPolling].
  final bool debugMockWorkerAssignment;

  @override
  State<FindingServicePersonScreen> createState() =>
      _FindingServicePersonScreenState();
}

class _FindingServicePersonScreenState
    extends State<FindingServicePersonScreen> {
  /// Consecutive failed polls (network hiccups, unexpected response shapes)
  /// tolerated before giving up and showing the error state. A 404 (booking
  /// not found / not yours) is terminal immediately and doesn't count here.
  static const int _maxStatusPollFailures = 5;

  late RequestSearchStatus _status;
  bool _workerFoundNavigationTriggered = false;
  bool _cancellationInFlight = false;
  bool _dialogOpen = false;
  Timer? _demoAcceptedTimer;
  Timer? _acceptedNavigationTimer;
  Timer? _statusPollTimer;
  int _statusPollFailureCount = 0;
  AcceptedWorkerUiModel? _polledWorker;
  final BookingStatusService _statusService = BookingStatusService();

  /// TEMP DEBUG ONLY — see [FindingServicePersonScreen.debugMockWorkerAssignment].
  /// Matches the documented "worker assigned" success response exactly,
  /// offset near the real service location so ServiceOnTheWayScreen's map
  /// draws a sensible route instead of a marker on the other side of the
  /// world.
  BookingStatusResponse _buildDebugWorkerAssignedResponse() {
    return BookingStatusResponse.fromJson({
      'id': int.tryParse(widget.requestId) ?? 12,
      'status': 'active',
      'worker': {
        'id': 5,
        'full_name': 'Rajan Sharma',
        'phone_number': '+9779800000010',
        'average_rating': 4.7,
        'completed_jobs': 8,
        'profile_photo': 'http://127.0.0.1:8000/media/technician_avatar.png',
        'current_latitude': widget.serviceLocation.latitude + 0.006,
        'current_longitude': widget.serviceLocation.longitude - 0.004,
      },
    });
  }

  @override
  void initState() {
    super.initState();
    _status = widget.statusListenable?.value ?? widget.initialStatus;
    widget.statusListenable?.addListener(_handleStatusListenableChanged);

    if (_status.isFound) _scheduleAcceptedNavigation();
    _startDemoSearchIfNeeded();
    _startStatusPolling();
  }

  @override
  void didUpdateWidget(covariant FindingServicePersonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusListenable != widget.statusListenable) {
      oldWidget.statusListenable?.removeListener(
        _handleStatusListenableChanged,
      );
      widget.statusListenable?.addListener(_handleStatusListenableChanged);
      _applyStatus(widget.statusListenable?.value ?? widget.initialStatus);
    } else if (oldWidget.initialStatus != widget.initialStatus &&
        widget.statusListenable == null) {
      _applyStatus(widget.initialStatus);
    }
  }

  @override
  void dispose() {
    _demoAcceptedTimer?.cancel();
    _acceptedNavigationTimer?.cancel();
    _statusPollTimer?.cancel();
    widget.statusListenable?.removeListener(_handleStatusListenableChanged);
    super.dispose();
  }

  void _handleStatusListenableChanged() {
    final nextStatus = widget.statusListenable?.value;
    if (nextStatus != null) _applyStatus(nextStatus);
  }

  void _applyStatus(RequestSearchStatus nextStatus) {
    if (!mounted || _status == nextStatus) return;
    setState(() => _status = nextStatus);
    if (nextStatus.isFound) {
      _demoAcceptedTimer?.cancel();
      _statusPollTimer?.cancel();
      _scheduleAcceptedNavigation();
    } else if (!nextStatus.isSearching) {
      // cancelled / error: nothing left to poll for.
      _statusPollTimer?.cancel();
    }
  }

  void _startDemoSearchIfNeeded() {
    if (!widget.enableDemoFlow ||
        widget.statusListenable != null ||
        !_status.isSearching) {
      return;
    }

    // FRONTEND DEMO ONLY:
    // This timer simulates the accepted/matched backend status so the complete
    // booking UI can be reviewed without the worker-side flow. Disable it when
    // real request status updates are connected.
    _demoAcceptedTimer = Timer(widget.demoSearchDuration, () {
      if (!mounted || !_status.isSearching) return;
      _applyStatus(RequestSearchStatus.accepted);
    });
  }

  /// Polls `GET /api/services/bookings/<id>/status/` for real worker
  /// assignment. Skipped when an external [statusListenable] drives status
  /// instead (e.g. tests), when [FindingServicePersonScreen.enableStatusPolling]
  /// is false (the debug preview route), or once no longer searching.
  void _startStatusPolling() {
    if (!widget.enableStatusPolling ||
        widget.statusListenable != null ||
        !_status.isSearching) {
      return;
    }

    unawaited(_pollBookingStatusOnce()); // Immediately calls _poolBookingStatusOnce
    _statusPollTimer = Timer.periodic(
      widget.statusPollInterval,
      (_) => unawaited(_pollBookingStatusOnce()),
    );
  }

  Future<void> _pollBookingStatusOnce() async {
    if (!mounted || !_status.isSearching) return;
    try {
      // TEMP DEBUG ONLY — see FindingServicePersonScreen.debugMockWorkerAssignment.
      // Delete this branch when the backend is ready; the real call in the
      // else branch already matches the documented contract and needs no
      // changes.
      final result = (kDebugMode && widget.debugMockWorkerAssignment)
          ? _buildDebugWorkerAssignedResponse()
          : await _statusService.fetchStatus(widget.requestId);
      if (!mounted) return;
      _statusPollFailureCount = 0;

      if (result.hasAssignedWorker) {
        _statusPollTimer?.cancel();
        _polledWorker = AcceptedWorkerUiModel.fromAssignedWorker(
          result.worker!,
        );
        _applyStatus(RequestSearchStatus.accepted);
      }
      // worker == null: still searching — nothing to change, wait for the
      // next tick.
    } on BookingNotFoundException {
      if (!mounted) return;
      _statusPollTimer?.cancel();
      _applyStatus(RequestSearchStatus.error);
    } catch (_) {
      // Transient failure (network hiccup, unexpected response shape, or a
      // non-2xx/non-404 status). Keep polling; only give up after repeated
      // failures so a single blip doesn't interrupt the search.
      _statusPollFailureCount++;
      if (_statusPollFailureCount >= _maxStatusPollFailures) {
        _statusPollTimer?.cancel();
        if (mounted) _applyStatus(RequestSearchStatus.error);
      }
    }
  }

  void _scheduleAcceptedNavigation() {
    if (_workerFoundNavigationTriggered || _acceptedNavigationTimer != null) {
      return;
    }
    _acceptedNavigationTimer = Timer(
      widget.acceptedDisplayDuration,
      _triggerWorkerFoundNavigationOnce,
    );
  }

  void _triggerWorkerFoundNavigationOnce() {
    if (_workerFoundNavigationTriggered) return;
    _workerFoundNavigationTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.onWorkerFound != null) {
        widget.onWorkerFound!.call();
        return;
      }

      // widget.acceptedWorker lets tests/preview routes inject a fixed
      // worker; _polledWorker is what the real status-polling path above
      // populates. The demo factory is only a last-resort fallback so this
      // never null-crashes — it shouldn't be reachable once a real booking
      // is what triggered `accepted` in the first place.
      final worker =
          widget.acceptedWorker ??
          _polledWorker ??
          AcceptedWorkerUiModel.demo(
            customerLatitude: widget.serviceLocation.latitude,
            customerLongitude: widget.serviceLocation.longitude,
          );
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceOnTheWayScreen(
            requestId: widget.requestId,
            category: widget.category,
            serviceLocation: widget.serviceLocation,
            requestDescription: widget.requestDescription,
            requestedAt: widget.requestedAt,
            worker: worker,
            onSubmitReview: widget.onSubmitReview,
            onBackToHome: widget.onBackToHome,
          ),
        ),
      );
    });
  }

  bool get _mustConfirmBack =>
      _status.isSearching || _status == RequestSearchStatus.error;

  Future<void> _handleBack() async {
    if (_cancellationInFlight) return;
    if (_mustConfirmBack) {
      await _confirmCancellation();
      return;
    }
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _confirmCancellation() async {
    if (_dialogOpen || _cancellationInFlight || !_status.canCancel) return;
    _dialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_cancellationInFlight,
      barrierColor: Colors.black.withValues(alpha: .52),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _CancelRequestDialog(
          isCancelling: _cancellationInFlight,
          onKeepSearching: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    _dialogOpen = false;
    if (!mounted || confirmed != true || !_status.canCancel) return;
    await _cancelRequest();
  }

  Future<void> _cancelRequest() async {
    if (_cancellationInFlight || !_status.canCancel) return;
    setState(() {
      _cancellationInFlight = true;
      _status = RequestSearchStatus.cancelling;
    });

    try {
      // BACKEND INTEGRATION:
      // Call the real cancel-request endpoint with widget.requestId and wait
      // for a successful response. Only then pop this route. If it fails,
      // return false so the user stays here and sees an error. Until a handler
      // is connected, confirmation intentionally does not navigate.
      final cancellationHandler = widget.onCancelRequested;
      if (cancellationHandler == null) {
        if (!mounted) return;
        if (widget.enableDemoFlow && Navigator.canPop(context)) {
          Navigator.pop(context);
          return;
        }
        setState(() {
          _cancellationInFlight = false;
          _status = RequestSearchStatus.searching;
        });

        // TODO(CANCEL-REQUEST BACKEND INTEGRATION):
        // final cancelled = await repository.cancelRequest(widget.requestId);
        // if (cancelled && mounted) Navigator.pop(context);
        // If it fails, keep this screen open and show the backend error.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation is waiting for backend integration.'),
          ),
        );
        return;
      }

      final cancelled = await cancellationHandler();
      if (!mounted) return;
      if (!cancelled) {
        _statusPollTimer?.cancel();
        setState(() {
          _cancellationInFlight = false;
          _status = RequestSearchStatus.error;
        });
        _showCancellationError();
        return;
      }
      _statusPollTimer?.cancel();
      setState(() => _status = RequestSearchStatus.cancelled);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _statusPollTimer?.cancel();
      setState(() {
        _cancellationInFlight = false;
        _status = RequestSearchStatus.error;
      });
      _showCancellationError();
    }
  }

  void _showCancellationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not cancel the request. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: PopScope<void>(
        canPop: !_mustConfirmBack && !_cancellationInFlight,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_cancellationInFlight) {
            unawaited(_confirmCancellation());
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFBF9FF),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
                  sliver: SliverList.list(
                    children: [
                      _FindingHeader(
                        category: widget.category,
                        onBack: _handleBack,
                      ),
                      const SizedBox(height: 18),
                      RequestSummaryCard(
                        requestId: widget.requestId,
                        category: widget.category,
                        isFound: _status.isFound,
                      ),
                      const SizedBox(height: 18),
                      _SearchStatusSection(
                        status: _status,
                        offersSent: widget.offersSent,
                      ),
                      const SizedBox(height: 18),
                      ServiceSearchMap(
                        location: widget.serviceLocation,
                        workerCoordinates: widget.workerCoordinates,
                      ),
                      const SizedBox(height: 14),
                      const _VerifiedProfessionalBanner(),
                      const SizedBox(height: 14),
                      RequestDetailsCard(
                        location: widget.serviceLocation,
                        requestedAt: widget.requestedAt,
                        addressText: widget.addressText,
                      ),
                      const SizedBox(height: 20),
                      _CancelRequestButton(
                        isBusy: _cancellationInFlight,
                        enabled: _status.canCancel,
                        onPressed: _confirmCancellation,
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: AppColors.grey,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'You can cancel before a professional is assigned.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _FindingHeader extends StatelessWidget {
  const _FindingHeader({required this.category, required this.onBack});

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
                'Finding Service Person',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ServiceCategoryPresentation.serviceTitleFor(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({
    required this.requestId,
    required this.category,
    required this.isFound,
    super.key,
  });

  final String requestId;
  final ServiceCategory category;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    final cleanId = requestId.trim().isEmpty ? 'Pending' : requestId.trim();
    return _WhiteCard(
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
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID: #$cleanId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ServiceCategoryPresentation.issueLabelFor(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFound
                  ? AppColors.green.withValues(alpha: .12)
                  : AppColors.lightPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isFound ? 'Accepted' : 'In Progress',
              style: TextStyle(
                color: isFound ? AppColors.green : AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedSearchingText extends StatefulWidget {
  const AnimatedSearchingText({required this.status, super.key});

  final RequestSearchStatus status;

  @override
  State<AnimatedSearchingText> createState() => _AnimatedSearchingTextState();
}

class _AnimatedSearchingTextState extends State<AnimatedSearchingText>
    with SingleTickerProviderStateMixin {
  static const _searchingText = 'Searching...';
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedSearchingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.status.isSearching) {
      _controller.duration = const Duration(milliseconds: 1800);
      _controller.repeat();
    } else if (widget.status.isFound) {
      _controller.duration = const Duration(milliseconds: 650);
      unawaited(_playAcceptedAnimation());
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  Future<void> _playAcceptedAnimation() async {
    await _controller.forward(from: 0);
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settledText = switch (widget.status) {
      RequestSearchStatus.searching => _searchingText,
      RequestSearchStatus.accepted => 'Accepted...',
      RequestSearchStatus.workerOnTheWay => 'Accepted...',
      RequestSearchStatus.arrived => 'Accepted...',
      RequestSearchStatus.working => 'Accepted...',
      RequestSearchStatus.completed => 'Accepted...',
      RequestSearchStatus.cancelling => 'Cancelling...',
      RequestSearchStatus.cancelled => 'Request cancelled',
      RequestSearchStatus.error => 'Search interrupted',
    };
    if (!widget.status.isSearching) {
      final statusText = Text(
        settledText,
        key: const ValueKey('search-status-text'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.status.isFound ? AppColors.green : AppColors.primary,
          fontSize: 22,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      );
      return Center(
        child: widget.status.isFound
            ? ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.06).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: statusText,
              )
            : statusText,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        const revealSteps = _searchingText.length + 3;
        final visibleCharacters = (_controller.value * revealSteps)
            .floor()
            .clamp(1, _searchingText.length);
        return Center(
          child: SizedBox(
            width: 158,
            child: Text(
              _searchingText.substring(0, visibleCharacters),
              key: const ValueKey('search-status-text'),
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                letterSpacing: .35,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchStatusSection extends StatelessWidget {
  const _SearchStatusSection({required this.status, this.offersSent});

  final RequestSearchStatus status;
  final int? offersSent;

  @override
  Widget build(BuildContext context) {
    final showOffersSent = status.isSearching && (offersSent ?? 0) > 0;
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 17),
      child: Column(
        children: [
          const Text(
            'We\'re finding the best professional for you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'This usually takes 2–5 minutes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11.5,
              fontFamily: 'Poppins',
            ),
          ),
          if (showOffersSent) ...[
            const SizedBox(height: 3),
            Text(
              '$offersSent professional${offersSent == 1 ? '' : 's'} notified',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11.5,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AnimatedSearchingText(status: status),
        ],
      ),
    );
  }
}

class _VerifiedProfessionalBanner extends StatelessWidget {
  const _VerifiedProfessionalBanner();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/verified_and__trusted_professional.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We verify all our professionals',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Background checked • Verified • Rated',
                  style: TextStyle(color: AppColors.grey, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              // TODO(VERIFIED-PROFESSIONALS NAVIGATION): Navigate to the
              // future professional-verification information page here.
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ...));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Professional verification details coming soon.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Learn More',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 17),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RequestDetailsCard extends StatelessWidget {
  const RequestDetailsCard({
    required this.location,
    required this.requestedAt,
    this.addressText,
    super.key,
  });

  final SelectedServiceLocation location;
  final DateTime requestedAt;

  /// Backend-resolved address (`address_text`). Preferred over the
  /// device-selected [location.landmark] when present, since it's the
  /// authoritative reverse-geocoded value rather than a client-side hint.
  final String? addressText;

  String get _address {
    final resolved = addressText?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final landmark = location.landmark?.trim();
    return landmark == null || landmark.isEmpty
        ? 'Selected service location'
        : landmark;
  }

  String get _relativeTime {
    final difference = DateTime.now().difference(requestedAt.toLocal());
    if (difference.inMinutes < 1) return 'Requested just now';
    if (difference.inMinutes < 60) {
      return 'Requested ${difference.inMinutes} minutes ago';
    }
    return 'Requested today';
  }

  String get _formattedTime {
    final local = requestedAt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return 'Today, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.location_on_outlined,
            title: _address,
            subtitle:
                '${location.latitude.toStringAsFixed(6)}, '
                '${location.longitude.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.access_time_rounded,
            title: _relativeTime,
            subtitle: _formattedTime,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
        Icon(icon, size: 19, color: AppColors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelRequestButton extends StatelessWidget {
  const _CancelRequestButton({
    required this.isBusy,
    required this.enabled,
    required this.onPressed,
  });

  final bool isBusy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        key: const ValueKey('cancel-request-button'),
        onPressed: enabled && !isBusy ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF3D55),
          disabledBackgroundColor: const Color(0xFFFFA0AD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cancel_outlined, color: Colors.white),
        label: Text(
          isBusy ? 'Cancelling...' : 'Cancel Request',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CancelRequestDialog extends StatelessWidget {
  const _CancelRequestDialog({
    required this.isCancelling,
    required this.onKeepSearching,
    required this.onConfirm,
  });

  final bool isCancelling;
  final VoidCallback onKeepSearching;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancel service request?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'We are still searching for a professional. Are you sure you '
                'want to cancel this request?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isCancelling ? null : onKeepSearching,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Keep Searching'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isCancelling ? null : onConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Yes, Cancel Request',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1A1233),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
