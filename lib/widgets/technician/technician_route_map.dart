import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';
import '../../models/technician/technician_job_status.dart';

class TechnicianRouteMap extends StatefulWidget {
  const TechnicianRouteMap({
    required this.technician,
    required this.customer,
    required this.routePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.status,
    this.height = 300,
    this.showTiles = true,
    this.borderRadius,
    this.showFullScreenButton = true,
    this.onFullScreen,
    super.key,
  });

  final LatLng technician;
  final LatLng customer;
  final List<LatLng> routePoints;
  final double distanceMeters;
  final double durationSeconds;
  final TechnicianJobStatus status;
  final double height;
  final bool showTiles;
  final BorderRadius? borderRadius;
  final bool showFullScreenButton;
  final VoidCallback? onFullScreen;

  @override
  State<TechnicianRouteMap> createState() => _TechnicianRouteMapState();
}

class _TechnicianRouteMapState extends State<TechnicianRouteMap> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _followTechnician = true;
  bool _ignoreProgrammaticMove = false;

  @override
  void didUpdateWidget(covariant TechnicianRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapReady &&
        _followTechnician &&
        oldWidget.technician != widget.technician) {
      _followDriver();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _followDriver() {
    if (!_mapReady) return;
    _ignoreProgrammaticMove = true;
    _mapController.moveAndRotate(
      widget.technician,
      math.max(16.2, _mapController.camera.zoom),
      -_routeBearingDegrees(),
    );
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (_ignoreProgrammaticMove) {
      _ignoreProgrammaticMove = false;
      return;
    }
    if (hasGesture && _followTechnician && mounted) {
      setState(() => _followTechnician = false);
    }
  }

  void _resumeNavigation() {
    setState(() => _followTechnician = true);
    _followDriver();
  }

  double _routeBearingDegrees() {
    var target = widget.customer;
    const distance = Distance();
    for (final point in widget.routePoints) {
      if (distance.as(LengthUnit.Meter, widget.technician, point) > 4) {
        target = point;
        break;
      }
    }
    final startLatitude = widget.technician.latitude * math.pi / 180;
    final targetLatitude = target.latitude * math.pi / 180;
    final longitudeDelta =
        (target.longitude - widget.technician.longitude) * math.pi / 180;
    final y = math.sin(longitudeDelta) * math.cos(targetLatitude);
    final x =
        math.cos(startLatitude) * math.sin(targetLatitude) -
        math.sin(startLatitude) *
            math.cos(targetLatitude) *
            math.cos(longitudeDelta);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.technician,
                initialZoom: 14.5,
                minZoom: 3,
                maxZoom: 19,
                onMapReady: () {
                  _mapReady = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _followDriver();
                  });
                },
                onPositionChanged: _onPositionChanged,
              ),
              children: [
                if (widget.showTiles)
                  TileLayer(
                    urlTemplate: MapConfig.openStreetMapTileUrl,
                    userAgentPackageName: MapConfig.userAgentPackageName,
                    maxZoom: 19,
                  ),
                if (widget.routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        color: Colors.white.withValues(alpha: .92),
                        strokeWidth: 8,
                      ),
                      Polyline(
                        points: widget.routePoints,
                        color: AppColors.primary,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.customer,
                      width: 48,
                      height: 48,
                      child: const _DestinationMarker(),
                    ),
                    Marker(
                      point: widget.technician,
                      width: 48,
                      height: 48,
                      child: _TechnicianMarker(
                        headingDegrees: _routeBearingDegrees(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _NavigationInstructionCard(
                status: widget.status,
                distanceMeters: widget.distanceMeters,
                durationSeconds: widget.durationSeconds,
                followPaused: !_followTechnician,
                onResume: _resumeNavigation,
              ),
            ),
            if (widget.showTiles)
              const Positioned(left: 8, bottom: 6, child: _MapAttribution()),
            if (widget.showFullScreenButton)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    key: const ValueKey('technician-map-fullscreen'),
                    tooltip: 'Open full screen navigation',
                    onPressed: widget.onFullScreen,
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationInstructionCard extends StatelessWidget {
  const _NavigationInstructionCard({
    required this.status,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.followPaused,
    required this.onResume,
  });

  final TechnicianJobStatus status;
  final double distanceMeters;
  final double durationSeconds;
  final bool followPaused;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final arrived = status.index >= TechnicianJobStatus.arrived.index;
    final minutes = (durationSeconds / 60).ceil().clamp(1, 999);
    final distance = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    // BACKEND INTEGRATION:
    // Replace this generic navigation message with the next maneuver, road
    // name, and maneuver distance returned by the approved directions service.
    // Keep route steps and rerouting in the route layer, not in this widget.
    final instruction = switch (status) {
      TechnicianJobStatus.accepted => 'Route ready to customer',
      TechnicianJobStatus.enRoute => 'Continue on highlighted route',
      TechnicianJobStatus.arrived => 'You have arrived',
      TechnicianJobStatus.working => 'At customer location',
      TechnicianJobStatus.completed => 'Service completed',
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('technician-navigation-instruction'),
        onTap: followPaused ? onResume : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: arrived ? AppColors.green : AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  arrived ? Icons.check_rounded : Icons.navigation_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      followPaused ? 'Tap to resume navigation' : instruction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      arrived
                          ? 'Customer destination reached'
                          : '$distance remaining • about $minutes min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!arrived) ...[
                const SizedBox(width: 8),
                Text(
                  '$minutes min',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicianMarker extends StatelessWidget {
  const _TechnicianMarker({required this.headingDegrees});

  final double headingDegrees;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('technician-map-marker'),
    decoration: BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
    ),
    child: Transform.rotate(
      angle: headingDegrees * math.pi / 180,
      child: const Icon(
        Icons.navigation_rounded,
        color: Colors.white,
        size: 25,
      ),
    ),
  );
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('customer-destination-marker'),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.primary, width: 2.5),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
    ),
    child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 25),
  );
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
