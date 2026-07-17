import 'incoming_service_request_details.dart';
import 'technician_job_status.dart';

class TechnicianActiveJobModel {
  const TechnicianActiveJobModel({
    required this.requestId,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.issueTitle,
    required this.fullProblemDescription,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.requestedAt,
    required this.acceptedAt,
    required this.technicianLatitude,
    required this.technicianLongitude,
    required this.currentStatus,
    this.customerProfileImageUrl,
    this.customerProfileImageAsset,
    this.customerPhone,
    this.arrivedAt,
    this.workStartedAt,
    this.completedAt,
  });

  final String requestId;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final String issueTitle;
  final String fullProblemDescription;
  final String customerId;
  final String customerName;
  final String? customerProfileImageUrl;
  final String? customerProfileImageAsset;
  final String? customerPhone;
  final String customerAddress;
  final double customerLatitude;
  final double customerLongitude;
  final DateTime requestedAt;
  final DateTime acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? workStartedAt;
  final DateTime? completedAt;
  final double technicianLatitude;
  final double technicianLongitude;
  final TechnicianJobStatus currentStatus;

  /// Builds a safe UI model from the request-details data already available
  /// when the technician presses Accept.
  factory TechnicianActiveJobModel.fromIncomingRequest(
    IncomingServiceRequestDetails request, {
    required DateTime requestedAt,
    required DateTime acceptedAt,
    required double fallbackCustomerLatitude,
    required double fallbackCustomerLongitude,
    required double technicianLatitude,
    required double technicianLongitude,
    String customerId = '',
    String? customerProfileImageUrl,
    String? customerProfileImageAsset,
    String? customerPhone,
  }) {
    return TechnicianActiveJobModel(
      requestId: request.id,
      categoryId: request.categoryId,
      categoryName: request.categoryName,
      categorySlug: request.categorySlug,
      issueTitle: request.shortDescription.isEmpty
          ? request.categoryName
          : request.shortDescription,
      fullProblemDescription: request.description,
      customerId: customerId,
      customerName: request.customerName,
      customerProfileImageUrl: customerProfileImageUrl,
      customerProfileImageAsset: customerProfileImageAsset,
      customerPhone: customerPhone,
      customerAddress: request.locationText,
      customerLatitude: request.latitude ?? fallbackCustomerLatitude,
      customerLongitude: request.longitude ?? fallbackCustomerLongitude,
      requestedAt: requestedAt,
      acceptedAt: acceptedAt,
      technicianLatitude: technicianLatitude,
      technicianLongitude: technicianLongitude,
      currentStatus: TechnicianJobStatus.accepted,
    );
  }

  factory TechnicianActiveJobModel.fromJson(Map<String, dynamic> json) {
    return TechnicianActiveJobModel(
      requestId: _string(json['request_id'] ?? json['id']),
      categoryId: _string(json['category_id']),
      categoryName: _string(json['category_name'] ?? json['service']),
      categorySlug: _string(json['category_slug']),
      issueTitle: _string(json['issue_title']),
      fullProblemDescription: _string(
        json['problem_description'] ?? json['description'],
      ),
      customerId: _string(json['customer_id']),
      customerName: _string(json['customer_name']),
      customerProfileImageUrl: _nullableString(
        json['customer_profile_image_url'],
      ),
      customerPhone: _nullableString(json['customer_phone']),
      customerAddress: _string(json['customer_address'] ?? json['address']),
      customerLatitude: _double(json['customer_latitude'] ?? json['latitude']),
      customerLongitude: _double(
        json['customer_longitude'] ?? json['longitude'],
      ),
      requestedAt: _date(json['requested_at']),
      acceptedAt: _date(json['accepted_at']),
      arrivedAt: _nullableDate(json['arrived_at']),
      workStartedAt: _nullableDate(json['work_started_at']),
      completedAt: _nullableDate(json['completed_at']),
      technicianLatitude: _double(json['technician_latitude']),
      technicianLongitude: _double(json['technician_longitude']),
      currentStatus: TechnicianJobStatus.fromBackendValue(
        json['status']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'category_id': categoryId,
    'category_name': categoryName,
    'category_slug': categorySlug,
    'issue_title': issueTitle,
    'problem_description': fullProblemDescription,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_profile_image_url': customerProfileImageUrl,
    'customer_phone': customerPhone,
    'customer_address': customerAddress,
    'customer_latitude': customerLatitude,
    'customer_longitude': customerLongitude,
    'requested_at': requestedAt.toUtc().toIso8601String(),
    'accepted_at': acceptedAt.toUtc().toIso8601String(),
    'arrived_at': arrivedAt?.toUtc().toIso8601String(),
    'work_started_at': workStartedAt?.toUtc().toIso8601String(),
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'technician_latitude': technicianLatitude,
    'technician_longitude': technicianLongitude,
    'status': currentStatus.backendValue,
  };

  TechnicianActiveJobModel copyWith({
    TechnicianJobStatus? currentStatus,
    double? technicianLatitude,
    double? technicianLongitude,
    DateTime? arrivedAt,
    DateTime? workStartedAt,
    DateTime? completedAt,
  }) {
    return TechnicianActiveJobModel(
      requestId: requestId,
      categoryId: categoryId,
      categoryName: categoryName,
      categorySlug: categorySlug,
      issueTitle: issueTitle,
      fullProblemDescription: fullProblemDescription,
      customerId: customerId,
      customerName: customerName,
      customerProfileImageUrl: customerProfileImageUrl,
      customerProfileImageAsset: customerProfileImageAsset,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      requestedAt: requestedAt,
      acceptedAt: acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      completedAt: completedAt ?? this.completedAt,
      technicianLatitude: technicianLatitude ?? this.technicianLatitude,
      technicianLongitude: technicianLongitude ?? this.technicianLongitude,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  static String _string(dynamic value) => value?.toString() ?? '';
  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
