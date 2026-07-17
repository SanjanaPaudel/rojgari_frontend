import 'mock_technician_job_repository.dart';
import 'technician_job_repository.dart';

// FRONTEND MOCK DEFAULT:
// This feature deliberately uses a local repository until the technician-job
// API contract is finalized. Keep the UI unchanged when switching providers.
final TechnicianJobRepository technicianJobRepository =
    MockTechnicianJobRepository();

// BACKEND INTEGRATION:
// Replace the mock above with an API implementation that uses the existing
// ApiService/StorageService bearer-token flow. Suggested integration points
// (not confirmed production routes):
// POST  /technician/requests/{requestId}/accept
// GET   /technician/jobs/{requestId}
// PATCH /technician/jobs/{requestId}/status
// PATCH /technician/jobs/{requestId}/location
// POST  /technician/jobs/{requestId}/complete
// Treat 409/already-accepted as an accept failure and do not navigate.
