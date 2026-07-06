
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_urls.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class AuthService {
  final ApiService _apiService = ApiService(); // Create an object of ApiService class . An underscore means Private this file

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    print("Entered login()");
    debugPrint("Inside AuthService.login()");
    final response = await _apiService.post(
      ApiUrls.login,
      {
        "phone_number": phone,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

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
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.post(
      ApiUrls.verifyOtp,
      {
        "email": email,
        "otp": otp,
      },
    );

    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> resendOTP({
    required String email,
  }) async {
    final response = await _apiService.post(
      ApiUrls.resendOtp,
      {
        "email": email,
      },
    );

    final data = jsonDecode(response.body);

    return data;
  }

}