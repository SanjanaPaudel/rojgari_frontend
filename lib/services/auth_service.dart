// Responsible for authentication.

// import 'package:dio/dio.dart';
//
// import '../core/constants/api_urls.dart';
// import 'api_service.dart';
// import 'storage_service.dart';
//
// class AuthService {
//   final StorageService _storage = StorageService();
//
//   Future<bool> login({
//     required String phoneNumber,
//     required String password,
//   }) async {
//     try {
//       final response = await ApiService.dio.post(
//         ApiUrls.login,
//         data: {
//           "phone_number": phoneNumber,
//           "password": password,
//         },
//       );
//
//       await _storage.saveAccessToken(response.data["access"]);
//       await _storage.saveRefreshToken(response.data["refresh"]);
//
//       return true;
//     } on DioException catch (e) {
//       print("Login Error: ${e.response?.data}");
//       return false;
//     }
//   }
// }

import 'dart:io';

import '../core/constants/api_urls.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> signup({
    required String role,
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    File? profilePhoto,
  }) async {
    return await _apiService.multipartPost(
      url: ApiUrls.signup,
      fields: {
        "role": role,
        "full_name": fullName,
        "phone_number": phoneNumber,
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
      },
      image: profilePhoto,
    );
  }
}