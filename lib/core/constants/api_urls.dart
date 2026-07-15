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
  // Defaults to the Android Emulator host. For a physical phone, pass the
  // development computer's LAN address, for example:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.8:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  // Authentication
  static const String signup = "$baseUrl/auth/signup/";

  // BACKEND TODO: Confirm this route with the Django developer.
  // Suggested route: POST /api/customer/service-requests/
  static const String serviceRequests = "$baseUrl/customer/service-requests/";
}
