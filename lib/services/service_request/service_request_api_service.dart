import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/service_request/service_request_draft.dart';

class ServiceRequestApiException implements Exception {
  const ServiceRequestApiException({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  final int statusCode;
  final String message;
  final String? responseBody;

  @override
  String toString() => 'ServiceRequestApiException($statusCode): $message';
}

class ServiceRequestApiService {
  const ServiceRequestApiService();

  // BACKEND TODO:
  // Replace the endpoint after the Django developer confirms the final route.
  // Suggested route: POST /api/customer/service-requests/
  // Multipart contract: `payload` is a JSON string; `photos` is zero to three
  // repeated images (request.FILES.getlist('photos')); `video` is zero or one
  // file (request.FILES.get('video')). DRF should use MultiPartParser and
  // FormParser, then json.loads(request.data['payload']). A successful response
  // should include id, status, message, created_at, and scheduled_for.
  // Schedule fields live inside payload: schedule_mode is `now` or `scheduled`;
  // scheduled_for is null or an ISO-8601 UTC timestamp. Django should use its
  // configured service-area timezone to confirm it is a future time today.
  Future<Map<String, dynamic>> createServiceRequest({
    required Uri endpoint,
    required String accessToken,
    required ServiceRequestDraft draft,
  }) async {
    final request = http.MultipartRequest('POST', endpoint)
      ..headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      })
      ..fields['payload'] = jsonEncode(draft.toJson());

    for (final photo in draft.photos) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photos',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    }
    if (draft.video != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          await draft.video!.readAsBytes(),
          filename: draft.video!.name,
        ),
      );
    }

    final response = await http.Response.fromStream(await request.send());
    final decoded = _decodeObject(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    throw ServiceRequestApiException(
      statusCode: response.statusCode,
      message:
          decoded['message']?.toString() ?? 'Unable to create service request.',
      responseBody: response.body.isEmpty ? null : response.body,
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic>
          ? value
          : <String, dynamic>{'data': value};
    } on FormatException {
      return <String, dynamic>{'message': body};
    }
  }
}
