
import 'dart:io';

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

}