import 'api_service_request_repository.dart';
import 'mock_service_request_repository.dart';
import 'service_request_repository.dart';

// ============================================================================
// BACKEND DEVELOPER: SWITCH MOCK SUBMISSION TO THE REAL API
// ============================================================================
//
// CURRENTLY ACTIVE: ApiServiceRequestRepository
//
// This allows the completed frontend Request Page to work before the backend
// endpoint is ready. Do not remove the mock until all of these are confirmed:
//
// 1. POST /api/customer/service-requests/ exists.
// 2. The login flow saves a valid access token.
// 3. Multipart text-field names match the API.
// 4. Repeated image field name is "photos".
// 5. Optional video field name is "video".
// 6. Backend reverse geocoding is working.
// 7. Backend success and error responses can be parsed.
//
// AFTER THE BACKEND IS READY, replace MockServiceRequestRepository() below
// with ApiServiceRequestRepository(). If the API repository requires another
// existing dependency, pass it here using the project's dependency pattern.
//
// Do not change the Request Page UI, final button, location UI, media pickers,
// schedule card, or validation. Only switch the repository implementation.
// ============================================================================
final ServiceRequestRepository serviceRequestRepository =
    ApiServiceRequestRepository();

// BACKEND DEVELOPER:
// After the endpoint contract and real login/token flow are confirmed,
// uncomment the API repository import, replace the value above with the value
// below, and change nothing in the UI:
// final ServiceRequestRepository serviceRequestRepository =
//     ApiServiceRequestRepository();
