class ApiUrls {
  // Defaults to the Android Emulator host. API_BASE_URL must contain only the
  // server origin (no trailing /api). Examples:
  // Physical phone: --dart-define=API_BASE_URL=http://192.168.1.8:8000
  // Windows:        --dart-define=API_BASE_URL=http://127.0.0.1:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Authentication
  static const String signup = "$baseUrl/api/auth/signup/";
  static const String login = "$baseUrl/api/auth/login/";
  static const String refresh = "$baseUrl/api/auth/refresh/";

  // Services
  static const String serviceCategories = "$baseUrl/api/services/categories/";
  static const String createBooking = "$baseUrl/api/services/bookings/";
}
