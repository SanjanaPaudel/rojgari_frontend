class ApiUrls {
  // static const String baseUrl = "http://10.0.2.2:8000/api";
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static const String signup = "$baseUrl/auth/signup/";
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
  static const String categories=  "$baseUrl/services/categories/";
}