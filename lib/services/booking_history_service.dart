import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/customer/booking_history_item.dart';
import 'api_service.dart';

class BookingHistoryException implements Exception {
  const BookingHistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches the logged-in customer's full booking history.
///
/// Built on [ApiService] (not a raw http.Client) so this call inherits the
/// app's existing JWT-refresh-on-401 and forced-logout-on-expired-session
/// behavior for free, same as every other authenticated endpoint.
class BookingHistoryService {
  BookingHistoryService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<List<BookingHistoryItem>> fetchHistory() async {
    final response = await _api.get(ApiUrls.bookingHistory);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(BookingHistoryItem.fromApi)
            .toList();
      }
      throw const BookingHistoryException(
        'Unexpected response while loading your bookings.',
      );
    }

    throw BookingHistoryException(
      'Unable to load your bookings (${response.statusCode}).',
    );
  }
}
