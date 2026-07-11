
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_urls.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
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
    File? profilePhoto,
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
      profilePhoto,
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

}