import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/accepted_worker_ui_model.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/service_category.dart';
import '../../../services/booking_history_store.dart';
import '../../../services/service_request/booking_status_service.dart';
import 'service_on_the_way_screen.dart';

/// Fetches the real current state of an in-progress booking (via
/// `GET .../bookings/<id>/status/`) and hands it to [ServiceOnTheWayScreen] —
/// reached by tapping an "In Progress" entry in the customer's booking
/// history, as opposed to the live post-acceptance flow that builds that
/// screen directly from data already held in memory by the request flow.
class CustomerBookingTrackingLoader extends StatefulWidget {
  const CustomerBookingTrackingLoader({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<CustomerBookingTrackingLoader> createState() =>
      _CustomerBookingTrackingLoaderState();
}

class _CustomerBookingTrackingLoaderState
    extends State<CustomerBookingTrackingLoader> {
  final BookingStatusService _service = BookingStatusService();

  bool _isLoading = true;
  String? _error;
  ServiceOnTheWayScreen? _screen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _slugFromName(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.fetchStatus(widget.bookingId);
      final worker = response.worker;
      if (worker == null) {
        throw const BookingStatusException(
          'This booking has no assigned technician yet.',
        );
      }

      final categoryName = response.categoryName ?? '';
      final category = ServiceCategory(
        id: categoryName,
        name: categoryName,
        slug: _slugFromName(categoryName),
      );

      final serviceLocation = SelectedServiceLocation(
        latitude: response.latitude ?? 0,
        longitude: response.longitude ?? 0,
        landmark: response.addressText,
        source: 'booking_history',
      );

      final acceptedWorker = AcceptedWorkerUiModel(
        id: worker.id,
        name: worker.fullName,
        phoneNumber: worker.phoneNumber,
        profileImageUrl: worker.profilePhoto,
        rating: worker.averageRating,
        completedJobs: worker.completedJobs,
        latitude: worker.currentLatitude ?? serviceLocation.latitude,
        longitude: worker.currentLongitude ?? serviceLocation.longitude,
      );

      if (!mounted) return;
      setState(() {
        _screen = ServiceOnTheWayScreen(
          requestId: widget.bookingId,
          category: category,
          serviceLocation: serviceLocation,
          requestDescription: response.description ?? '',
          requestedAt: response.createdAt ?? DateTime.now(),
          worker: acceptedWorker,
          visitCharge: response.visitCharge,
          initialStatus: response.jobProgress,
          // Real fetched data is being used from here on — the screen's
          // built-in demo timers must stay off so nothing fabricated
          // overlays it. Real-time updates from here come from its own
          // ws/bookings/<id>/ connection (enableLocationPolling default).
          enableDemoFlow: false,
          onCancelRequested: () async {
            await _service.cancelBooking(widget.bookingId);
            BookingHistoryStore.instance.refreshNow();
            return true;
          },
        );
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
            'Tracking',
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

    return _screen!;
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
