import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TechnicianRouteException implements Exception {
  const TechnicianRouteException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TechnicianRouteResult {
  const TechnicianRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isFallback = false,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isFallback;
}

abstract class TechnicianRouteService {
  Future<TechnicianRouteResult> getRoute({
    required LatLng technician,
    required LatLng customer,
  });

  void dispose() {}
}

class MockTechnicianRouteService implements TechnicianRouteService {
  const MockTechnicianRouteService({
    this.delay = const Duration(milliseconds: 180),
  });

  final Duration delay;

  @override
  Future<TechnicianRouteResult> getRoute({
    required LatLng technician,
    required LatLng customer,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final points = buildTechnicianDemoRoute(technician, customer);
    final distance = routeDistanceMeters(points);
    return TechnicianRouteResult(
      points: points,
      distanceMeters: distance,
      durationSeconds: math.max(60, distance / 6.5),
      isFallback: true,
    );
  }

  @override
  void dispose() {}
}

class OsrmTechnicianRouteService implements TechnicianRouteService {
  OsrmTechnicianRouteService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'OSRM_BASE_URL',
      defaultValue: 'https://router.project-osrm.org',
    ),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;

  @override
  Future<TechnicianRouteResult> getRoute({
    required LatLng technician,
    required LatLng customer,
  }) async {
    // OSRM expects longitude,latitude even though LatLng stores
    // latitude,longitude. Keep this ordering when the backend route is added.
    final coordinates =
        '${technician.longitude},${technician.latitude};'
        '${customer.longitude},${customer.latitude}';
    final uri = Uri.parse('$baseUrl/route/v1/driving/$coordinates').replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    // BACKEND INTEGRATION:
    // The public OSRM endpoint is suitable only for development and must not
    // be treated as Rojgari production infrastructure. Prefer proxying routing
    // through the approved backend, with rate limits and failure handling.
    try {
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'Rojgari/1.0 (technician-route-preview)',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const TechnicianRouteException(
          'Directions are temporarily unavailable.',
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw const TechnicianRouteException('No route was found.');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) {
        throw const TechnicianRouteException('Route geometry is unavailable.');
      }
      final points = coordinates
          .map((coordinate) {
            final pair = coordinate as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          })
          .toList(growable: false);
      return TechnicianRouteResult(
        points: points,
        distanceMeters:
            (route['distance'] as num?)?.toDouble() ??
            routeDistanceMeters(points),
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } on TechnicianRouteException {
      rethrow;
    } catch (_) {
      throw const TechnicianRouteException(
        'Directions are temporarily unavailable.',
      );
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

List<LatLng> buildTechnicianDemoRoute(LatLng technician, LatLng customer) {
  final latitudeDelta = customer.latitude - technician.latitude;
  final longitudeDelta = customer.longitude - technician.longitude;
  final perpendicularLatitude = -longitudeDelta;
  final perpendicularLongitude = latitudeDelta;

  LatLng point(double progress, double bend) => LatLng(
    technician.latitude +
        latitudeDelta * progress +
        perpendicularLatitude * bend,
    technician.longitude +
        longitudeDelta * progress +
        perpendicularLongitude * bend,
  );

  return [
    technician,
    point(.24, .08),
    point(.48, -.045),
    point(.72, .055),
    point(.9, -.02),
    customer,
  ];
}

double routeDistanceMeters(List<LatLng> points) {
  if (points.length < 2) return 0;
  const distance = Distance();
  var total = 0.0;
  for (var index = 0; index < points.length - 1; index++) {
    total += distance.as(LengthUnit.Meter, points[index], points[index + 1]);
  }
  return total;
}

LatLng technicianRoutePointAt(List<LatLng> route, double progress) {
  final sample = _sampleRoute(route, progress);
  return sample.point;
}

List<LatLng> remainingTechnicianRoute(List<LatLng> route, double progress) {
  if (route.length < 2) return List.of(route);
  final sample = _sampleRoute(route, progress);
  return [sample.point, ...route.skip(sample.nextPointIndex)];
}

({LatLng point, int nextPointIndex}) _sampleRoute(
  List<LatLng> route,
  double progress,
) {
  if (route.isEmpty) return (point: const LatLng(0, 0), nextPointIndex: 0);
  if (route.length == 1) return (point: route.first, nextPointIndex: 1);
  final lengths = <double>[];
  var total = 0.0;
  const distance = Distance();
  for (var index = 0; index < route.length - 1; index++) {
    final length = distance.as(
      LengthUnit.Meter,
      route[index],
      route[index + 1],
    );
    lengths.add(length);
    total += length;
  }
  if (total == 0) return (point: route.last, nextPointIndex: route.length);
  final target = total * progress.clamp(0.0, 1.0);
  var travelled = 0.0;
  for (var index = 0; index < lengths.length; index++) {
    if (travelled + lengths[index] >= target) {
      final segmentProgress = lengths[index] == 0
          ? 1.0
          : (target - travelled) / lengths[index];
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
    travelled += lengths[index];
  }
  return (point: route.last, nextPointIndex: route.length);
}
