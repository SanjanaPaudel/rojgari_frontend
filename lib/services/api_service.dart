//Only responsible for making HTTP requests and delivery.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/services/navigation_service.dart';
import 'package:rojgari_frontend_one/services/storage_service.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
import '../core/constants/api_urls.dart';

class ApiService {
  static const String sessionExpired = "Session Expired. Please login again.";

  // Concurrency control for token refreshing
  Future<bool>? _refreshFuture;

  Future<String?> _getValidAccessToken() async {
    final String? token = await StorageService.getAccessToken();

    if (token == null) {
      return null;
    }

    // Check expiration locally before proceeding
    if (_isTokenExpired(token)) {
      final refreshed = await _handleTokenRefresh();
      if (refreshed) {
        return await StorageService.getAccessToken();
      }
      return null;
    }

    return token;
  }

  Future<bool> checkAndRefreshSession() async {
    final String? token = await StorageService.getAccessToken();

    if (token == null) {
      return false;
    }

    if (_isTokenExpired(token)) {
      return await _handleTokenRefresh();
    }

    return true;
  }

  Future<Map<String, String>> _getHeaders([String? token]) async {
    final activeToken = token ?? await _getValidAccessToken();

    return {
      "Content-Type": "application/json",
      if (activeToken != null) "Authorization": "Bearer $activeToken",
    };
  }

  Future<void> _logoutUser() async {
    await StorageService.clearTokens();
    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    throw Exception(ApiService.sessionExpired);
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> get(String url) async {
    http.Response response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 401) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
    }
    return response;
  }

  //=====================
  // MULTIPART POST
  //=====================
  Future<http.StreamedResponse> multipartPost(
    String url,
    Map<String, String> fields,
    File? image,
  ) async {
    http.MultipartRequest request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    final token = await _getValidAccessToken();

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(fields);

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile_photo",
          image.path,
        ),
      );
    }

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _handleTokenRefresh();

      if (!refreshed) {
        await _logoutUser();
      }

      // MultipartRequest cannot be reused.
      request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      final newToken = await _getValidAccessToken();

      if (newToken != null) {
        request.headers["Authorization"] = "Bearer $newToken";
      }

      request.fields.addAll(fields);

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "profile_photo",
            image.path,
          ),
        );
      }

      response = await request.send();
    }

    return response;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // The payload is the second block of the token
      String payload = parts[1];

      // Standardize base64 url padding requirements
      int padding = 4 - (payload.length % 4);
      if (padding > 0 && padding < 4) {
        payload += '=' * padding;
      }

      final decodedString = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> jsonClaims = jsonDecode(decodedString);

      if (jsonClaims.containsKey('exp')) {
        final expTimeSeconds = jsonClaims['exp'] as int;
        final currentTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Add a 10-second buffer to handle slight clock skew issues
        return currentTimeSeconds >= (expTimeSeconds - 10);
      }
      return true;
    } catch (_) {
      return true; // Fallback to expired if parsing fails
    }
  }

  // Mutex wrapper to prevent redundant/simultaneous token refresh operations
  Future<bool> _handleTokenRefresh() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    _refreshFuture = _refreshAccessToken();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await StorageService.getRefreshToken();

    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiUrls.refresh),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "refresh": refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await StorageService.saveAccessToken(
          data["access"],
        );

        return true;
      }
    } catch (_) {
      // Catch socket exceptions or request abort errors
    }

    await StorageService.clearTokens();
    return false;
  }
}
