import 'request_search_status.dart';

/// Worker payload nested inside a [BookingStatusResponse] once assigned.
///
/// Maps `GET /api/services/bookings/<id>/status/`'s "worker" object.
class AssignedWorkerInfo {
  const AssignedWorkerInfo({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.averageRating,
    this.completedJobs,
    this.profilePhoto,
    this.currentLatitude,
    this.currentLongitude,
  });

  final String id;
  final String fullName;
  final String? phoneNumber;
  final double? averageRating;
  final int? completedJobs;
  final String? profilePhoto;
  final double? currentLatitude;
  final double? currentLongitude;

  factory AssignedWorkerInfo.fromJson(Map<String, dynamic> json) {
    return AssignedWorkerInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number']?.toString(),
      averageRating: _toDouble(json['average_rating']),
      completedJobs: _toInt(json['completed_jobs']),
      profilePhoto: json['profile_photo']?.toString(),
      currentLatitude: _toDouble(json['current_latitude']),
      currentLongitude: _toDouble(json['current_longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Result of one `GET /api/services/bookings/<id>/status/` poll.
///
/// `worker` is null while the backend hasn't assigned a technician yet — the
/// top-level `status` stays "active" either way, so [hasAssignedWorker] (not
/// [status]) is the actual assignment signal to act on.
class BookingStatusResponse {
  const BookingStatusResponse({
    required this.id,
    required this.status,
    required this.jobProgress,
    this.worker,
    this.categoryName,
    this.description,
    this.addressText,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final String id;
  final String status;

  /// The worker-side job stage ("accepted" / "working" / "completed"),
  /// mapped through the same [RequestSearchStatus.fromBackendValue] the rest
  /// of the app uses — distinct from [status], which is the booking's own
  /// lifecycle ("active" / "assigned" / etc), not the in-progress job stage.
  final RequestSearchStatus jobProgress;
  final AssignedWorkerInfo? worker;

  /// BookingDetailSerializer's `category` field — already just the category
  /// name (a CharField sourced from `category.name`), not an id/slug object.
  final String? categoryName;
  final String? description;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  bool get hasAssignedWorker => worker != null;

  factory BookingStatusResponse.fromJson(Map<String, dynamic> json) {
    final workerJson = json['worker'];
    return BookingStatusResponse(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      jobProgress: RequestSearchStatus.fromBackendValue(
        json['job_progress']?.toString(),
      ),
      worker: workerJson is Map<String, dynamic>
          ? AssignedWorkerInfo.fromJson(workerJson)
          : null,
      categoryName: json['category']?.toString(),
      description: json['description']?.toString(),
      addressText: json['address_text']?.toString(),
      latitude: AssignedWorkerInfo._toDouble(json['latitude']),
      longitude: AssignedWorkerInfo._toDouble(json['longitude']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
