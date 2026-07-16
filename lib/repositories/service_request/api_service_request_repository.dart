import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_urls.dart';
import '../../models/service_request/service_request_payload.dart';
import '../../models/service_request/service_request_validation.dart';
import '../../services/storage_service.dart';
import 'service_request_repository.dart';

class ServiceRequestMultipartFields {
  const ServiceRequestMultipartFields._();

  static const String category = 'category';
  static const String description = 'description';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String photos = 'photos';
  static const String video = 'video';
}

class ApiServiceRequestRepository implements ServiceRequestRepository {
  ApiServiceRequestRepository({
    http.Client? client,
    Uri? endpoint,
    Future<String?> Function()? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? Uri.parse(ApiUrls.createBooking),
       _accessTokenProvider =
           accessTokenProvider ?? StorageService().getAccessToken;

  final http.Client _client;
  final Uri _endpoint;
  final Future<String?> Function() _accessTokenProvider;

  // ============================================================================
  // REAL BACKEND INTEGRATION: CREATE SERVICE BOOKING
  // ============================================================================
  //
  // ENDPOINT:
  //
  // POST /api/services/bookings/
  //
  // AUTHENTICATION:
  //
  // Authorization: Bearer <access_token>
  //
  // The access token is returned by POST /api/auth/login/ under the exact key
  // "access" and must be read from the existing StorageService.
  //
  // Do not send customer_id. Django obtains the customer from the JWT user.
  //
  // ---------------------------------------------------------------------------
  // CATEGORY
  // ---------------------------------------------------------------------------
  //
  // Send:
  //
  // category
  //
  // It must be the real integer ID returned by:
  //
  // GET /api/services/categories/
  //
  // Categories response:
  //
  // {
  //   "categories": [
  //     {
  //       "id": 1,
  //       "name": "Plumber",
  //       "description": "...",
  //       "icon": "...",
  //       "display_order": 0
  //     }
  //   ]
  // }
  //
  // Never send a category name, slug or guessed numeric mapping.
  //
  // ---------------------------------------------------------------------------
  // EXACT MULTIPART TEXT FIELDS
  // ---------------------------------------------------------------------------
  //
  // category
  // description
  // latitude
  // longitude
  //
  // ---------------------------------------------------------------------------
  // EXACT MULTIPART FILE FIELDS
  // ---------------------------------------------------------------------------
  //
  // photos
  // - zero to three
  // - every image uses the repeated field name "photos"
  //
  // video
  // - zero or one optional file
  //
  // Actual bytes are uploaded.
  // Local file paths must never be sent as text fields.
  //
  // ---------------------------------------------------------------------------
  // DO NOT SEND
  // ---------------------------------------------------------------------------
  //
  // category_id
  // schedule_type
  // scheduled_time
  // timezone
  // preferredDate
  // preferredTime
  // scheduleForLater
  // accuracy_meters
  // landmark
  // location_source
  // formatted_address
  // address_text
  //
  // The current backend sprint does not accept schedule or landmark values.
  // Their approved UI remains unchanged, but they are not part of this request.
  //
  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------
  //
  // Flutter sends only latitude and longitude.
  //
  // Django performs reverse geocoding and returns address_text.
  //
  // address_text can be null. A null value is not an API failure.
  //
  // ---------------------------------------------------------------------------
  // SUCCESS
  // ---------------------------------------------------------------------------
  //
  // HTTP 201:
  //
  // {
  //   "id": 12,
  //   "category": "Plumber",
  //   "description": "Kitchen pipe is leaking under the sink",
  //   "address_text": "Lazimpat, Kathmandu, Bagmati Province, Nepal",
  //   "status": "active"
  // }
  //
  // No worker is assigned by this endpoint.
  // No matching or polling endpoint exists in this sprint.
  // No schedule result is returned.
  //
  // ---------------------------------------------------------------------------
  // ERRORS
  // ---------------------------------------------------------------------------
  //
  // HTTP 400:
  // Django field validation errors; values can be strings or string lists.
  //
  // HTTP 401:
  // Missing, invalid or expired JWT.
  //
  // HTTP 403:
  // Authenticated account is not a customer.
  //
  // Convert these responses into readable repository exceptions.
  // Never expose raw HTML, stack traces or unparsed maps.
  //
  // ---------------------------------------------------------------------------
  // FUTURE BACKEND SUPPORT
  // ---------------------------------------------------------------------------
  //
  // If the backend later adds scheduling:
  // - document the accepted scheduling field(s)
  // - update only this repository/payload layer
  // - do not redesign the Request Page
  //
  // If the backend later adds landmark:
  // - add the exact documented field here
  // - do not place landmark inside description or address_text
  //
  // Do not move HTTP code into the Request Page.
  // ============================================================================
  @override
  Future<ServiceRequestResult> createServiceRequest(
    ServiceRequestPayload payload,
  ) async {
    _validatePayload(payload);
    final accessToken = (await _accessTokenProvider())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ServiceRequestException(
        message: 'Your session has expired. Please sign in again.',
      );
    }

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

    final location = payload.serviceLocation;
    final request = http.MultipartRequest('POST', _endpoint)
      ..headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      })
      ..fields.addAll({
        ServiceRequestMultipartFields.category: payload.categoryId.toString(),
        ServiceRequestMultipartFields.description: payload.description.trim(),
        ServiceRequestMultipartFields.latitude: location.latitude.toString(),
        ServiceRequestMultipartFields.longitude: location.longitude.toString(),
      });

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
      // BACKEND TODO: The current API does not document or validate video
      // duration or file-size limits. Flutter retains the existing 30-second
      // validation until the backend publishes its definitive constraints.
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
      if (response.statusCode == 201) return _parseResult(decoded);

