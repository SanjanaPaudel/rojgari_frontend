import 'api_service_request_repository.dart';
import 'service_request_repository.dart';

// The real repository is active because login now stores the backend JWT,
// dashboard categories carry real integer IDs, and the booking endpoint uses
// the confirmed Django multipart contract. The Request Page UI is unchanged.
final ServiceRequestRepository serviceRequestRepository =
    ApiServiceRequestRepository();
