import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import '../../core/constants/colors.dart';
import '../../dev_testing/fake_worker_movement.dart';
import '../../models/service_request/service_booking_demo_config.dart';
import '../../models/technician/technician_active_job_model.dart';
import '../../repositories/technician_job/technician_job_repository.dart';
import '../../repositories/technician_job/technician_job_repository_provider.dart';
import '../../services/location/location_service.dart';
import 'technician_active_job_screen.dart';

/// Fetches the real current-job details for [offerId] and hands them to
/// [TechnicianActiveJobScreen].
///
/// WHY this exists:
///   Accepting an offer takes two sequential real API calls — the accept
///   POST, then GET current-job/ to fetch the resulting job (deliberately
///   not reused from the accept response; see
///   IncomingRequestDetailsLoader.onAcceptedNavigation for why). Previously
///   both ran back-to-back before ever leaving the request-details screen,
///   so its Accept button spinner covered the full span of both round
///   trips. Splitting the second call out to its own loader means the
///   button clears — and the technician moves to a new screen — right
///   after the accept itself succeeds, with only this screen's own
///   (single-purpose) loading state left to wait through instead.
class TechnicianActiveJobLoader extends StatefulWidget {
  const TechnicianActiveJobLoader({super.key, required this.offerId});

  /// The BookingOffer id — same one IncomingRequestDetailsLoader was showing.
  final String offerId;

  @override
  State<TechnicianActiveJobLoader> createState() =>
      _TechnicianActiveJobLoaderState();
}

class _TechnicianActiveJobLoaderState
    extends State<TechnicianActiveJobLoader> {
  final TechnicianJobRepository _repository = technicianJobRepository;

  TechnicianActiveJobModel? _job;
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
      final job = await _repository.getActiveJob(widget.offerId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is TechnicianJobException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
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
          title: const Text(
            'Accepted Job',
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

    final job = _job!;
    return TechnicianActiveJobScreen(
      job: job,
      repository: _repository,
      // Real accept/current-job data is being used from here on — the
      // screen's built-in fake-GPS-travel/auto-advancing-status demo timers
      // must stay off so nothing fabricated overlays it.
      enableDemoFlow: false,
      // Turns on the screen's real device-location tracking (permission
      // check, live GPS stream, PATCH .../location/ publishing, arrival
      // detection).
      enableDeviceLocation: true,
      // TEMP TEST-ONLY (remove before shipping): when
      // ServiceBookingDemoConfig.useFakeWorkerMovement is true, swaps in a
      // fake coordinate source instead of the real device/browser GPS,
      // walking from this job's starting position to the real customer
      // coordinates. Everything downstream of it (arrival detection, status
      // persistence) is the real, unmodified code path — see
      // dev_testing/fake_worker_movement.dart. When the flag is false,
      // omitting this parameter falls back to TechnicianActiveJobScreen's
      // own default — the real LocationService reading actual device GPS.
      locationService: ServiceBookingDemoConfig.useFakeWorkerMovement
          ? FakeWorkerLocationService(
              start: LatLng(job.technicianLatitude, job.technicianLongitude),
              destination: LatLng(
                job.customerLatitude,
                job.customerLongitude,
              ),
            )
          : const LocationService(),
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
