import 'dart:convert';

import '../../core/constants/api_urls.dart';
import '../../models/service_request/booking_status_response.dart';
import '../api_service.dart';

class BookingStatusException implements Exception {
  const BookingStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown on HTTP 404 — the booking doesn't exist, or doesn't belong to the
/// requesting customer. Kept distinct from [BookingStatusException] so a
/// poller can treat this as terminal (stop polling) rather than a transient
/// failure worth retrying.
class BookingNotFoundException extends BookingStatusException {
  const BookingNotFoundException()
    : super('This service request could not be found.');
}

/// Fetches booking-assignment status for the "Finding Service Person" screen.
///
/// Built on [ApiService] (not a raw http.Client) so this call inherits the
/// app's existing JWT-refresh-on-401 and forced-logout-on-expired-session
/// behavior for free, same as every other authenticated endpoint.
class BookingStatusService {
  BookingStatusService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<BookingStatusResponse> fetchStatus(String bookingId) async {
    final response = await _api.get(ApiUrls.bookingStatus(bookingId));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return BookingStatusResponse.fromJson(decoded);
      }
      throw const BookingStatusException(
        'Unexpected response while checking the request status.',
      );
    }

    if (response.statusCode == 404) {
      throw const BookingNotFoundException();
    }

    throw BookingStatusException(
      'Unable to check the request status (${response.statusCode}).',
    );
  }

  /// POST /api/services/bookings/arrived — tells the backend the worker has
  /// physically reached the customer's location. Returns once the backend
  /// confirms with `{ "status": "arrived" }`; throws otherwise so the caller
  /// never flips the UI to "Arrived" on anything less than a confirmed
  /// success response.
  Future<void> markWorkerArrived() async {
    final response = await _api.post(ApiUrls.bookingArrived, const {
      'status': 'arrived',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['status'] == 'arrived') {
        return;
      }
      throw const BookingStatusException(
        'Unexpected response while confirming arrival.',
      );
    }

    throw BookingStatusException(
      'Unable to confirm arrival (${response.statusCode}).',
    );
  }
}
