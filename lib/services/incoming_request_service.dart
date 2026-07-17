import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/incoming_request_model.dart';
import 'api_service.dart';

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
}
