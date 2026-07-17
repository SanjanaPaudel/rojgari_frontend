import 'api_service_request_repository.dart';
import 'service_request_repository.dart';

// ============================================================================
// ACTIVE: ApiServiceRequestRepository (real backend, POST /services/bookings/)
// ============================================================================
//
// MockServiceRequestRepository still exists in this folder for tests/local UI
// preview (see ServiceRequestScreen's `repository` constructor param), but is
// not used by the app at runtime. Swap the value below only if the real
// endpoint becomes temporarily unavailable and you need to demo the UI.
// ============================================================================
final ServiceRequestRepository serviceRequestRepository =
    ApiServiceRequestRepository();
