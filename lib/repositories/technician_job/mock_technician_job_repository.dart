import '../../models/technician/incoming_service_request_details.dart';
import '../../models/technician/technician_active_job_model.dart';
import '../../models/technician/technician_job_status.dart';
import 'technician_job_repository.dart';

class MockTechnicianJobRepository implements TechnicianJobRepository {
  MockTechnicianJobRepository({
    this.delay = const Duration(milliseconds: 350),
    this.failAccept = false,
    this.failComplete = false,
  });

  static const _customerLatitude = 27.671234;
  static const _customerLongitude = 85.339876;
  static const _technicianLatitude = 27.6782;
  static const _technicianLongitude = 85.3318;

  final Duration delay;
  final bool failAccept;
  final bool failComplete;
  final Map<String, TechnicianActiveJobModel> _jobs = {};

  @override
  Future<TechnicianActiveJobModel> acceptRequest(
    IncomingServiceRequestDetails request,
  ) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failAccept) {
      throw const TechnicianJobException(
        'This request could not be accepted. Please try again.',
      );
    }
    final now = DateTime.now();
    final job = TechnicianActiveJobModel.fromIncomingRequest(
      request,
      requestedAt: now.subtract(const Duration(minutes: 8)),
      acceptedAt: now,
      fallbackCustomerLatitude: _customerLatitude,
      fallbackCustomerLongitude: _customerLongitude,
      technicianLatitude: _technicianLatitude,
      technicianLongitude: _technicianLongitude,
    );
    _jobs[job.requestId] = job;
    return job;
  }

  @override
  Future<TechnicianActiveJobModel> getActiveJob(String requestId) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final job = _jobs[requestId];
    if (job == null) {
      throw const TechnicianJobException('Active job was not found.');
    }
    return job;
  }

  @override
  Future<void> updateJobStatus(
    String requestId,
    TechnicianJobStatus status,
  ) async {
    final job = _jobs[requestId];
    if (job != null) _jobs[requestId] = job.copyWith(currentStatus: status);
  }

  @override
  Future<void> updateTechnicianLocation(
    String requestId,
    double latitude,
    double longitude,
  ) async {
    final job = _jobs[requestId];
    if (job != null) {
      _jobs[requestId] = job.copyWith(
        technicianLatitude: latitude,
        technicianLongitude: longitude,
      );
    }
  }

  @override
  Future<void> completeJob(String requestId) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failComplete) {
      throw const TechnicianJobException(
        'The work could not be completed. Please try again.',
      );
    }
    final job = _jobs[requestId];
    if (job != null) {
      _jobs[requestId] = job.copyWith(
        currentStatus: TechnicianJobStatus.completed,
        completedAt: DateTime.now(),
      );
    }
  }
}