      throw ServiceRequestException(
        statusCode: response.statusCode,
        message: _errorMessage(response.statusCode, decoded),
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

  void _validatePayload(ServiceRequestPayload payload) {
    if (payload.categoryId <= 0) {
      throw const ServiceRequestException(
        message: 'Select an available service category and try again.',
      );
    }
    final descriptionError = ServiceRequestValidation.description(
      payload.description,
    );
    if (descriptionError != null) {
      throw ServiceRequestException(message: descriptionError);
    }
    final locationError = ServiceRequestValidation.location(
      payload.serviceLocation,
    );
    if (locationError != null) {
      throw ServiceRequestException(message: locationError);
    }
    // BACKEND TODO: Scheduling remains local UI state only. The current
    // booking endpoint always creates status "active" and accepts no schedule.
    // BACKEND TODO: Landmark remains local UI state only. Add it here only
    // after Django documents an optional landmark request field.
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

  ServiceRequestResult _parseResult(Map<String, dynamic> response) {
    final idValue = response['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '');
    if (id == null) {
      throw const ServiceRequestException(
        message: 'The server response did not include a booking ID.',
      );
    }
    return ServiceRequestResult(
      id: id,
      category: response['category']?.toString() ?? '',
      description: response['description']?.toString() ?? '',
      addressText: response['address_text']?.toString(),
      status: response['status']?.toString() ?? 'active',
      message: 'Booking created successfully.',
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String _errorMessage(int statusCode, Map<String, dynamic> response) {
    if (statusCode == 400) {
      return _firstReadableValidationMessage(response) ??
          'Please correct the submitted information.';
    }
    if (statusCode == 401) {
      return 'Your login session is missing, invalid, or expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'Only customer accounts can create a service booking.';
    }
    return _readDirectMessage(response) ??
        'Unable to create the service booking. Please try again.';
  }

  String? _firstReadableValidationMessage(Map<String, dynamic> response) {
    final direct = _readDirectMessage(response);
    if (direct != null) return direct;
    for (final entry in response.entries) {
      if (entry.key == 'detail' || entry.key == 'message') continue;
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List) {
        for (final item in value) {
          final text = item?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }
    return null;
  }

  String? _readDirectMessage(Map<String, dynamic> response) {
    for (final key in const ['detail', 'message']) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List && value.isNotEmpty) {
        final first = value.first?.toString().trim();
        if (first != null && first.isNotEmpty) return first;
      }
    }
    return null;
  }
}
