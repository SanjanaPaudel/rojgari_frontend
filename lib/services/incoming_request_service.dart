import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/incoming_request_model.dart';
import '../models/technician/incoming_service_request_details.dart';
import 'api_service.dart';

/// Thrown by [IncomingRequestService.acceptRequest] / [rejectRequest] on a
/// non-2xx response. Carries the HTTP status code alongside the backend's
/// message so callers can tell a permanent conflict (409 — the offer already
/// expired or was taken by another worker) apart from a transient failure
/// worth retrying.
class IncomingRequestActionException implements Exception {
  const IncomingRequestActionException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Fetches the pending booking offers addressed to the logged-in worker.
///
/// Goes through [ApiService] so the request inherits the shared JWT
/// expiry check, refresh-on-401 retry, and auto-logout behaviour.
class IncomingRequestService {
  IncomingRequestService() : _api = ApiService();

  final ApiService _api;

  /// GET /api/auth/worker/incoming-requests/
  ///
  /// Response: `{ "count": <int>, "requests": [ ... ] }`
  ///
  /// Throws an [Exception] with a human-readable message on network errors,
  /// unexpected HTTP status codes, or JSON parsing failures. The backend
  /// returns 403 with a `detail` message when the user is not a worker.
  Future<List<IncomingRequest>> fetchIncomingRequests() async {
    try {
      final response = await _api.get(ApiUrls.workerIncomingRequests);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final requests = body['requests'] as List<dynamic>? ?? const [];

        return requests
            .map(
              (item) => IncomingRequest.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      // Surface server-side error messages when available.
      String detail = 'Failed to load requests (HTTP ${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['detail'] != null) {
          detail = body['detail'].toString();
        }
      } catch (_) {
        // Body is not JSON — keep the generic message.
      }
      throw Exception(detail);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// GET /api/auth/worker/request/[offerId]/
  ///
  /// [offerId] is the BookingOffer id. Returns 404 when the offer does not
  /// exist or belongs to another worker.
  Future<IncomingServiceRequestDetails> fetchRequestDetail(
    String offerId,
  ) async {
    try {
      final response = await _api.get(ApiUrls.workerRequestDetail(offerId));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return IncomingServiceRequestDetails.fromJson(body);
      }

      throw Exception(
        _messageFor(response.body, 'Failed to load request (HTTP ${response.statusCode})'),
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// POST /api/auth/worker/request/[offerId]/accept/
  ///
  /// Takes no body. On success the backend marks the booking scheduled and
  /// cancels every other pending offer for it.
  ///
  /// Returns the backend `message` string.
  Future<String> acceptRequest(String offerId) async {
    try {
      final response = await _api.post(
        ApiUrls.workerAcceptRequest(offerId),
        const {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? 'Request accepted successfully.';
      }

      throw IncomingRequestActionException(
        statusCode: response.statusCode,
        message: _messageFor(
          response.body,
          'Failed to accept request (HTTP ${response.statusCode})',
        ),
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// POST /api/auth/worker/request/[offerId]/reject/
  ///
  /// Takes no body. On success the backend marks the offer rejected.
  ///
  /// Returns the backend `message` string.
  Future<String> rejectRequest(String offerId) async {
    try {
      final response = await _api.post(
        ApiUrls.workerRejectRequest(offerId),
        const {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? 'Request rejected successfully.';
      }

      throw IncomingRequestActionException(
        statusCode: response.statusCode,
        message: _messageFor(
          response.body,
          'Failed to reject request (HTTP ${response.statusCode})',
        ),
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Pulls the backend's `detail` message out of an error body, falling back
  /// to [fallback] when the body is not JSON or carries no message.
  String _messageFor(String body, String fallback) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final detail = decoded['detail'] ?? decoded['message'];
      if (detail != null) return detail.toString();
    } catch (_) {
      // Body is not JSON — keep the generic message.
    }
    return fallback;
  }
}
