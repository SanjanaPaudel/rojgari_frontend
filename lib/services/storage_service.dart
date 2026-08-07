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
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _viewedOfferIdsKey = 'viewed_offer_ids';

  // BACKEND LOGIN TODO:
  // After a successful real login, persist the returned access token with:
  // await StorageService().saveAccessToken(accessToken);
  // ApiServiceRequestRepository reads this same token for its Bearer header.
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

  // Returns the logged-in user's id, decoded from the stored JWT access
  // token's "user_id" claim — the same claim the backend's WebSocket auth
  // reads to identify the connected user. The chat screen uses this to tell
  // which messages are the current user's own (align them right vs left),
  // without needing a separate "who am I" endpoint. Returns null if there's
  // no token or the payload can't be parsed. Mirrors the base64url payload
  // decoding ApiService._isTokenExpired already does.
  static Future<int?> getCurrentUserId() async {
    final token = await getAccessToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      final padding = 4 - (payload.length % 4);
      if (padding > 0 && padding < 4) {
        payload += '=' * padding;
      }

      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (decoded is Map<String, dynamic>) {
        final id = decoded['user_id'];
        return id is int ? id : int.tryParse('$id');
      }
    } catch (_) {
      // Malformed token — treat as unknown user.
    }
    return null;
  }

  // Get next screen
  static Future<String?> getNextScreen() async {
    return await _storage.read(key: 'next_screen');
  }

  // Delete All Tokens
  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'next_screen');
  }

  // Save the full set of incoming-request offer IDs the worker has opened,
  // so "Viewed" status survives an app restart on this device. See
  // IncomingRequestsStore for how this gets used.
  static Future<void> saveViewedOfferIds(Set<String> ids) async {
    await _storage.write(
      key: _viewedOfferIdsKey,
      value: jsonEncode(ids.toList()),
    );
  }

  // Get the saved set of viewed offer IDs, or an empty set if none saved yet
  // (first run, or the saved value is missing/corrupted).
  static Future<Set<String>> getViewedOfferIds() async {
    final raw = await _storage.read(key: _viewedOfferIdsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }
}
