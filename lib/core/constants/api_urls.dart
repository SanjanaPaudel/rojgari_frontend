

// class ApiUrls {
//   // Android Emulator
//   static const String baseUrl = "http://10.0.2.2:8000/api/auth";
//
//   // Physical phone example:
//   // static const String baseUrl = "http://192.168.1.8:8000/api/auth";
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
  static const String updateWorkerSkills = "$baseUrl/auth/worker/update-skills/";


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
}