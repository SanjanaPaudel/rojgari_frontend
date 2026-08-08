
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/api_urls.dart';
import 'api_service.dart';
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService(); // Create an object of ApiService class . An underscore means Private this file

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiUrls.login,
      {
        "phone_number": phone,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    // Save tokens only if login was successful
    if (response.statusCode == 200) {
      await StorageService.saveAccessToken(data["access"]);
      await StorageService.saveRefreshToken(data["refresh"]);
      await StorageService.saveNextScreen(data["next_screen"]);
    }
    return data;

  }

  Future<Map<String, dynamic>> signup({
    required String phone,
    required String password,
    required String fullName,
    required String email,
    required String confirmPassword,
    Uint8List? profilePhotoBytes, // Image bytes — works on Web and native
    String? profilePhotoName,     // Original filename e.g. "photo.jpg"
    required String role,
  }) async {

    final streamedResponse = await _apiService.multipartPost(
      ApiUrls.signup,
      {
        "role": role,
        "full_name": fullName,
        "phone_number": phone,
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
      },
      profilePhotoBytes,
      profilePhotoName,
    );

    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiService.post(
      ApiUrls.verifyOtp,
      {
        "phone_number": phone,
        "otp": otp,
      },
    );

    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> resendOTP({
    required String phone,
  }) async {
    final response = await _apiService.post(
      ApiUrls.resendOtp,
      {
        "phone_number": phone,
      },
    );

    final data = jsonDecode(response.body);

    return data;
  }

  // Forgot password flow (email-based, any role). Each method returns the
  // raw decoded response body — callers check response["success"] the same
  // way the signup OTP flow above does. reset-password's error body is the
  // one exception: it can also come back as bare DRF field-array errors
  // ({"confirm_password": [...]}, {"new_password": [...]}) with no
  // "success" key at all, so callers of resetPassword must check those
  // fields directly rather than relying solely on response["success"].

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await _apiService.post(
      ApiUrls.forgotPassword,
      {"email": email},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resendForgotPasswordOtp({
    required String email,
  }) async {
    final response = await _apiService.post(
      ApiUrls.resendForgotPasswordOtp,
      {"email": email},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.post(
      ApiUrls.verifyForgotPasswordOtp,
      {"email": email, "otp": otp},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post(
      ApiUrls.resetPassword,
      {
        "email": email,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      },
    );

    return jsonDecode(response.body);
  }

}