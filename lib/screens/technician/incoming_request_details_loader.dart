import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/technician/incoming_service_request_details.dart';
import '../../services/incoming_request_service.dart';
import 'incoming_request_details_screen.dart';
import 'incoming_requests_screen.dart';

/// How often to quietly re-check the offer's status while the worker is
/// sitting on this screen, so an expiry or another worker taking it is
/// noticed without waiting for the worker to tap Accept/Decline. The offer
/// window itself is 120 seconds server-side, so this gives several checks
/// within that time.
const Duration _staleCheckInterval = Duration(seconds: 12);

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
  Timer? _staleCheckTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _staleCheckTimer?.cancel();
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
      _startStaleCheck();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Quietly re-fetches this offer on a timer so an expiry or another
  /// worker accepting it first is noticed while the worker is just looking
  /// at the screen, not only when they tap Accept/Decline. Uses the exact
  /// same detail endpoint the initial load already uses — no new endpoint,
  /// no visible loading state.
  void _startStaleCheck() {
    _staleCheckTimer?.cancel();
    _staleCheckTimer = Timer.periodic(_staleCheckInterval, (_) async {
      if (!mounted) return;
      try {
        final latest = await _service.fetchRequestDetail(widget.offerId);
        if (!mounted) return;
        if (latest.status != null && latest.status != 'pending') {
          _handleOfferNoLongerAvailable(latest.status!);
        }
      } catch (_) {
        // A single failed check is likely a transient network issue — leave
        // the timer running and try again next tick rather than disturbing
        // the worker over something that might not even be real.
      }
    });
  }

  void _handleOfferNoLongerAvailable(String status) {
    _staleCheckTimer?.cancel();
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
    _staleCheckTimer?.cancel();
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
      onAcceptedNavigation: () async {
        if (!mounted) return;
        Navigator.pop(context, true);
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
