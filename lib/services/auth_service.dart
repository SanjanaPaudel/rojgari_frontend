import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/api_urls.dart';
import '../models/auth_session.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    StorageService? storage,
    ApiService? apiService,
    Uri? loginEndpoint,
    Uri? refreshEndpoint,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? StorageService(),
       _apiService = apiService ?? ApiService(),
       _loginEndpoint = loginEndpoint ?? Uri.parse(ApiUrls.login),
       _refreshEndpoint = refreshEndpoint ?? Uri.parse(ApiUrls.refresh);

  final http.Client _client;
  final StorageService _storage;
  final ApiService _apiService;
  final Uri _loginEndpoint;
  final Uri _refreshEndpoint;

  Future<AuthSession> login({
    required String phoneNumber,
    required String password,
  }) async {
    final normalizedPhone = _normalizeNepalPhone(phoneNumber);
    final response = await _client.post(
      _loginEndpoint,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone_number': normalizedPhone, 'password': password}),
    );
    final decoded = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _readError(decoded) ??
            (response.statusCode == 401
                ? 'Incorrect phone number or password.'
                : 'Unable to sign in. Please try again.'),
        statusCode: response.statusCode,
      );
    }
    try {
      final session = AuthSession.fromJson(decoded);
      await _storage.saveAccessToken(session.accessToken);
      await _storage.saveRefreshToken(session.refreshToken);
      return session;
    } on FormatException {
      throw const AuthException('The login response is incomplete.');
    }
  }

  Future<String> refreshAccessToken() async {
    final refreshToken = (await _storage.getRefreshToken())?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    final response = await _client.post(
      _refreshEndpoint,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'refresh': refreshToken}),
    );
    final decoded = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _readError(decoded) ??
            'Your session has expired. Please sign in again.',
        statusCode: response.statusCode,
      );
    }
    final accessToken = decoded['access']?.toString().trim() ?? '';
    if (accessToken.isEmpty) {
      throw const AuthException('The token refresh response is incomplete.');
    }
    await _storage.saveAccessToken(accessToken);
    return accessToken;
  }

  Future<Map<String, dynamic>> signup({
    required String role,
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    File? profilePhoto,
  }) async {
    return _apiService.multipartPost(
      url: ApiUrls.signup,
      fields: {
        'role': role,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
      image: profilePhoto,
    );
  }

  String _normalizeNepalPhone(String value) {
    final phone = value.trim().replaceAll(' ', '');
    return phone.startsWith('+') ? phone : '+977$phone';
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String? _readError(Map<String, dynamic> response) {
    for (final key in const ['detail', 'message', 'non_field_errors']) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List && value.isNotEmpty) {
        final first = value.first?.toString().trim();
        if (first != null && first.isNotEmpty) return first;
      }
    }
    return null;
  }
}
