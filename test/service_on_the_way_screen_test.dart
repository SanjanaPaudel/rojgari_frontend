import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rojgari_frontend_one/models/service_request/accepted_worker_ui_model.dart';
import 'package:rojgari_frontend_one/models/service_request/request_search_status.dart';
import 'package:rojgari_frontend_one/models/service_request/selected_service_location.dart';
import 'package:rojgari_frontend_one/models/service_request/service_category.dart';
import 'package:rojgari_frontend_one/models/service_request/worker_tracking_ui_state.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/service_on_the_way_screen.dart';
import 'package:rojgari_frontend_one/widgets/customer/service_request/service_search_map.dart';

const _category = ServiceCategory(id: '2', name: 'Mechanic', slug: 'mechanic');
const _location = SelectedServiceLocation(
  latitude: 27.671234,
  longitude: 85.339876,
  landmark: 'Balkumari Road, Lalitpur',
);
const _worker = AcceptedWorkerUiModel(
  id: 'worker-1',
  name: 'Aarav Sharma',
  latitude: 27.673634,
  longitude: 85.338076,
  rating: 4.7,
  completedJobs: 167,
  profileDescription: 'Careful mechanic for everyday repairs.',
  distanceKm: 1.2,
  estimatedArrivalMinutes: 2,
);

