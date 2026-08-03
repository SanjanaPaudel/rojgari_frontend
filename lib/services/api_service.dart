//Only responsible for making HTTP requests and delivery.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/services/navigation_service.dart';
import 'package:rojgari_frontend_one/services/storage_service.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
import '../core/constants/api_urls.dart';
import 'fcm_service.dart';

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
    FcmService.resetSession();
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

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
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

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
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

  Future<http.Response> patch(
    String url,
    Map<String, dynamic> body,
  ) async {
    http.Response response = await http.patch(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    http.Response response = await http.put(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    }
    return response;
  }

  // Sends a multipart/form-data POST request.
  //
  // WHY this method does NOT call _getHeaders():
  //   _getHeaders() adds "Content-Type: application/json", which would
  //   override the boundary that http.MultipartRequest sets automatically.
  //   Only the Authorization header is added manually here.
  //
  // The http package sets:
  //   Content-Type: multipart/form-data; boundary=<auto>
  // on the outer request automatically when you call request.send().
  //
  // Parameters:
  //   [fieldName]  – The multipart field name the server expects
  //                  (e.g. "profile_photo").  Passed in by the caller so
  //                  this method stays generic and reusable.
  //   [fields]     – Additional plain-text form fields (can be empty map).
  //   [imageBytes] – Raw image bytes read from XFile.readAsBytes().
  //   [imageName]  – Original filename (e.g. "IMG_1234.jpg") used as the
  //                  Content-Disposition filename parameter in the part
  //                  header.  Also used to infer the MIME type.
  Future<http.StreamedResponse> multipartPost(
    String url,
    Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageName, {
    String fieldName = 'photo', // field name the server reads from request.FILES
    String method = 'POST', // some endpoints (e.g. customer profile photo) expect PATCH
  }) async {
    // Infer MIME type from the file extension so the part header is correct.
    // Pillow validates image bytes directly, but a correct Content-Type header
    // is good practice and avoids surprises with strict server configurations.
    http.MediaType _mimeType(String? name) {
      final ext = (name ?? '').split('.').last.toLowerCase();
      return switch (ext) {
        'png'  => http.MediaType('image', 'png'),
        'webp' => http.MediaType('image', 'webp'),
        'gif'  => http.MediaType('image', 'gif'),
        _      => http.MediaType('image', 'jpeg'), // default — covers jpg/jpeg
      };
    }

    http.MultipartRequest request = http.MultipartRequest(
      method,
      Uri.parse(url),
    );

    final token = await _getValidAccessToken();
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(fields);

    if (imageBytes != null) {
      // fromBytes() is synchronous and works on Flutter Web + Android/iOS.
      // We pass contentType so the multipart part header reads:
      //   Content-Type: image/jpeg  (or png/webp/gif)
      // instead of the default application/octet-stream.
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          imageBytes,
          filename: imageName ?? '$fieldName.jpg',
          contentType: _mimeType(imageName),
        ),
      );
    }

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) await _logoutUser();

      // MultipartRequest cannot be reused after send() — rebuild it.
      request = http.MultipartRequest(method, Uri.parse(url));

      final newToken = await _getValidAccessToken();
      if (newToken != null) {
        request.headers["Authorization"] = "Bearer $newToken";
      }

      request.fields.addAll(fields);

      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            imageBytes,
            filename: imageName ?? '$fieldName.jpg',
            contentType: _mimeType(imageName),
          ),
        );
      }

      response = await request.send();
    }

    return response;
  }

  // Sends a multipart/form-data POST request with multiple named file fields.
  //
  // WHY a separate method instead of extending multipartPost:
  //   The identity-document upload requires three distinct field names
  //   (citizenship_front, citizenship_back, experience_document) in a single
  //   request.  multipartPost is designed for exactly one file field and is
  //   kept unchanged so the profile-photo upload is not affected.
  //
  // Parameters:
  //   [fields]     – Additional plain-text form fields (can be empty map).
  //   [fileFields] – List of named file entries, each carrying:
  //                    fieldName – multipart field name the server reads from
  //                                request.FILES (e.g. "citizenship_front")
  //                    bytes     – raw file bytes (from XFile.readAsBytes())
  //                    filename  – original filename for Content-Disposition
  //
  // The MIME type of each file is inferred from the filename extension.
  // Authorization header is added automatically via _getValidAccessToken().
  // On a 401 the token is refreshed and the full request is rebuilt + resent
  // (MultipartRequest cannot be reused after send()).
  Future<http.StreamedResponse> multipartPostFiles(
    String url,
    Map<String, String> fields,
    List<({String fieldName, Uint8List bytes, String filename})> fileFields,
  ) async {
    http.MediaType _mimeType(String name) {
      final ext = name.split('.').last.toLowerCase();
      return switch (ext) {
        'png'  => http.MediaType('image', 'png'),
        'webp' => http.MediaType('image', 'webp'),
        'gif'  => http.MediaType('image', 'gif'),
        _      => http.MediaType('image', 'jpeg'),
      };
    }

    // Builds a fresh MultipartRequest with all file parts attached.
    // Must be called again on 401-retry because a sent request cannot be reused.
    List<http.MultipartFile> buildFileParts() => [
      for (final f in fileFields)
        http.MultipartFile.fromBytes(
          f.fieldName,
          f.bytes,
          filename: f.filename,
          contentType: _mimeType(f.filename),
        ),
    ];

    http.MultipartRequest request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    final token = await _getValidAccessToken();
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(fields);
    request.files.addAll(buildFileParts());

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(url)) {
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) await _logoutUser();

      // Rebuild the request — MultipartRequest cannot be reused after send().
      request = http.MultipartRequest("POST", Uri.parse(url));
      final newToken = await _getValidAccessToken();
      if (newToken != null) {
        request.headers["Authorization"] = "Bearer $newToken";
      }
      request.fields.addAll(fields);
      request.files.addAll(buildFileParts());

      response = await request.send();
    }

    return response;
  }

  bool _isPublicAuthEndpoint(String url) {
    return url == ApiUrls.login ||
        url == ApiUrls.signup ||
        url == ApiUrls.verifyOtp ||
        url == ApiUrls.resendOtp;
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
