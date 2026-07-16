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

  String get shortDescription {
    final normalized = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    final words = normalized.split(' ');
    final summary = words.take(4).join(' ');
    return words.length > 4 ? '$summary…' : summary;
  }
}
