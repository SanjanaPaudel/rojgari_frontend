import 'dart:convert';
import 'dart:typed_data';

import '../core/constants/api_urls.dart';
import '../models/customer_profile_model.dart';
import 'api_service.dart';

/// Fetches the authenticated customer's profile data from the backend.
class CustomerProfileService {
  CustomerProfileService() : _api = ApiService();

  final ApiService _api;

  /// Fetches the currently logged-in customer's profile.
  ///
  /// Throws an [Exception] with a human-readable message on network errors,
  /// unexpected HTTP status codes, or JSON parsing failures.
  Future<CustomerProfileModel> getProfile() async {
    try {
      final response = await _api.get(ApiUrls.customerProfile);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return CustomerProfileModel.fromJson(json);
      }

      String detail = 'Failed to load profile (HTTP ${response.statusCode})';
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

  /// Updates the currently logged-in customer's full name and/or phone
  /// number. Pass only the field(s) that changed — the backend leaves any
  /// omitted/null field untouched.
  ///
  /// Note: the backend does not support updating email through this
  /// endpoint, so there's no [email] parameter here — the returned model's
  /// email always reflects the server's existing value.
  ///
  /// Throws an [Exception] with a human-readable message on network errors,
  /// unexpected HTTP status codes, or JSON parsing failures.
  Future<CustomerProfileModel> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _api.patch(ApiUrls.customerProfileUpdate, {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> customer =
            body['customer'] as Map<String, dynamic>;
        return CustomerProfileModel.fromJson(customer);
      }

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

  /// Uploads the currently logged-in customer's profile photo.
  ///
  /// Returns the backend's raw `profile_photo` value (may be relative —
  /// resolve with [ApiUrls.resolveMediaUrl] before displaying), or `null` if
  /// the response didn't include one.
  ///
  /// Throws an [Exception] with a human-readable message on network errors,
  /// unexpected HTTP status codes, or JSON parsing failures.
  Future<String?> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      final streamed = await _api.multipartPost(
        ApiUrls.customerProfilePhoto,
        {},
        imageBytes,
        imageName,
        fieldName: 'profile_photo',
        method: 'PATCH',
      );

      final bodyString = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(bodyString) as Map<String, dynamic>;
        return body['profile_photo']?.toString();
      }

      String detail =
          'Failed to upload profile photo (HTTP ${streamed.statusCode})';
      try {
        final body = jsonDecode(bodyString) as Map<String, dynamic>;
        if (body['error'] != null) detail = body['error'].toString();
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
