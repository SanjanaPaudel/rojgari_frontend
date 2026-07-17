import 'package:latlong2/latlong.dart';

import 'request_search_status.dart';

class WorkerTrackingUiState {
  const WorkerTrackingUiState({
    required this.coordinate,
    required this.distanceKm,
    required this.estimatedArrivalMinutes,
    required this.status,
    required this.updatedAt,
    this.routeProgress = 0,
  });

  final LatLng coordinate;
  final double distanceKm;
  final int estimatedArrivalMinutes;
  final RequestSearchStatus status;
  final DateTime updatedAt;
  final double routeProgress;

  // BACKEND INTEGRATION:
  // Map each approved live-location update into this small UI state. The
  // accepted-worker/job-tracking response remains the source of truth for the
  // coordinate, distance, ETA, status, route progress, and server update
  // timestamp. routeProgress is a normalized 0–1 value used to remove the
  // travelled portion of the route; the final routing/tracking integration
  // should calculate it against the production route geometry.

  bool get hasArrived => status.hasReachedService;

  WorkerTrackingUiState copyWith({
    LatLng? coordinate,
    double? distanceKm,
    int? estimatedArrivalMinutes,
    RequestSearchStatus? status,
    DateTime? updatedAt,
    double? routeProgress,
  }) {
    return WorkerTrackingUiState(
      coordinate: coordinate ?? this.coordinate,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      routeProgress: routeProgress ?? this.routeProgress,
    );
  }
}
