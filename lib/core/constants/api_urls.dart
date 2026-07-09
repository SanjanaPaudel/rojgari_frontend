class ApiUrls {
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static const String signup = "$baseUrl/auth/signup/";
  static const String verifyOtp = "$baseUrl/auth/verify-otp/";
  static const String resendOtp = "$baseUrl/auth/resend-otp/";
  static const String login = "$baseUrl/auth/login/";
  static const String refresh = "$baseUrl/auth/refresh/";
  static const String logout = "$baseUrl/auth/logout/";
  static const String workerDashboard = "$baseUrl/auth/worker/dashboard/";

  static const String workerProfile = "$baseUrl/worker/profile/";
  static const String workerSkills = "$baseUrl/worker/skills/";
  static const String selectWorkerSkills = "$baseUrl/worker/select-skills/";
}