void main() {
  test('tracking route trims travelled points from the worker position', () {
    const start = LatLng(27.673634, 85.338076);
    const customer = LatLng(27.671234, 85.339876);
    final route = buildDemoServiceTrackingRoute(start, customer);
    final workerPosition = serviceTrackingCoordinateAt(route, .6);
    final remaining = remainingServiceTrackingRoute(route, .6);

    expect(remaining.length, lessThan(route.length));
    expect(remaining.first.latitude, closeTo(workerPosition.latitude, 1e-10));
    expect(remaining.first.longitude, closeTo(workerPosition.longitude, 1e-10));
    expect(remaining.last.latitude, customer.latitude);
    expect(remaining.last.longitude, customer.longitude);
  });

  testWidgets('worker rating and description render without a jobs count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkerInformationCard(worker: _worker, onCall: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('167 jobs'), findsNothing);
    expect(find.text('Careful mechanic for everyday repairs.'), findsOneWidget);
  });

  testWidgets('approaching screen transitions to arrived and disables cancel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ServiceOnTheWayScreen(
          requestId: 'REQ-91',
          category: _category,
          serviceLocation: _location,
          requestDescription: 'The motorcycle will not start.',
          requestedAt: DateTime.now(),
          worker: _worker,
          demoArrivalDuration: const Duration(milliseconds: 100),
          demoTrackingInterval: const Duration(milliseconds: 20),
          enableLocationPolling: false,
        ),
      ),
    );

    expect(find.text('Service on the Way'), findsOneWidget);
    expect(find.text('Mechanic Service'), findsOneWidget);
    expect(find.text('Arriving in'), findsOneWidget);
    expect(find.text('2 min (1.2 km away)'), findsOneWidget);
    expect(find.text('Issue'), findsNothing);
    expect(find.text('The motorcycle will not start.'), findsNothing);
    expect(find.text('More'), findsNothing);
    expect(find.text('Share Live Location'), findsNothing);
    expect(find.textContaining('MOTOR-BIKE'), findsNothing);
    final requestStatusBadge = find.byKey(
      const ValueKey('tracking-request-status-badge'),
    );
    expect(
      find.descendant(
        of: requestStatusBadge,
        matching: find.text('In Progress'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('2 min (1.0 km away)'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 81));
    expect(find.text('Arrived'), findsWidgets);
    expect(find.text('0 km'), findsWidgets);
    expect(
      find.byKey(const ValueKey('horizontal-service-status-tracker')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('arrival-status-card')), findsNothing);
    expect(
      find.descendant(of: requestStatusBadge, matching: find.text('Arrived')),
      findsOneWidget,
    );

    await tester.dragFrom(const Offset(10, 850), const Offset(0, -700));
    await tester.pump();
    final cancelAction = find.descendant(
      of: find.byKey(const ValueKey('tracking-cancel-button')),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(cancelAction).onPressed, isNull);
  });

  testWidgets('chat and call actions use their shared handlers', (
    tester,
  ) async {
    var chatCalls = 0;
    var phoneCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingActionButtons(
            cancelEnabled: true,
            onChat: () => chatCalls++,
            onCall: () => phoneCalls++,
            onCancel: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Chat'));
    await tester.tap(find.text('Call'));
    expect(chatCalls, 1);
    expect(phoneCalls, 1);
  });

  testWidgets('cancel dialog keeps tracking or pops after confirmed cancel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-tracking'),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceOnTheWayScreen(
                      requestId: 'REQ-CANCEL',
                      category: _category,
                      serviceLocation: _location,
                      requestDescription: 'Preserve this draft.',
                      requestedAt: DateTime.now(),
                      worker: _worker,
                      enableDemoFlow: false,
                      enableLocationPolling: false,
                    ),
                  ),
                ),
                child: const Text('Open tracking'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-tracking')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Request'), findsOneWidget);
    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep Tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Service on the Way'), findsOneWidget);

    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    final confirmCancellation = find.byKey(
      const ValueKey('confirm-tracking-cancellation'),
    );
    expect(
      tester.widget<OutlinedButton>(confirmCancellation).onPressed,
      isNotNull,
    );
    await tester.tap(confirmCancellation);
    await tester.pumpAndSettle();
    expect(find.text('Service on the Way'), findsNothing);
    expect(find.byKey(const ValueKey('open-tracking')), findsOneWidget);
  });

  testWidgets('confirmed cancel never pops the only route to a blank page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ServiceOnTheWayScreen(
          requestId: 'REQ-PREVIEW',
          category: _category,
          serviceLocation: _location,
          requestDescription: 'Preview request.',
          requestedAt: DateTime.now(),
          worker: _worker,
          enableDemoFlow: false,
          enableLocationPolling: false,
        ),
      ),
    );

    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-tracking-cancellation')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Service on the Way'), findsOneWidget);
    expect(
      find.text(
        'Cancellation confirmed. Return navigation will be connected here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('external live tracking updates distance, ETA, and arrival', (
    tester,
  ) async {
    final tracking = ValueNotifier(
      WorkerTrackingUiState(
        coordinate: _worker.coordinate,
        distanceKm: 1.2,
        estimatedArrivalMinutes: 2,
        status: RequestSearchStatus.workerOnTheWay,
        updatedAt: DateTime.now(),
      ),
    );
    addTearDown(tracking.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ServiceOnTheWayScreen(
          requestId: 'REQ-LIVE',
          category: _category,
          serviceLocation: _location,
          requestDescription: 'Not rendered on this page.',
          requestedAt: DateTime.now(),
          worker: _worker,
          trackingListenable: tracking,
          enableDemoFlow: false,
          trackingSnapshotInterpolationDuration: const Duration(
            milliseconds: 100,
          ),
        ),
      ),
    );

    tracking.value = WorkerTrackingUiState(
      coordinate: const LatLng(27.6722, 85.3391),
      distanceKm: .6,
      estimatedArrivalMinutes: 1,
      status: RequestSearchStatus.workerOnTheWay,
      updatedAt: DateTime.now(),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('2 min (0.9 km away)'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 51));
    expect(find.text('1 min (0.6 km away)'), findsOneWidget);

    tracking.value = WorkerTrackingUiState(
      coordinate: LatLng(_location.latitude, _location.longitude),
      distanceKm: 0,
      estimatedArrivalMinutes: 0,
      status: RequestSearchStatus.arrived,
      updatedAt: DateTime.now(),
    );
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text('Arrived'), findsWidgets);
    expect(find.text('0 km'), findsWidgets);
    expect(
      find.byKey(const ValueKey('horizontal-service-status-tracker')),
      findsOneWidget,
    );
  });

  testWidgets('tracking fullscreen map opens and closes', (tester) async {
    final tracking = ValueNotifier(
      WorkerTrackingUiState(
        coordinate: _worker.coordinate,
        distanceKm: 1.2,
        estimatedArrivalMinutes: 2,
        status: RequestSearchStatus.workerOnTheWay,
        updatedAt: DateTime.now(),
      ),
    );
    addTearDown(tracking.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceTrackingMap(
            location: _location,
            worker: _worker,
            trackingListenable: tracking,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open full-screen map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Service tracking'), findsOneWidget);

    tracking.value = WorkerTrackingUiState(
      coordinate: LatLng(_location.latitude, _location.longitude),
      distanceKm: 0,
      estimatedArrivalMinutes: 0,
      status: RequestSearchStatus.working,
      updatedAt: DateTime.now(),
    );
    await tester.pump();
    expect(find.text('Working'), findsWidgets);

    tracking.value = tracking.value.copyWith(
      status: RequestSearchStatus.completed,
      updatedAt: DateTime.now(),
    );
    await tester.pump();
    expect(find.text('Completed'), findsWidgets);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Service tracking'), findsNothing);
  });
}
