import 'dart:convert';

import '../../core/constants/api_urls.dart';
import '../../models/technician/incoming_service_request_details.dart';
import '../../models/technician/technician_active_job_model.dart';
import '../../models/technician/technician_job_status.dart';
import '../../services/api_service.dart';
import '../../services/location/location_service.dart';
import 'technician_job_repository.dart';

/// Real backend-backed [TechnicianJobRepository], per the worker-side API
/// reference (accept/, GET current-job/, start/, complete/, PATCH location/).
class ApiTechnicianJobRepository implements TechnicianJobRepository {
  ApiTechnicianJobRepository({
    ApiService? apiService,
    LocationService? locationService,
  }) : _api = apiService ?? ApiService(),
       _location = locationService ?? const LocationService();

  final ApiService _api;
  final LocationService _location;

  @override
  Future<TechnicianActiveJobModel> acceptRequest(
    IncomingServiceRequestDetails request,
  ) async {
    final response = await _api.post(
      ApiUrls.workerAcceptRequest(request.id),
      const {},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw TechnicianJobException(
        _messageFor(
          response.body,
          'Unable to accept this request (HTTP ${response.statusCode}).',
        ),
      );
    }

    // The accept response only confirms booking_id/status — the full
    // customer/job detail needed to populate the tracking screen comes from
    // GET current-job/, fetched immediately after a successful accept.
    return _fetchCurrentJob(offerId: request.id);
  }

  @override
  Future<TechnicianActiveJobModel> getActiveJob(String requestId) {
    return _fetchCurrentJob(offerId: requestId);
  }

  @override
  Future<void> updateJobStatus(
    String requestId,
    TechnicianJobStatus status,
  ) async {
    // The real backend has no generic "set status" endpoint and no concept
    // of en-route/arrived at all — job_progress only moves accepted ->
    // working -> completed, driven by the discrete start/ and complete/
    // actions below. "working" is the only status this method can act on;
    // "completed" goes through completeJob() instead, and en-route/arrived
    // are purely client-side UI states with nothing to persist server-side.
    if (status != TechnicianJobStatus.working) return;

    final response = await _api.post(ApiUrls.workerStartJob(requestId), const {});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw TechnicianJobException(
        _messageFor(
          response.body,
          'Unable to start the job (HTTP ${response.statusCode}).',
        ),
      );
    }
  }

  @override
  Future<void> updateTechnicianLocation(
    String requestId,
    double latitude,
    double longitude,
  ) async {
    final response = await _api.patch(ApiUrls.workerLocation, {
      'latitude': latitude,
      'longitude': longitude,
    });
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw TechnicianJobException(
        _messageFor(
          response.body,
          'Unable to update your location (HTTP ${response.statusCode}).',
        ),
      );
    }
  }

  @override
  Future<void> completeJob(String requestId) async {
    final response = await _api.post(
      ApiUrls.workerCompleteJob(requestId),
      const {},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw TechnicianJobException(
        _messageFor(
          response.body,
          'Unable to complete the job (HTTP ${response.statusCode}).',
        ),
      );
    }
  }

  Future<TechnicianActiveJobModel> _fetchCurrentJob({
    required String offerId,
  }) async {
    final response = await _api.get(ApiUrls.workerCurrentJob);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return _parseCurrentJob(decoded, offerId: offerId);
      }
      throw const TechnicianJobException(
        'Unexpected response while loading the active job.',
      );
    }

    if (response.statusCode == 404) {
      throw const TechnicianJobException('No active job found.');
    }

    throw TechnicianJobException(
      _messageFor(
        response.body,
        'Unable to load the active job (HTTP ${response.statusCode}).',
      ),
    );
  }

  /// Builds the UI model from GET current-job/'s response.
  ///
  /// [offerId] is threaded through separately rather than read off the
  /// response because start/ and complete/ both key off the *original*
  /// BookingOffer id — the same one used by accept/reject — and this
  /// endpoint never actually returns that id: it only exposes booking_id (a
  /// different underlying entity) and a cosmetically formatted request_id
  /// string ("#REQ00007"). Neither is usable as the offer_id path segment.
  Future<TechnicianActiveJobModel> _parseCurrentJob(
    Map<String, dynamic> json, {
    required String offerId,
  }) async {
    final customer = json['customer'] as Map<String, dynamic>? ?? const {};
    final customerLatitude = _toDouble(json['latitude']);
    final customerLongitude = _toDouble(json['longitude']);

    // The backend has no notion of the worker's own position — seed it from
    // the device's current fix so the map doesn't flash at (0, 0) before
    // TechnicianActiveJobScreen's own live-location stream takes over.
    // Falling back to the customer's coordinate (not null-island) keeps the
    // initial map view sane if location isn't available yet.
    var technicianLatitude = customerLatitude;
    var technicianLongitude = customerLongitude;
    try {
      final current = await _location.getCurrentLocation();
      technicianLatitude = current.latitude;
      technicianLongitude = current.longitude;
    } catch (_) {
      // Keep the customer-coordinate fallback; the screen's own permission
      // flow (enableDeviceLocation) will prompt and recover from here.
    }

    return TechnicianActiveJobModel(
      requestId: offerId,
      categoryId: '',
      categoryName: json['category']?.toString() ?? '',
      categorySlug: '',
      issueTitle: json['category']?.toString() ?? '',
      fullProblemDescription: json['description']?.toString() ?? '',
      customerId: '',
      customerName: customer['name']?.toString() ?? '',
      customerProfileImageUrl: _resolveNullableMedia(
        customer['profile_photo'],
      ),
      customerAddress: json['address']?.toString() ?? '',
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      requestedAt:
          DateTime.tryParse(json['requested_at']?.toString() ?? '') ??
          DateTime.now(),
      acceptedAt: DateTime.now(),
      technicianLatitude: technicianLatitude,
      technicianLongitude: technicianLongitude,
      currentStatus: TechnicianJobStatus.fromBackendValue(
        json['job_progress']?.toString(),
      ),
    );
  }

  String? _resolveNullableMedia(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return ApiUrls.resolveMediaUrl(text);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Pulls the backend's `detail`/`message` out of an error body, falling
  /// back to [fallback] when the body is not JSON or carries no message.
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
