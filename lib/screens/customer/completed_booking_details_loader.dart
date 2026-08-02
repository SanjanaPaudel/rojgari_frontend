import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/service_request/booking_status_response.dart';
import '../../services/service_request/booking_status_service.dart';
import 'completed_booking_details_screen.dart';
import 'debug_completed_booking_fixture.dart';

/// Fetches one completed booking (via `GET .../bookings/<id>/status/`, the
/// same endpoint CustomerBookingTrackingLoader uses for in-progress ones)
/// and hands it to [CompletedBookingDetailsScreen] — reached by tapping a
/// "Completed" entry in the customer's booking history.
class CompletedBookingDetailsLoader extends StatefulWidget {
  const CompletedBookingDetailsLoader({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<CompletedBookingDetailsLoader> createState() =>
      _CompletedBookingDetailsLoaderState();
}

class _CompletedBookingDetailsLoaderState
    extends State<CompletedBookingDetailsLoader> {
  final BookingStatusService _service = BookingStatusService();

  bool _isLoading = true;
  String? _error;
  BookingStatusResponse? _booking;

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

    // DEBUG-ONLY (see debug_completed_booking_fixture.dart) — delete this
    // block, along with that file, once the booking history list is wired to
    // real bookingIds and this can always call the real API below.
    if (kDebugMode && debugUseFakeCompletedBooking) {
      setState(() {
        _booking = debugFakeCompletedBooking();
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _service.fetchStatus(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = response;
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
            'Booking Details',
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

    return CompletedBookingDetailsScreen(booking: _booking!);
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
