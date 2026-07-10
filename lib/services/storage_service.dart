//Stores
//
// access token
// refresh token
//
// using flutter_secure_storage.

//Why Store the Token?
//Imagine the user closes the app.
//Tomorrow they reopen it.
//The app reads
// _storage.read(key:"access_token")
// If token exists
// No need to login again.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Save Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // Save Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  // Save next screen
  static Future<void> saveNextScreen(String next_screen) async {
    await _storage.write(key: 'next_screen', value: next_screen);
  }

  // Get Access Token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Get Refresh Token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  // Get next screen
  static Future<String?> getNextScreen() async {
    return await _storage.read(key: 'next_screen');
  }

  // Delete All Tokens
  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}