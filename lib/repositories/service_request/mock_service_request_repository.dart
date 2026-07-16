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
      id: DateTime.now().millisecondsSinceEpoch,
      category: payload.categoryName,
      description: payload.description,
      addressText: null,
      status: 'active',
      message: 'Frontend request created successfully.',
    );
  }
}
