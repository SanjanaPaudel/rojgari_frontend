import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_urls.dart';
import '../../models/service_request/service_request_payload.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'service_request_repository.dart';

class ServiceRequestMultipartFields {
  const ServiceRequestMultipartFields._();

  static const String categoryId = 'category_id';
  static const String description = 'description';
  static const String scheduleType = 'schedule_type';
  static const String scheduledTime = 'scheduled_time';
  static const String timezone = 'timezone';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String accuracyMeters = 'accuracy_meters';
  static const String landmark = 'landmark';
  static const String locationSource = 'location_source';
  static const String photos = 'photos';
  static const String video = 'video';
}

class ServiceRequestApiConfig {
  const ServiceRequestApiConfig._();

  static const String timezone = 'Asia/Kathmandu';
}

class ApiServiceRequestRepository implements ServiceRequestRepository {
  ApiServiceRequestRepository({
    http.Client? client,
    Uri? endpoint,
    Future<String?> Function()? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? Uri.parse(ApiUrls.serviceRequests),
       _accessTokenProvider =
           accessTokenProvider ?? StorageService.getAccessToken;

  final http.Client _client;
  final Uri _endpoint;
  final Future<String?> Function() _accessTokenProvider;

  // ========================================================================
  // BACKEND HANDOFF: REAL MULTIPART SERVICE REQUEST API
  // ========================================================================
  //
  // PURPOSE
  // This repository method is the only place where the completed Flutter
  // Request Page connects to the real service-request backend. Do not move
  // HTTP code into the Request Page or redesign the completed UI.
  //
  // ------------------------------------------------------------------------
  // CURRENT FRONTEND STATUS
  // ------------------------------------------------------------------------
  // The application currently uses MockServiceRequestRepository. The frontend
  // already collects the category, description, up to three photos, one
  // optional video, raw OpenStreetMap coordinates, optional GPS accuracy,
  // optional landmark, and either service now or later today. Selected media
  // is attached as real bytes. The backend remains responsible for trusted
  // reverse geocoding even if the location UI has an optional display hint.
  //
  // ------------------------------------------------------------------------
  // FINAL API ENDPOINT
  // ------------------------------------------------------------------------
  // Method: POST
  // Suggested endpoint: /api/customer/service-requests/
  // Keep the base URL in API_BASE_URL. Never hardcode localhost or a computer
  // LAN IP here. Confirm or replace only ApiUrls.serviceRequests.
  //
  // ------------------------------------------------------------------------
  // AUTHENTICATION
  // ------------------------------------------------------------------------
  // Read the access token from the existing StorageService and add:
  // Authorization: Bearer <access_token>
  // Accept: application/json
  //
  // The real login implementation must save the backend token with:
  // await StorageService().saveAccessToken(accessToken);
  // Do not create another secure-storage or authentication system.
  //
  // ------------------------------------------------------------------------
  // MULTIPART TEXT FIELDS
  // ------------------------------------------------------------------------
  // category_id
  // description
  // schedule_type
  // scheduled_time
  // timezone
  // latitude
  // longitude
  // accuracy_meters
  // landmark
  // location_source
  //
  // schedule_type supports exactly: now, later_today.
  // For "now", scheduled_time is omitted.
  // For "later_today", scheduled_time is HH:mm:ss and must be later today.
  // No date field is sent. The backend interprets the time using the supplied
  // timezone, currently Asia/Kathmandu.
  //
  // Do not send preferredDate, preferredTime, scheduleForLater, or
  // formatted_address.
  //
  // ------------------------------------------------------------------------
  // MULTIPART MEDIA FIELDS
  // ------------------------------------------------------------------------
  // Multiple image files: photos
  // Optional single video: video
  //
  // Add each selected photo using repeated field name "photos". Do not use
  // photos[], photos[0], or photos[1]. Local paths only locate files; never
  // send a local path as text or JSON.
  //
  // ------------------------------------------------------------------------
  // LOCATION RESPONSIBILITY
  // ------------------------------------------------------------------------
  // Flutter sends latitude, longitude, optional accuracy_meters, optional
  // landmark, and location_source. The backend must validate coordinates,
  // perform reverse geocoding, produce formatted_address, store both raw and
  // resolved locations, check the service area, and use coordinates for
  // matching and distance calculations.
  //
  // ------------------------------------------------------------------------
  // EXPECTED SUCCESS RESPONSE (HTTP 201)
  // ------------------------------------------------------------------------
  // {
  //   "success": true,
  //   "message": "Service request created successfully.",
  //   "data": {
  //     "request_id": "req_123",
  //     "status": "searching",
  //     "category_id": "mechanic",
  //     "schedule_type": "later_today",
  //     "scheduled_time": "20:30:00",
  //     "created_at": "2026-07-15T15:45:00+05:45",
  //     "service_location": {
  //       "latitude": 27.671234,
  //       "longitude": 85.339876,
  //       "formatted_address": "Balkumari Road, Lalitpur",
  //       "landmark": "Near NCIT College"
  //     }
  //   }
  // }
  // Parse this into ServiceRequestResult. Adjust only repository parsing for
  // a documented backend variation.
  //
  // ------------------------------------------------------------------------
  // EXPECTED ERROR RESPONSE
  // ------------------------------------------------------------------------
  // {
  //   "success": false,
  //   "code": "VALIDATION_ERROR",
  //   "message": "Please correct the submitted information.",
  //   "errors": {
  //     "scheduled_time": [
  //       "Scheduled time must be later than the current time."
  //     ]
  //   }
  // }
  // Convert errors into readable ServiceRequestException values. Never expose
  // raw server exceptions or HTML in the UI.
  //
  // ------------------------------------------------------------------------
  // BACKEND DEVELOPER CHECKLIST
  // ------------------------------------------------------------------------
  // 1. Confirm the endpoint in api_urls.dart.
  // 2. Implement or confirm the backend POST endpoint.
  // 3. Confirm repeated photo field "photos" and optional video field "video".
  // 4. Confirm accepted media types and maximum file sizes.
  // 5. Confirm success and standard error response structures.
  // 6. Confirm login returns an access token and save it via StorageService.
  // 7. Switch the provider from mock to API only after end-to-end testing.
  //
  // Do not change the Request Page UI during backend integration.
  // ========================================================================
  @override
  Future<ServiceRequestResult> createServiceRequest(
    ServiceRequestPayload payload,
  ) async {
    _validatePayload(payload);
    
    // Proactively check and refresh session before making request, skipping under unit tests to prevent secure storage channel crashes
    final isUnderTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isUnderTest) {
      await ApiService().checkAndRefreshSession();
    }
    
    final accessToken = (await _accessTokenProvider())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ServiceRequestException(
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      })
      ..fields.addAll(_buildTextFields(payload));

    final photos = _uniqueLocalMedia(payload, type: 'image');
    final videos = _uniqueLocalMedia(payload, type: 'video');
    if (photos.length > 3) {
      throw const ServiceRequestException(
        message: 'A maximum of three photos can be attached.',
      );
    }
    if (videos.length > 1) {
      throw const ServiceRequestException(
        message: 'Only one video can be attached to a service request.',
      );
    }

    for (final photo in photos) {
      request.files.add(
        await _multipartFile(
          field: ServiceRequestMultipartFields.photos,
          file: photo,
          kind: 'photo',
        ),
      );
    }
    if (videos.isNotEmpty) {
      request.files.add(
        await _multipartFile(
          field: ServiceRequestMultipartFields.video,
          file: videos.single,
          kind: 'video',
        ),
      );
    }

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResult(decoded);
      }
      throw ServiceRequestException(
        statusCode: response.statusCode,
        message: _readMessage(decoded) ?? _statusMessage(response.statusCode),
        responseBody: response.body.isEmpty ? null : response.body,
      );
    } on ServiceRequestException {
      rethrow;
    } catch (_) {
      throw const ServiceRequestException(
        message: 'Could not connect to the server. Please try again.',
      );
    }
  }

  Map<String, String> _buildTextFields(ServiceRequestPayload payload) {
    final location = payload.serviceLocation;
    return <String, String>{
      'category': payload.categoryId,
      'description': payload.description,
      'latitude': location.latitude.toStringAsFixed(6),
      'longitude': location.longitude.toStringAsFixed(6),
    };
  }

  List<XFile> _uniqueLocalMedia(
    ServiceRequestPayload payload, {
    required String type,
  }) {
    final paths = <String>{};
    final files = <XFile>{};
    return payload.media
        .where((item) => item.type == type && item.localFile != null)
        .map((item) => item.localFile!)
        .where((file) {
          if (!files.add(file)) return false;
          return file.path.isEmpty || paths.add(file.path);
        })
        .toList(growable: false);
  }

  Future<http.MultipartFile> _multipartFile({
    required String field,
    required XFile file,
    required String kind,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw ServiceRequestException(
          message: 'The selected $kind "${file.name}" is empty.',
        );
      }
      return http.MultipartFile.fromBytes(field, bytes, filename: file.name);
    } on ServiceRequestException {
      rethrow;
    } catch (_) {
      throw ServiceRequestException(
        message: 'The selected $kind "${file.name}" is no longer readable.',
      );
    }
  }

  void _validatePayload(ServiceRequestPayload payload) {
    if (payload.categoryId.trim().isEmpty) {
      throw const ServiceRequestException(
        message: 'A valid service category is required.',
      );
    }
    final desc = payload.description.trim();
    if (desc.isEmpty) {
      throw const ServiceRequestException(
        message: 'Please describe the service problem.',
      );
    }
    if (desc.length > 300) {
      throw const ServiceRequestException(
        message: 'Description cannot exceed 300 characters.',
      );
    }
    if (!payload.serviceLocation.hasValidCoordinates) {
      throw const ServiceRequestException(
        message: 'Please select a valid service location.',
      );
    }
  }

  ServiceRequestResult _parseResult(Map<String, dynamic> response) {
    final nested = response['data'];
    final data = nested is Map<String, dynamic> ? nested : response;
    final requestId =
        data['request_id']?.toString() ??
        data['requestId']?.toString() ??
        data['id']?.toString() ??
        '';
    if (requestId.isEmpty) {
      throw const ServiceRequestException(
        message: 'The server response did not include a request ID.',
      );
    }
    return ServiceRequestResult(
      requestId: requestId,
      status: data['status']?.toString() ?? 'active',
      createdAt:
          DateTime.tryParse(
            data['created_at']?.toString() ??
                data['createdAt']?.toString() ??
                '',
          )?.toUtc() ??
          DateTime.now().toUtc(),
      message:
          _readMessage(response) ?? 'Service request created successfully.',
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } on FormatException {
      // Never expose an HTML error page or arbitrary server output to the UI.
      return <String, dynamic>{};
    }
  }

  String? _readMessage(Map<String, dynamic> response) {
    if (response.containsKey('detail')) {
      return response['detail']?.toString().trim();
    }
    if (response.containsKey('message')) {
      return response['message']?.toString().trim();
    }
    // Collect all field validation errors
    final errorParts = <String>[];
    response.forEach((key, value) {
      if (key == 'success' || key == 'code') return;
      if (value is List) {
        final errorText = value.map((e) => e.toString().trim()).join(', ');
        errorParts.add('$key: $errorText');
      } else if (value is String) {
        errorParts.add('$key: ${value.trim()}');
      } else if (value is Map) {
        final subMsg = _readMessage(Map<String, dynamic>.from(value));
        if (subMsg != null && subMsg.isNotEmpty) {
          errorParts.add('$key: $subMsg');
        }
      }
    });
    if (errorParts.isNotEmpty) {
      return errorParts.join('\n');
    }

    final nested = response['data'];
    if (nested is Map<String, dynamic>) {
      final message = nested['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }

  bool _isValidTime(String? value) =>
      value != null &&
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d:[0-5]\d$').hasMatch(value);

  String _statusMessage(int statusCode) => switch (statusCode) {
    400 => 'Please correct the submitted information.',
    401 => 'Your session has expired. Please sign in again.',
    403 => 'Your account cannot create this request.',
    404 => 'The selected service category was not found.',
    413 => 'One or more selected files are too large.',
    415 => 'One or more selected files use an unsupported format.',
    _ => 'Unable to create the service request. Please try again.',
  };
}
