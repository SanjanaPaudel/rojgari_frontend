import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/technician/incoming_service_request_details.dart';
import '../../services/incoming_request_service.dart';
import 'incoming_request_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
      // onDeclineRequest is intentionally omitted: the backend has no decline
      // route. BookingOffer supports a "rejected" status but nothing sets it,
      // so the screen keeps showing its "not connected" message until a
      // POST .../request/<offer_id>/decline/ endpoint exists.
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
