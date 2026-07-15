import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/worker_dashboard_response.dart';
import 'api_service.dart';

/// Fetches the authenticated worker's dashboard data from the backend.
class WorkerDashboardService {
  WorkerDashboardService() : _api = ApiService();

  final ApiService _api;

  /// Fetches dashboard data for the currently logged-in worker.
  ///
  /// Throws an [Exception] with a human-readable message on network errors,
  /// unexpected HTTP status codes, or JSON parsing failures.
  Future<WorkerDashboardResponse> fetchDashboard() async {
    try {
      final response = await _api.get(ApiUrls.workerDashboard);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return WorkerDashboardResponse.fromJson(json);
      }

      // Surface server-side error messages when available.
      String detail = 'Failed to load dashboard (HTTP ${response.statusCode})';
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

  /// Sends a PATCH request to /worker/status/ to update the worker's
  /// online/offline status.
  ///
  /// Returns the backend [message] string on success
  /// (e.g. "You are now offline." or "You are now online.").
  ///
  /// Throws an [Exception] on network failure or a non-200 response.
  Future<String> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _api.patch(
        ApiUrls.workerStatus,
        {"is_online": isOnline}, // Sends {"is_online": true} or {"is_online": false}
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? 'Status updated.';
      }

      // Surface the backend error message when available.
      String detail = 'Failed to update status (HTTP ${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['detail'] != null) detail = body['detail'].toString();
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
