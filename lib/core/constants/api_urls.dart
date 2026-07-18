

// class ApiUrls {
//   // Android Emulator
//   static const String baseUrl = "http://10.0.2.2:8000/api/auth";
//
//   // Physical phone example:
//   static const String baseUrl = "http://192.168.1.8:8000/api/auth";
//
//   static const String login = "$baseUrl/login/";
//   static const String refresh = "$baseUrl/refresh/";
//   static const String logout = "$baseUrl/logout/";
// }

class ApiUrls {
  // Android Emulator
  // static const String baseUrl = "http://10.0.2.2:8000/api";

  //   // Physical phone example:
  // static const String baseUrl = "http://192.168.1.8:8000/api/auth";

  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Authentication
  static const String signup = "$baseUrl/auth/signup/";

  static const String serviceRequests = "$baseUrl/services/bookings/";

  static const String verifyOtp = "$baseUrl/auth/verify-otp/";
  static const String resendOtp = "$baseUrl/auth/resend-otp/";
  static const String login = "$baseUrl/auth/login/";
  static const String refresh = "$baseUrl/auth/refresh/";
  static const String logout = "$baseUrl/auth/logout/";
  static const String workerDashboard = "$baseUrl/auth/worker/dashboard/";

  static const String workerProfile = "$baseUrl/auth/worker/profile/";
  static const String workerSkills = "$baseUrl/auth/worker/skills/";
  static const String selectWorkerSkills = "$baseUrl/auth/worker/select-skills/";
  static const String workerStatus = "$baseUrl/auth/worker/status/";
  static const String workerLocation = "$baseUrl/auth/worker/location/";
  static const String updateWorkerSkills = "$baseUrl/auth/worker/update-skills/";

  // GET — returns the pending booking offers for the logged-in worker.
  // Response: { "count": <int>, "requests": [ { offer_id, customer_name,
  //             service, service_icon, description, address, distance_km,
  //             created_at } ] }
  static const String workerIncomingRequests =
      "$baseUrl/auth/worker/incoming-requests/";

  // GET — full detail of one offer, including media.
  // Response adds to the list shape: latitude, longitude, photos (list of
  // relative media URLs), video (relative media URL or null), status.
  // [offerId] is the BookingOffer id, not a booking id.
  static String workerRequestDetail(String offerId) =>
      "$baseUrl/auth/worker/request/$offerId/";

  // POST — accept an offer. Takes no request body.
  // Response: { "message": "...", "booking_id": <int>, "status": "scheduled" }
  static String workerAcceptRequest(String offerId) =>
      "$baseUrl/auth/worker/request/$offerId/accept/";

  // POST — reject an offer. Takes no request body.
  // Response 200: { "message": "Request rejected successfully" }
  // Response 401: { "detail": "Authentication credentials were not provided." }
  // Response 403: { "detail": "Only workers can access this endpoint." }
  static String workerRejectRequest(String offerId) =>
      "$baseUrl/auth/worker/request/$offerId/reject/";

  // Resolves a media path returned by the backend into a loadable URL.
  //
  // WHY this exists:
  //   Django's ImageField.url returns a path relative to MEDIA_URL, e.g.
  //   "/media/skills/icons/plumbing.png" — not an absolute URL. Passing that
  //   straight to Image.network fails. Some endpoints (worker profile photo)
  //   already return an absolute URL, so absolute inputs are passed through
  //   unchanged.
  static String resolveMediaUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${Uri.parse(baseUrl).origin}$path';
  }


  // POST multipart/form-data — field: "profile_photo" → <image file>
  // Response: { "message": "...", "profile_photo": "<absolute URL>" }
  static const String workerProfilePhoto = "$baseUrl/auth/worker/profile/photo/";

  // POST multipart/form-data
  // Fields: citizenship_front (File, required), citizenship_back (File, required),
  //         experience_document (File, optional)
  // Response: { "message": "...", "documents": { "citizenship_front": "...",
  //             "citizenship_back": "...", "experience_document": "...",
  //             "is_verified": false } }
  static const String workerIdentity = "$baseUrl/auth/worker/identity/";

  static const String categories = "$baseUrl/services/categories/";

  // GET — polled while the customer is on the "Finding Service Person"
  // screen to detect worker assignment.
  // Response 200, no worker yet: { "id": <int>, "status": "active",
  //   "worker": null }
  // Response 200, worker assigned: { "id", "status", "worker": { "id",
  //   "full_name", "phone_number", "average_rating", "completed_jobs",
  //   "profile_photo", "current_latitude", "current_longitude" } }
  // Response 404 — booking doesn't exist, or doesn't belong to the
  // requesting customer.
  static String bookingStatus(String bookingId) =>
      "$baseUrl/services/bookings/$bookingId/status/";
}