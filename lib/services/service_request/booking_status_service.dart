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

  /// Cancels a booking. Returns normally on success; throws on failure so
  /// callers can distinguish "backend rejected it" from a raw network error
  /// only by the message, same as [fetchStatus].
  Future<void> cancelBooking(String bookingId) async {
    final response = await _api.post(ApiUrls.cancelBooking(bookingId), {});

    if (response.statusCode == 200) return;

    if (response.statusCode == 404) {
      throw const BookingNotFoundException();
    }

    if (response.statusCode == 400) {
      final decoded = jsonDecode(response.body);
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail'] as String?
          : null;
      throw BookingStatusException(
        detail ?? 'This request can no longer be cancelled.',
      );
    }

    throw BookingStatusException(
      'Unable to cancel the request (${response.statusCode}).',
    );
  }

  /// Submits the customer's rating (and optional review) for a completed
  /// booking. [rating] must be 1-5 — the UI already enforces this via its
  /// star picker, so this only guards against a caller bypassing that.
  Future<BookingStatusResponse> rateBooking(
    String bookingId, {
    required int rating,
    String? reviewText,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const BookingStatusException('Rating must be between 1 and 5.');
    }

    final response = await _api.post(ApiUrls.rateBooking(bookingId), {
      'rating': rating,
      if (reviewText != null && reviewText.isNotEmpty)
        'review_text': reviewText,
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return BookingStatusResponse.fromJson(decoded);
      }
      throw const BookingStatusException(
        'Unexpected response while submitting your review.',
      );
    }

    if (response.statusCode == 404) {
      throw const BookingNotFoundException();
    }

    if (response.statusCode == 400) {
      final decoded = jsonDecode(response.body);
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail'] as String?
          : null;
      throw BookingStatusException(
        detail ?? 'Unable to submit your review.',
      );
    }

    throw BookingStatusException(
      'Unable to submit your review (${response.statusCode}).',
    );
  }
}
