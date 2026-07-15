import '../../models/service_request/service_request_payload.dart';
import 'service_request_repository.dart';

class MockServiceRequestRepository implements ServiceRequestRepository {
  const MockServiceRequestRepository();

  @override
  Future<ServiceRequestResult> createServiceRequest(
    ServiceRequestPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return ServiceRequestResult(
      requestId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      status: 'searching',
      createdAt: DateTime.now().toUtc(),
      message: 'Frontend request created successfully.',
    );
  }
}
