import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/map_config.dart';
import '../../../models/service_request/accepted_worker_ui_model.dart';
import '../../../models/service_request/request_search_status.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/worker_tracking_ui_state.dart';

/// Deterministic frontend-only route used until production route geometry is
/// supplied by the tracking backend.
List<LatLng> buildDemoServiceTrackingRoute(LatLng worker, LatLng customer) {
  final latitudeDelta = customer.latitude - worker.latitude;
  final longitudeDelta = customer.longitude - worker.longitude;
  final perpendicularLatitude = -longitudeDelta;
  final perpendicularLongitude = latitudeDelta;

  LatLng routePoint(double progress, double bend) => LatLng(
    worker.latitude + latitudeDelta * progress + perpendicularLatitude * bend,
    worker.longitude +
        longitudeDelta * progress +
        perpendicularLongitude * bend,
  );

  return <LatLng>[
    worker,
    routePoint(.22, .08),
    routePoint(.48, -.05),
    routePoint(.73, .06),
    routePoint(.9, -.025),
    customer,
  ];
}

LatLng serviceTrackingCoordinateAt(List<LatLng> route, double progress) {
  final sample = _sampleRoute(route, progress);
  return sample.point;
}

List<LatLng> remainingServiceTrackingRoute(
  List<LatLng> route,
  double progress,
) {
  if (route.length < 2) return List<LatLng>.of(route);
  final sample = _sampleRoute(route, progress);
  return <LatLng>[sample.point, ...route.skip(sample.nextPointIndex)];
}

