import 'package:latlong2/latlong.dart';

import '../../core/constants/api_urls.dart';
import 'booking_status_response.dart';

class AcceptedWorkerUiModel {
  const AcceptedWorkerUiModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.profileImageUrl,
    this.profileImageAsset,
    this.rating,
    this.completedJobs,
    this.profileDescription,
    this.distanceKm,
    this.estimatedArrivalMinutes,
    this.acceptedAt,
    this.arrivedAt,
  });

  final String id;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? profileImageAsset;
  final double? rating;
  final int? completedJobs;
  final String? profileDescription;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final int? estimatedArrivalMinutes;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;

  LatLng get coordinate => LatLng(latitude, longitude);

  /// Maps the real `GET /api/services/bookings/<id>/status/` worker payload
  /// into the UI model this screen already knows how to render.
  ///
  /// `distanceKm` and `estimatedArrivalMinutes` are left null — the status
  /// endpoint doesn't provide either, and the UI already treats both as
  /// optional (hidden when absent) rather than showing a fabricated number.
  factory AcceptedWorkerUiModel.fromAssignedWorker(AssignedWorkerInfo worker) {
    return AcceptedWorkerUiModel(
      id: worker.id,
      name: worker.fullName,
      phoneNumber: worker.phoneNumber,
      profileImageUrl: worker.profilePhoto == null
          ? null
          : ApiUrls.resolveMediaUrl(worker.profilePhoto!),
      rating: worker.averageRating,
      completedJobs: worker.completedJobs,
      latitude: worker.currentLatitude ?? 0,
      longitude: worker.currentLongitude ?? 0,
      acceptedAt: DateTime.now(),
    );
  }

  // BACKEND INTEGRATION:
  // Populate worker name, profile image, rating, and profile description from
  // the accepted-worker response. profileDescription must be the description
  // written by the worker on their worker profile. Rating may be null for a
  // new worker; keep the rating section hidden instead of displaying 0.0.
  //
  // FRONTEND DEMO ONLY:
  // Replace AcceptedWorkerUiModel.demo() with data mapped from the
  // accepted-worker API response.
  factory AcceptedWorkerUiModel.demo({
    required double customerLatitude,
    required double customerLongitude,
  }) {
    return AcceptedWorkerUiModel(
      id: 'demo-worker-001',
      name: 'Aarav Sharma',
      profileImageAsset: 'assets/images/technician_avatar.png',
      rating: 4.7,
      completedJobs: 167,
      // FRONTEND DEMO ONLY:
      // Replace this text with the worker's profile description returned by
      // the backend accepted-worker/profile response.
      profileDescription:
          'Reliable professional focused on quality service and customer care.',
      latitude: customerLatitude + .0024,
      longitude: customerLongitude - .0018,
      distanceKm: 1.2,
      estimatedArrivalMinutes: 2,
      acceptedAt: DateTime.now(),
    );
  }
}
