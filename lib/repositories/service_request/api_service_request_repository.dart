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
  // REAL MULTIPART SERVICE REQUEST API (CONFIRMED CONTRACT)
  // ========================================================================
  //
  // Method: POST ApiUrls.serviceRequests ("/services/bookings/")
  // Auth: Authorization: Bearer <access_token> (read via StorageService),
  //       Accept: application/json.
  //
  // ------------------------------------------------------------------------
  // MULTIPART TEXT FIELDS (only these six are sent — nothing else)
  // ------------------------------------------------------------------------
  // category    — integer, required. The active Category id from
  //               GET /services/categories/ (the same id the customer-home
  //               category grid uses). An inactive or non-existent id is
  //               rejected by the backend.
  // description — text, required, max 300 chars, cannot be blank/
  //               whitespace-only.
  // latitude    — decimal, required. No fallback location exists.
  // longitude   — decimal, required.
  //
  // "Schedule for Later" (ServiceScheduleCard) is intentionally NOT part of
  // this contract yet — it stays in the UI as an inert control (per product
  // decision) but nothing it collects is sent.
  //
  // ------------------------------------------------------------------------
  // MULTIPART MEDIA FIELDS
  // ------------------------------------------------------------------------
  // photos — 0-3 image files, repeated field name "photos" for each.
  // video  — 0-1 video file, field name "video".
  //
  // ------------------------------------------------------------------------
  // SUCCESS RESPONSE (HTTP 201, flat — no "data" wrapper)
  // ------------------------------------------------------------------------
  // {
  //   "id": 12,
  //   "category": "Plumber",
  //   "description": "Kitchen pipe is leaking",
  //   "address_text": "Lazimpat, Kathmandu, Bagmati Province, Nepal",
  //   "status": "active",
  //   "offers_sent": 3
  // }
  // Parsed by _parseResult into ServiceRequestResult (id -> requestId,
  // address_text -> addressText, offers_sent -> offersSent). There is no
  // created_at in this response; createdAt falls back to the submission time.
  //
  // ------------------------------------------------------------------------
  // ERROR RESPONSES
  // ------------------------------------------------------------------------
  // 400 — validation errors (bad category, empty description, too many
  //       photos, missing lat/long), read via _readErrorMessage.
  // 403 — not a customer account.
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
        message:
            _readErrorMessage(decoded) ?? _statusMessage(response.statusCode),
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
          _readPlainMessage(response) ??
          'Service request created successfully.',
      addressText: _readAddressText(data),
      offersSent: _readOffersSent(data),
    );
  }

  String? _readAddressText(Map<String, dynamic> data) {
    final text = (data['address_text'] ?? data['addressText'])
        ?.toString()
        .trim();
    return text == null || text.isEmpty ? null : text;
  }

  int? _readOffersSent(Map<String, dynamic> data) {
    final value = data['offers_sent'] ?? data['offersSent'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
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

  /// Reads only an explicit message the server sent. Used on the success path.
  ///
  /// WHY this is separate from [_readErrorMessage]:
  ///   The booking endpoint returns 201 with {id, category, description,
  ///   address_text, status, offers_sent} and no message field. Running the
  ///   error formatter over that would scrape the created booking's own data
  ///   into "category: Plumbing Service\ndescription: ..." and show it to the
  ///   customer as the success text. A success response has no field errors to
  ///   collect, so there is nothing here to fall back to but the caller's
  ///   default.
  String? _readPlainMessage(Map<String, dynamic> response) {
    for (final key in const ['message', 'detail']) {
      final text = response[key]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }

    final nested = response['data'];
    if (nested is Map<String, dynamic>) {
      final text = nested['message']?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  /// Builds a readable message from an error response, falling back to
  /// collecting DRF field errors such as {"description": ["Cannot be empty"]}.
  /// Only call this for non-2xx responses — see [_readPlainMessage].
  String? _readErrorMessage(Map<String, dynamic> response) {
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
        final subMsg = _readErrorMessage(Map<String, dynamic>.from(value));
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
