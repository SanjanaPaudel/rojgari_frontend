// TEMP TEST-ONLY FILE — not part of the shipped app.
//
// Fakes the worker's GPS coordinate walking toward the customer's real
// service location, purely so this can be visually QA'd without physically
// moving a device there. Everything else stays real: the customer's search
// request, the worker's real accept action, and the real booking/job status
// on the backend are untouched by this file.
//
// Deliberately does NOT touch job/request status beyond reflecting
// "arrived" once the walk finishes — it never advances to working,
// completed, or triggers rate-your-experience navigation. Both consumers
// below only feed a coordinate into an existing extension point that the
// real screens already support (an injectable LocationService, and an
// external tracking listenable), so none of the screens' own
// enableDemoFlow auto-lifecycle timers are ever turned on.
//
// To remove: delete this file and the two call-sites that reference it —
//   - technician/incoming_request_details_loader.dart
//   - customer/service_request/finding_service_person_screen.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/service_request/request_search_status.dart';
import '../models/service_request/worker_tracking_ui_state.dart';
import '../services/location/location_service.dart';

/// Drop-in [LocationService] replacement for the worker's own active-job
/// screen (passed as its `locationService:` constructor argument). Instead
/// of reading the device/browser GPS, [getCurrentLocation] returns a
/// coordinate that walks linearly from [start] to [destination] over
/// [travelDuration], computed from wall-clock time elapsed since
/// construction — so it naturally lines up with the real screen's own
/// repeated polling of this method.
class FakeWorkerLocationService extends LocationService {
  FakeWorkerLocationService({
    required this.start,
    required this.destination,
    this.travelDuration = const Duration(seconds: 45),
  }) : _startedAt = DateTime.now();

  final LatLng start;
  final LatLng destination;
  final Duration travelDuration;
  final DateTime _startedAt;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.granted;

  @override
  Future<AppLocationPermission> requestPermission() async =>
      AppLocationPermission.granted;

  @override
  Future<CurrentDeviceLocation> getCurrentLocation() async {
    final progress = _progress();
    return CurrentDeviceLocation(
      latitude:
          start.latitude + (destination.latitude - start.latitude) * progress,
      longitude:
          start.longitude +
          (destination.longitude - start.longitude) * progress,
      accuracyMeters: 5,
    );
  }

  double _progress() {
    final totalMs = travelDuration.inMilliseconds;
    if (totalMs <= 0) return 1;
    final elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }
}

/// Drives a [WorkerTrackingUiState] notifier (passed as
/// [ServiceOnTheWayScreen]'s `trackingListenable:` constructor argument)
/// that walks the marker from [start] to [destination], then settles on
/// "arrived" and stops permanently. Supplying an external tracking
/// listenable is what makes the real screen disable its own location
/// polling and demo/auto-lifecycle timers, so this never advances the
/// visible status past "arrived".
class FakeWorkerTrackingController {
  FakeWorkerTrackingController({
    required LatLng start,
    required LatLng destination,
    this.travelDuration = const Duration(seconds: 45),
    Duration tickInterval = const Duration(milliseconds: 500),
  }) : _start = start,
       _destination = destination,
       _startedAt = DateTime.now(),
       notifier = ValueNotifier(
         WorkerTrackingUiState(
           coordinate: start,
           distanceKm: const Distance().as(
             LengthUnit.Kilometer,
             start,
             destination,
           ),
           estimatedArrivalMinutes: travelDuration.inMinutes.clamp(1, 999),
           status: RequestSearchStatus.workerOnTheWay,
           updatedAt: DateTime.now(),
         ),
       ) {
    _timer = Timer.periodic(tickInterval, _tick);
  }

  final LatLng _start;
  final LatLng _destination;
  final Duration travelDuration;
  final DateTime _startedAt;
  final ValueNotifier<WorkerTrackingUiState> notifier;
  late final Timer _timer;

  void _tick(Timer timer) {
    final totalMs = travelDuration.inMilliseconds;
    final elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    final progress = totalMs <= 0
        ? 1.0
        : (elapsedMs / totalMs).clamp(0.0, 1.0);
    final arrived = progress >= 1;
    final coordinate = arrived
        ? _destination
        : LatLng(
            _start.latitude +
                (_destination.latitude - _start.latitude) * progress,
            _start.longitude +
                (_destination.longitude - _start.longitude) * progress,
          );
    final distanceKm = arrived
        ? 0.0
        : const Distance().as(LengthUnit.Kilometer, coordinate, _destination);

    notifier.value = WorkerTrackingUiState(
      coordinate: coordinate,
      distanceKm: distanceKm,
      estimatedArrivalMinutes: arrived
          ? 0
          : ((1 - progress) * travelDuration.inMinutes).ceil().clamp(1, 999),
      status: arrived
          ? RequestSearchStatus.arrived
          : RequestSearchStatus.workerOnTheWay,
      updatedAt: DateTime.now(),
      routeProgress: progress,
    );

    if (arrived) timer.cancel();
  }

  void dispose() {
    _timer.cancel();
    notifier.dispose();
  }
}

/// Shared handoff point so TechnicianHomeScreen's always-on background
/// location timer can publish the SAME coordinate TechnicianActiveJobScreen's
/// map is showing, instead of the real device GPS, whenever a fake-walk test
/// session is active.
///
/// WHY this exists: TechnicianHomeScreen's location timer keeps running the
/// entire time the worker is online, completely independent of whichever
/// screen is on top — including TechnicianActiveJobScreen showing a fake
/// walk. Without this, the worker's own map shows a simulated journey while
/// the customer's map (fed by that always-real timer) shows wherever the
/// test device actually physically is — two unrelated data sources that
/// were never going to match.
///
/// TechnicianActiveJobScreen sets [current] in initState — only when it was
/// actually handed a [FakeWorkerLocationService] — and clears it in
/// dispose. TechnicianHomeScreen's timer checks this FIRST; when it's null
/// (the common case, and always true once
/// ServiceBookingDemoConfig.useFakeWorkerMovement is false, since that's the
/// only thing that ever causes a FakeWorkerLocationService to be created),
/// it falls through to real GPS, completely unaffected by any of this.
class ActiveFakeWorkerSession {
  ActiveFakeWorkerSession._();

  static FakeWorkerLocationService? current;
}
