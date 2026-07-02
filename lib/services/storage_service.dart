//Stores
//
// access token
// refresh token
//
// using flutter_secure_storage.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Save Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // Save Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  // Get Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Get Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  // Delete All Tokens
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}