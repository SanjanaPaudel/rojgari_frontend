import 'dart:convert';

import '../../core/constants/api_urls.dart';
import '../../models/chat/chat_message.dart';
import '../api_service.dart';

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads a booking's chat history over REST.
///
/// Only the one-time history fetch lives here — the live send/receive side
/// rides the booking WebSocket (see AppWebSocket + ApiUrls.bookingSocket) and
/// is driven directly by the chat screen, mirroring how the tracking screen
/// manages its own socket. Built on [ApiService] so it inherits the app's
/// JWT-refresh-on-401 / forced-logout-on-expiry behavior for free.
class BookingChatService {
  BookingChatService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  /// Fetches the most recent messages for [bookingId], oldest first. Throws
  /// [ChatException] on any non-200 so the screen can show a retry state.
  Future<List<ChatMessage>> fetchHistory(String bookingId) async {
    final response = await _api.get(ApiUrls.bookingMessages(bookingId));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromRest)
            .toList();
      }
      throw const ChatException('Unexpected response while loading messages.');
    }

    if (response.statusCode == 404 || response.statusCode == 403) {
      throw const ChatException('This conversation could not be found.');
    }

    throw ChatException('Unable to load messages (${response.statusCode}).');
  }
}