double serviceTrackingProgressForCoordinate(
  List<LatLng> route,
  LatLng coordinate,
) {
  if (route.length < 2) return 0;
  final segmentLengths = <double>[];
  var totalLength = 0.0;
  for (var index = 0; index < route.length - 1; index++) {
    final length = _coordinateDistance(route[index], route[index + 1]);
    segmentLengths.add(length);
    totalLength += length;
  }
  if (totalLength == 0) return 1;

  var bestDistanceSquared = double.infinity;
  var bestProgress = 0.0;
  var distanceBeforeSegment = 0.0;
  for (var index = 0; index < segmentLengths.length; index++) {
    final start = route[index];
    final end = route[index + 1];
    final latitudeDelta = end.latitude - start.latitude;
    final longitudeDelta = end.longitude - start.longitude;
    final segmentLengthSquared =
        latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta;
    final projection = segmentLengthSquared == 0
        ? 0.0
        : (((coordinate.latitude - start.latitude) * latitudeDelta +
                      (coordinate.longitude - start.longitude) *
                          longitudeDelta) /
                  segmentLengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();
    final projectedLatitude = start.latitude + latitudeDelta * projection;
    final projectedLongitude = start.longitude + longitudeDelta * projection;
    final latitudeError = coordinate.latitude - projectedLatitude;
    final longitudeError = coordinate.longitude - projectedLongitude;
    final distanceSquared =
        latitudeError * latitudeError + longitudeError * longitudeError;
    if (distanceSquared < bestDistanceSquared) {
      bestDistanceSquared = distanceSquared;
      bestProgress =
          (distanceBeforeSegment + segmentLengths[index] * projection) /
          totalLength;
    }
    distanceBeforeSegment += segmentLengths[index];
  }
  return bestProgress.clamp(0.0, 1.0).toDouble();
}

({LatLng point, int nextPointIndex}) _sampleRoute(
  List<LatLng> route,
  double progress,
) {
  if (route.isEmpty) {
    return (point: const LatLng(0, 0), nextPointIndex: 0);
  }
  if (route.length == 1) {
    return (point: route.first, nextPointIndex: 1);
  }

  final clampedProgress = progress.clamp(0.0, 1.0);
  final segmentLengths = <double>[];
  var totalLength = 0.0;
  for (var index = 0; index < route.length - 1; index++) {
    final length = _coordinateDistance(route[index], route[index + 1]);
    segmentLengths.add(length);
    totalLength += length;
  }
  if (totalLength == 0) {
    return (point: route.last, nextPointIndex: route.length);
  }

  final targetLength = totalLength * clampedProgress;
  var travelledLength = 0.0;
  for (var index = 0; index < segmentLengths.length; index++) {
    final segmentLength = segmentLengths[index];
    if (travelledLength + segmentLength >= targetLength) {
      final segmentProgress = segmentLength == 0
          ? 1.0
          : (targetLength - travelledLength) / segmentLength;
      final start = route[index];
      final end = route[index + 1];
      return (
        point: LatLng(
          start.latitude + (end.latitude - start.latitude) * segmentProgress,
          start.longitude + (end.longitude - start.longitude) * segmentProgress,
        ),
        nextPointIndex: index + 1,
      );
    }
    travelledLength += segmentLength;
  }
  return (point: route.last, nextPointIndex: route.length);
}

double _coordinateDistance(LatLng first, LatLng second) {
  final latitudeDelta = second.latitude - first.latitude;
  final longitudeDelta = second.longitude - first.longitude;
  return math.sqrt(
    latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta,
  );
}

class ServiceSearchMap extends StatefulWidget {
  const ServiceSearchMap({
    required this.location,
    this.workerCoordinates,
    this.height = 285,
    this.showFullscreenButton = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  });

  final SelectedServiceLocation location;
  final List<LatLng>? workerCoordinates;
  final double? height;
  final bool showFullscreenButton;
  final BorderRadius borderRadius;

  @override
  State<ServiceSearchMap> createState() => _ServiceSearchMapState();
}

class _ServiceSearchMapState extends State<ServiceSearchMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final List<LatLng> _workerCoordinates;

  LatLng get _customerCoordinate =>
      LatLng(widget.location.latitude, widget.location.longitude);

  @override
  void initState() {
    super.initState();
    _workerCoordinates = _resolveWorkerCoordinates();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<LatLng> _resolveWorkerCoordinates() {
    final supplied = widget.workerCoordinates;
    if (supplied != null && supplied.isNotEmpty) {
      return List<LatLng>.unmodifiable(supplied);
    }

    final center = _customerCoordinate;
    // BACKEND INTEGRATION:
    // Replace these temporary deterministic offsets with the latitude and
    // longitude of workers selected by the backend. The backend decides which
    // available workers may be shown; do not expose private worker data before
    // the backend explicitly allows it.
    return <LatLng>[
      LatLng(center.latitude + .0022, center.longitude - .0017),
      LatLng(center.latitude - .0018, center.longitude + .0021),
      LatLng(center.latitude + .0012, center.longitude + .0024),
    ];
  }

  void _openFullscreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenServiceSearchMap(
          location: widget.location,
          workerCoordinates: _workerCoordinates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _customerCoordinate,
                initialZoom: 15.5,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.openStreetMapTileUrl,
                  userAgentPackageName: MapConfig.userAgentPackageName,
                  maxZoom: 19,
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final progress = _pulseController.value;
                    return CircleLayer(
                      circles: List.generate(3, (index) {
                        final phase = (progress + index / 3) % 1;
                        return CircleMarker(
                          point: _customerCoordinate,
                          radius: 55 + (phase * 150),
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(
                            alpha: .18 * (1 - phase),
                          ),
                          borderColor: AppColors.secondary.withValues(
                            alpha: .34 * (1 - phase),
                          ),
                          borderStrokeWidth: 1.2,
                        );
                      }),
                    );
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _customerCoordinate,
                      width: 52,
                      height: 52,
                      child: const _CustomerMarker(),
                    ),
                    for (final coordinate in _workerCoordinates)
                      Marker(
                        point: coordinate,
                        width: 44,
                        height: 44,
                        child: const _WorkerMarker(),
                      ),
                  ],
                ),
              ],
            ),
            const Positioned(
              left: 8,
              bottom: 6,
              child: _OpenStreetMapAttribution(),
            ),
            if (widget.showFullscreenButton)
              Positioned(
                right: 12,
                bottom: 12,
                child: _MapActionButton(
                  tooltip: 'Open full-screen map',
                  icon: Icons.fullscreen_rounded,
                  onPressed: _openFullscreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ServiceTrackingMap extends StatelessWidget {
  const ServiceTrackingMap({
    required this.location,
    required this.worker,
    required this.trackingListenable,
    this.height = 300,
    this.showFullscreenButton = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  });

  final SelectedServiceLocation location;
  final AcceptedWorkerUiModel worker;
  final ValueListenable<WorkerTrackingUiState> trackingListenable;
  final double? height;
  final bool showFullscreenButton;
  final BorderRadius borderRadius;

  void _openFullscreen(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenServiceTrackingMap(
          location: location,
          worker: worker,
          trackingListenable: trackingListenable,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WorkerTrackingUiState>(
      valueListenable: trackingListenable,
      builder: (context, tracking, child) {
        final arrived = tracking.hasArrived;
        final customer = LatLng(location.latitude, location.longitude);
        final workerPoint = tracking.coordinate;
        final fullRoute = buildDemoServiceTrackingRoute(
          worker.coordinate,
          customer,
        );
        final remainingRoute = remainingServiceTrackingRoute(
          fullRoute,
          tracking.routeProgress,
        );

        return ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: customer,
                    initialZoom: 15.5,
                    minZoom: 3,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.openStreetMapTileUrl,
                      userAgentPackageName: MapConfig.userAgentPackageName,
                      maxZoom: 19,
                    ),
                    if (!arrived && remainingRoute.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: remainingRoute,
                            color: AppColors.primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: customer,
                          radius: 90,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: .13),
                          borderColor: AppColors.primary.withValues(alpha: .28),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customer,
                          width: 48,
                          height: 48,
                          child: const _CustomerMarker(),
                        ),
                        Marker(
                          point: workerPoint,
                          width: 48,
                          height: 48,
                          child: _TrackingWorkerMarker(
                            worker: worker,
                            tracking: tracking,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Positioned(
                  left: 8,
                  bottom: 6,
                  child: _OpenStreetMapAttribution(),
                ),
                if (showFullscreenButton)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _MapActionButton(
                      tooltip: 'Open full-screen map',
                      icon: Icons.fullscreen_rounded,
                      onPressed: () => _openFullscreen(context),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // BACKEND INTEGRATION:
  // Replace the temporary worker coordinate, distance, ETA, route progress,
  // and route geometry with values returned by the accepted-worker/job-
  // tracking API. Update these through the project's final polling, socket,
  // or live-location approach. The backend route should remain fixed while
  // the travelled section is trimmed behind the worker marker.
}

class _FullScreenServiceTrackingMap extends StatelessWidget {
  const _FullScreenServiceTrackingMap({
    required this.location,
    required this.worker,
    required this.trackingListenable,
  });

  final SelectedServiceLocation location;
  final AcceptedWorkerUiModel worker;
  final ValueListenable<WorkerTrackingUiState> trackingListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
        ),
        title: const Text(
          'Service tracking',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ServiceTrackingMap(
          location: location,
          worker: worker,
          trackingListenable: trackingListenable,
          height: null,
          showFullscreenButton: false,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _TrackingWorkerMarker extends StatelessWidget {
  const _TrackingWorkerMarker({required this.worker, required this.tracking});

  final AcceptedWorkerUiModel worker;
  final WorkerTrackingUiState tracking;

  @override
  Widget build(BuildContext context) {
    final arrived = tracking.hasArrived;
    final eta = tracking.estimatedArrivalMinutes;
    final statusLabel = switch (tracking.status) {
      RequestSearchStatus.working => 'Working',
      RequestSearchStatus.completed => 'Completed',
      RequestSearchStatus.arrived => 'Arrived',
      _ => eta != null ? '$eta min' : 'On the way',
    };
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _WorkerAvatar(worker: worker, size: 38),
        Positioned(
          left: 31,
          top: -8,
          child: Container(
            width: 68,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  maxLines: 1,
                  style: TextStyle(
                    color: arrived ? AppColors.green : AppColors.black,
                    fontSize: statusLabel == 'Completed' ? 8 : 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  arrived
                      ? '0 km'
                      : tracking.distanceKm != null
                      ? '${tracking.distanceKm!.toStringAsFixed(1)} km'
                      : '--',
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.grey, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({required this.worker, required this.size});

  final AcceptedWorkerUiModel worker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = worker.profileImageAsset?.trim();
    final network = worker.profileImageUrl?.trim();
    Widget fallback() =>
        const Icon(Icons.engineering_rounded, color: AppColors.primary);

    Widget child;
    // BACKEND INTEGRATION:
    // profileImageUrl is the dynamic accepted-worker image. The bundled asset
    // is demo-only, and the professional icon remains the safe null/error
    // fallback for workers without a profile photo.
    if (network != null && network.isNotEmpty) {
      child = Image.network(
        network,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      child = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      child = fallback();
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: child,
    );
  }
}

class _FullScreenServiceSearchMap extends StatelessWidget {
  const _FullScreenServiceSearchMap({
    required this.location,
    required this.workerCoordinates,
  });

  final SelectedServiceLocation location;
  final List<LatLng> workerCoordinates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
        ),
        title: const Text(
          'Nearby professionals',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ServiceSearchMap(
          location: location,
          workerCoordinates: workerCoordinates,
          height: null,
          showFullscreenButton: false,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _CustomerMarker extends StatelessWidget {
  const _CustomerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 27),
    );
  }
}

class _WorkerMarker extends StatelessWidget {
  const _WorkerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(
        Icons.engineering_rounded,
        color: AppColors.primary,
        size: 23,
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _OpenStreetMapAttribution extends StatelessWidget {
  const _OpenStreetMapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 9, color: Color(0xFF555266)),
        ),
      ),
    );
  }
}
