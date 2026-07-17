import '../../models/technician/incoming_service_request_details.dart';
import '../../models/technician/technician_active_job_model.dart';
import '../../models/technician/technician_job_status.dart';

class TechnicianJobException implements Exception {
  const TechnicianJobException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class TechnicianJobRepository {
  Future<TechnicianActiveJobModel> acceptRequest(
    IncomingServiceRequestDetails request,
  );

  Future<TechnicianActiveJobModel> getActiveJob(String requestId);

  Future<void> updateJobStatus(String requestId, TechnicianJobStatus status);

  Future<void> updateTechnicianLocation(
    String requestId,
    double latitude,
    double longitude,
  );

  Future<void> completeJob(String requestId);
}
