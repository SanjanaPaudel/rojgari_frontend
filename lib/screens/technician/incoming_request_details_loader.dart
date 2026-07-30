import 'dart:async';

import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import '../../core/constants/colors.dart';
import '../../dev_testing/fake_worker_movement.dart';
import '../../models/service_request/service_booking_demo_config.dart';
import '../../models/technician/incoming_service_request_details.dart';
import '../../repositories/technician_job/technician_job_repository_provider.dart';
import '../../services/incoming_request_service.dart';
import '../../services/incoming_requests_store.dart';
import '../../services/location/location_service.dart';
import 'incoming_request_details_screen.dart';
import 'incoming_requests_screen.dart';
import 'technician_active_job_screen.dart';

/// Fetches one incoming request and hands it to [IncomingRequestDetailsScreen].
///
/// WHY this wrapper exists:
///   IncomingRequestDetailsScreen is deliberately presentational — its model
///   states the UI must not make the HTTP request directly, and its accept and
///   decline actions are injected callbacks. This widget owns the network work
///   (load, accept) so that screen stays free of it.
///
/// Pops `true` after a successful accept so the caller can refresh its list.
class IncomingRequestDetailsLoader extends StatefulWidget {
  const IncomingRequestDetailsLoader({super.key, required this.offerId});

  /// The BookingOffer id, from IncomingRequest.id.
  final String offerId;

  @override
  State<IncomingRequestDetailsLoader> createState() =>
      _IncomingRequestDetailsLoaderState();
}

class _IncomingRequestDetailsLoaderState
    extends State<IncomingRequestDetailsLoader> {
  final IncomingRequestService _service = IncomingRequestService();

  IncomingServiceRequestDetails? _request;
  bool _isLoading = true;
  String? _error;
  bool _staleCheckInFlight = false;

  @override
  void initState() {
    super.initState();
    // Reference-counted — safe alongside whichever screen underneath (home
    // preview or the full list) already attached; the socket itself is
    // shared, not duplicated per screen.
    IncomingRequestsStore.instance.attach();
    IncomingRequestsStore.instance.requests.addListener(_handleOffersChanged);
    _load();
  }

  @override
  void dispose() {
    IncomingRequestsStore.instance.requests.removeListener(
      _handleOffersChanged,
    );
    IncomingRequestsStore.instance.detach();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await _service.fetchRequestDetail(widget.offerId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Fires on every change to IncomingRequestsStore's shared pending-offers
  /// list — kept fresh by IncomingRequestsStore's own socket (new offers,
  /// backfills, offer_cancelled pushes), not a poll of our own. If this
  /// screen's offer is no longer in that list, it's no longer pending —
  /// expired, accepted by someone else, or cancelled — so do one REST fetch
  /// to find out which, for the differentiated message below.
  void _handleOffersChanged() {
    if (!mounted || _isLoading || _error != null) return;
    final stillPending = IncomingRequestsStore.instance.requests.value.any(
      (request) => request.id == widget.offerId,
    );
    if (!stillPending) unawaited(_checkOfferStillAvailable());
  }

  Future<void> _checkOfferStillAvailable() async {
    if (_staleCheckInFlight) return;
    _staleCheckInFlight = true;
    try {
      final latest = await _service.fetchRequestDetail(widget.offerId);
      if (!mounted) return;
      if (latest.status != null && latest.status != 'pending') {
        _handleOfferNoLongerAvailable(latest.status!);
      }
    } catch (_) {
      // Transient failure — if this offer genuinely went away, the store
      // will still reflect that and nothing here needs to retry on its own.
    } finally {
      _staleCheckInFlight = false;
    }
  }

  void _handleOfferNoLongerAvailable(String status) {
    final message = switch (status) {
      'expired' => 'This request has expired and is no longer available.',
      'accepted' ||
      'cancelled' => 'This request has already been taken by another technician.',
      _ => 'This request is no longer available.',
    };
    _showOfferGoneDialogThenGoToList(message);
  }

  /// Shows a popup with [message] that the worker must dismiss with "OK",
  /// then clears back to the incoming-requests list — regardless of whether
  /// this screen was reached from the home-screen preview or from the list
  /// itself, the worker always ends up on the list afterwards, and it will
  /// show fresh data since that screen re-fetches every time it opens.
  Future<void> _showOfferGoneDialogThenGoToList(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request unavailable'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _goToIncomingRequestsList();
  }

  /// Clears back to the incoming-requests list — regardless of whether this
  /// screen was reached from the home-screen preview or from the list
  /// itself, the worker always ends up on a fresh copy of the list, which
  /// re-fetches on its own the moment it opens (so a just-rejected/expired
  /// offer is already gone from it before the worker even sees it).
  Future<void> _goToIncomingRequestsList() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const IncomingRequestsScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Request Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _ErrorBody(message: _error!, onRetry: _load),
      );
    }

    return IncomingRequestDetailsScreen(
      request: _request!,
      // Throwing propagates to the screen's own error handling, which shows a
      // message and clears its processing state.
      onAcceptRequest: (offerId) => _service.acceptRequest(offerId),
      // The real POST .../accept/ call already happened by the time this
      // runs (that's onAcceptRequest, above) — the backend has genuinely
      // recorded the acceptance. This fetches the real resulting job via
      // GET .../current-job/ (getActiveJob) — deliberately NOT calling
      // repository.acceptRequest() here, since that would trigger a second,
      // redundant accept call against an offer that's no longer "pending"
      // and fail.
      onAcceptedNavigation: () async {
        if (!mounted) return;
        final repository = technicianJobRepository;
        final activeJob = await repository.getActiveJob(widget.offerId);
        if (!mounted) return;
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianActiveJobScreen(
              job: activeJob,
              repository: repository,
              // Real accept/current-job data is being used from here on —
              // the screen's built-in fake-GPS-travel/auto-advancing-status
              // demo timers must stay off so nothing fabricated overlays it.
              enableDemoFlow: false,
              // Turns on the screen's real device-location tracking
              // (permission check, live GPS stream, PATCH .../location/
              // publishing, arrival detection).
              enableDeviceLocation: true,
              // TEMP TEST-ONLY (remove before shipping): when
              // ServiceBookingDemoConfig.useFakeWorkerMovement is true, swaps
              // in a fake coordinate source instead of the real
              // device/browser GPS, walking from this job's starting
              // position to the real customer coordinates. Everything
              // downstream of it (arrival detection, status persistence) is
              // the real, unmodified code path — see
              // dev_testing/fake_worker_movement.dart. When the flag is
              // false, omitting this parameter falls back to
              // TechnicianActiveJobScreen's own default — the real
              // LocationService reading actual device GPS.
              locationService: ServiceBookingDemoConfig.useFakeWorkerMovement
                  ? FakeWorkerLocationService(
                      start: LatLng(
                        activeJob.technicianLatitude,
                        activeJob.technicianLongitude,
                      ),
                      destination: LatLng(
                        activeJob.customerLatitude,
                        activeJob.customerLongitude,
                      ),
                    )
                  : const LocationService(),
            ),
          ),
        );
      },
      onDeclineRequest: (offerId) => _service.rejectRequest(offerId),
      // A successful decline always takes the worker to a fresh
      // "All Incoming Requests" list — the rejected offer is already gone
      // from it (and from the home screen's preview, since both read the
      // same shared store) by the time this list is shown.
      onDeclinedNavigation: _goToIncomingRequestsList,
      onOfferNoLongerAvailable: _showOfferGoneDialogThenGoToList,
    );
  }
}

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 46,
              color: Color(0xffBFC4D2),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xffD8CCFB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
