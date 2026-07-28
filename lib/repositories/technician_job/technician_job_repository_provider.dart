import 'api_technician_job_repository.dart';
import 'technician_job_repository.dart';

// ============================================================================
// ACTIVE: ApiTechnicianJobRepository (real backend)
// ============================================================================
//
// MockTechnicianJobRepository still exists in this folder for tests/local UI
// preview, but is not used by the app at runtime. Integration is being done
// one capability at a time — only getActiveJob (GET current-job/) is
// exercised for real so far. acceptRequest is deliberately never called
// through this repository (the real accept happens via
// IncomingRequestService instead, to keep the existing 409/expired-offer
// handling); updateJobStatus (start job) and completeJob are still pending
// their own integration steps.
// ============================================================================
final TechnicianJobRepository technicianJobRepository =
    ApiTechnicianJobRepository();
