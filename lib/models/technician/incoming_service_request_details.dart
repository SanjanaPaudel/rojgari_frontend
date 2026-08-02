import '../../core/constants/api_urls.dart';

class IncomingServiceRequestDetails {
  const IncomingServiceRequestDetails({
    required this.id,
    required this.customerName,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.description,
    required this.locationText,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.photoUrls = const [],
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDurationSeconds,
    this.status,
    this.visitCharge,
    this.expiresInSeconds,
  });

  final String id;
  final String customerName;
  final String categoryId;
  final String categoryName;
  final String categorySlug;

  // BACKEND DATA:
  // Map the service-request API description field to request.description.
  // The UI must not make the HTTP request directly.
  final String description;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  // BACKEND DATA:
  // The request-details API should return a list of uploaded photo URLs.
  // Map those URLs to request.photoUrls before opening this screen.
  final List<String> photoUrls;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final int? videoDurationSeconds;
  final String? status;

  // What the worker earns just for showing up to this job.
  final double? visitCharge;

  // Seconds left to accept/decline as of when this was fetched — see
  // IncomingRequest.expiresInSeconds for the same semantics.
  final int? expiresInSeconds;

  /// Maps `GET /api/auth/worker/request/<offer_id>/`.
  ///
  /// Response fields: offer_id, customer_name, service, service_icon,
  /// description, address, latitude, longitude, distance_km, visit_charge,
  /// expires_in_seconds, photos, video, status, created_at.
  ///
  /// Fields with no backend source:
  ///   • categoryId / categorySlug — the API returns a flat `service` name.
  ///     categorySlug is left empty; ServiceCategoryIconResolver falls back to
  ///     matching on categoryName, so the icon still resolves.
  ///   • videoThumbnailUrl / videoDurationSeconds — not returned. The screen
  ///     already falls back to a placeholder and hides the duration badge.
  factory IncomingServiceRequestDetails.fromJson(Map<String, dynamic> json) {
    final video = json['video']?.toString();

    return IncomingServiceRequestDetails(
      id: json['offer_id'].toString(),
      customerName: json['customer_name']?.toString() ?? '',
      categoryId: '',
      categoryName: json['service']?.toString() ?? '',
      categorySlug: '',
      description: json['description']?.toString() ?? '',
      locationText: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      distanceKm: _toDouble(json['distance_km']),
      visitCharge: _toDouble(json['visit_charge']),
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt(),
      photoUrls: (json['photos'] as List<dynamic>? ?? const [])
          .map((photo) => ApiUrls.resolveMediaUrl(photo.toString()))
          .toList(growable: false),
      videoUrl: (video == null || video.isEmpty)
          ? null
          : ApiUrls.resolveMediaUrl(video),
      status: json['status']?.toString(),
    );
  }

  /// Django DecimalField values can arrive as either a JSON number or a
  /// quoted string depending on renderer settings, so both are handled.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String get shortDescription {
    final normalized = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    final words = normalized.split(' ');
    final summary = words.take(4).join(' ');
    return words.length > 4 ? '$summary…' : summary;
  }
}
