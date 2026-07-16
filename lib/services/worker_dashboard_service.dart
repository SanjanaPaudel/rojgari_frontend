import 'dart:convert';
import 'dart:typed_data';

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

  /// Sends a PUT request to /api/auth/worker/profile/ to update the worker's
  /// editable profile fields.
  ///
  /// Returns the backend [message] string on success
  /// (e.g. "Profile updated successfully.").
  ///
  /// Throws an [Exception] on network failure or a non-200 response.
  Future<String> updateProfile({
    required String fullName,
    required String email,
    required String about,
    required String serviceArea,
  }) async {
    try {
      final response = await _api.put(
        ApiUrls.workerProfile,
        {
          "full_name": fullName,
          "email": email,
          "about": about,
          "service_area": serviceArea,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? 'Profile updated successfully.';
      }

      // Surface the backend error message when available.
      String detail =
          'Failed to update profile (HTTP ${response.statusCode})';
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

  // ────────────────────────────────────────────────────────────────────────────
  // uploadProfilePhoto
  // ────────────────────────────────────────────────────────────────────────────
  //
  // Uploads the worker's profile photo to the backend via multipart/form-data.
  //
  // HTTP METHOD : POST
  // ENDPOINT    : /api/auth/worker/profile-photo/
  // CONTENT-TYPE: multipart/form-data
  // FIELD NAME  : "profile_photo"  →  the image file
  //
  // SUCCESS RESPONSE (HTTP 200):
  // {
  //   "message"      : "Profile photo uploaded successfully.",
  //   "profile_photo": "http://127.0.0.1:8000/media/profile_photos/worker.jpg"
  // }
  //
  // The returned "profile_photo" value is the canonical, server-side absolute
  // URL.  The caller should store this URL in the model so the app always
  // displays the persisted server copy, not a stale local path/bytes.
  //
  // Parameters:
  //   [imageBytes] – Raw bytes of the chosen image (from XFile.readAsBytes()).
  //   [imageName]  – Original filename string (e.g. "photo.jpg") used as the
  //                  multipart filename header.  The backend may use this to
  //                  derive the stored filename.
  //
  // Throws an [Exception] with a human-readable message on:
  //   • Network failure
  //   • Non-200 HTTP status
  //   • Missing or empty "profile_photo" key in the response
  // ────────────────────────────────────────────────────────────────────────────
  Future<String> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      // ApiService.multipartPost() builds a multipart/form-data request.
      // It deliberately does NOT call _getHeaders() so that the http package
      // can set:  Content-Type: multipart/form-data; boundary=<auto>
      // without it being overridden by Content-Type: application/json.
      //
      // Wire format sent to the server:
      //   POST /api/auth/worker/profile-photo/
      //   Authorization: Bearer <access_token>
      //   Content-Type: multipart/form-data; boundary=<auto>
      //
      //   --<boundary>
      //   Content-Disposition: form-data; name="profile_photo"; filename="<imageName>"
      //   Content-Type: image/jpeg   ← inferred from file extension
      //
      //   <raw binary image bytes>   ← Django reads this from request.FILES
      //   --<boundary>--
      //
      // Django/DRF reads the file from request.FILES["profile_photo"].
      // Pillow then validates/processes the raw bytes — it does NOT rely on
      // Content-Type: application/json at any point.
      final streamed = await _api.multipartPost(
        ApiUrls.workerProfilePhoto,
        {}, // No extra text fields — only the image file is required
        imageBytes,
        imageName,
        fieldName: 'profile_photo', // matches request.FILES key on the server
      );

      // StreamedResponse must be read to bytes before the connection closes.
      final bodyString = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final body = jsonDecode(bodyString) as Map<String, dynamic>;

        // Extract the canonical photo URL returned by the server.
        final photoUrl = body['profile_photo']?.toString();
        if (photoUrl == null || photoUrl.isEmpty) {
          throw Exception('Server returned an empty profile photo URL.');
        }
        return photoUrl; // e.g. "http://127.0.0.1:8000/media/profile_photos/worker.jpg"
      }

      // Surface the backend error message when available.
      String detail =
          'Failed to upload profile photo (HTTP ${streamed.statusCode})';
      try {
        final body = jsonDecode(bodyString) as Map<String, dynamic>;
        if (body['detail'] != null) detail = body['detail'].toString();
        if (body['message'] != null) detail = body['message'].toString();
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
