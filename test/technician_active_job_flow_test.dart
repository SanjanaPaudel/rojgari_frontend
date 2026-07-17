import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
import 'package:rojgari_frontend_one/models/technician/incoming_service_request_details.dart';
import 'package:rojgari_frontend_one/models/technician/technician_active_job_model.dart';
import 'package:rojgari_frontend_one/models/technician/technician_job_status.dart';
import 'package:rojgari_frontend_one/repositories/technician_job/mock_technician_job_repository.dart';
import 'package:rojgari_frontend_one/screens/technician/technician_active_job_screen.dart';
import 'package:rojgari_frontend_one/screens/technician/incoming_request_details_screen.dart';
import 'package:rojgari_frontend_one/screens/technician/technician_work_completed_screen.dart';
import 'package:rojgari_frontend_one/services/technician_job/technician_route_service.dart';

final _requestedAt = DateTime(2026, 7, 17, 20);
final _acceptedAt = DateTime(2026, 7, 17, 20, 8);

TechnicianActiveJobModel job({
  String categoryName = 'Plumbing Service',
  String categorySlug = 'plumbing',
  TechnicianJobStatus status = TechnicianJobStatus.accepted,
}) => TechnicianActiveJobModel(
  requestId: 'REQ-TECH-42',
  categoryId: '1',
  categoryName: categoryName,
  categorySlug: categorySlug,
  issueTitle: 'Kitchen pipe is leaking',
  fullProblemDescription: 'Water is dripping continuously.',
  customerId: 'customer-1',
  customerName: 'Ram Bahadur',
  customerAddress: 'Balkumari Road, Lalitpur',
  customerLatitude: 27.671234,
  customerLongitude: 85.339876,
  requestedAt: _requestedAt,
  acceptedAt: _acceptedAt,
  workStartedAt: status == TechnicianJobStatus.working
      ? DateTime(2026, 7, 17, 20, 25)
      : null,
  technicianLatitude: 27.6782,
  technicianLongitude: 85.3318,
  currentStatus: status,
);

Widget activeApp(TechnicianActiveJobModel value) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: TechnicianActiveJobScreen(
    job: value,
    repository: MockTechnicianJobRepository(delay: Duration.zero),
    routeService: const MockTechnicianRouteService(delay: Duration.zero),
    enableDemoFlow: false,
    showMapTiles: false,
  ),
);

void main() {
  test('backend status mapper supports the technician lifecycle', () {
    expect(
      TechnicianJobStatus.fromBackendValue('en_route'),
      TechnicianJobStatus.enRoute,
    );
    expect(
      TechnicianJobStatus.fromBackendValue('working'),
      TechnicianJobStatus.working,
    );
    expect(TechnicianJobStatus.completed.backendValue, 'completed');
  });

  testWidgets('active job renders dynamic request and category data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(activeApp(job()));
    await tester.pump();

    expect(find.text('Request ID: #REQ-TECH-42'), findsOneWidget);
    expect(find.text('Plumbing Service'), findsOneWidget);
    expect(find.text('Ram Bahadur'), findsOneWidget);
    expect(find.text('Balkumari Road, Lalitpur'), findsOneWidget);
    expect(find.byIcon(Icons.plumbing), findsOneWidget);
    expect(find.textContaining('Accepted at'), findsNothing);
    expect(find.textContaining('Work started at'), findsNothing);
    expect(
      find.byKey(const ValueKey('profile-call-customer-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chat-customer-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-customer-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('more-job-actions-button')),
      findsOneWidget,
    );
    expect(find.text('Work Done'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer actions stay clickable as integration placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(activeApp(job()));
    await tester.pump();

    final chat = find.byKey(const ValueKey('chat-customer-button'));
    await tester.ensureVisible(chat);
    await tester.tap(chat);
    await tester.pump();

    expect(
      find.text('Customer chat is ready for integration.'),
      findsOneWidget,
    );
  });

  testWidgets('technician navigation map opens and closes full screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.enRoute)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('technician-map-fullscreen')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('close-technician-fullscreen-map')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('close-technician-fullscreen-map')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('close-technician-fullscreen-map')),
      findsNothing,
    );
  });

  testWidgets('default mock Accept opens the active-job screen', (
    tester,
  ) async {
    const incoming = IncomingServiceRequestDetails(
      id: 'REQ-ACCEPT-1',
      customerName: 'Sita Rai',
      categoryId: '2',
      categoryName: 'Electrician Service',
      categorySlug: 'electrician',
      description: 'The bedroom socket is sparking.',
      locationText: 'Maitidevi, Kathmandu',
      latitude: 27.705,
      longitude: 85.342,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: IncomingRequestDetailsScreen(
          request: incoming,
          jobRepository: MockTechnicianJobRepository(delay: Duration.zero),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Active Service Job'), findsOneWidget);
    expect(find.text('Request ID: #REQ-ACCEPT-1'), findsOneWidget);
  });

  testWidgets('category icon and name change for electrician', (tester) async {
    await tester.pumpWidget(
      activeApp(
        job(categoryName: 'Electrician Service', categorySlug: 'electrician'),
      ),
    );
    await tester.pump();

    expect(find.text('Electrician Service'), findsOneWidget);
    expect(find.byIcon(Icons.electrical_services), findsOneWidget);
  });

  testWidgets('Work Done appears only while working', (tester) async {
    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.enRoute)),
    );
    await tester.pump();
    expect(find.text('Work Done'), findsNothing);

    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.working)),
    );
    await tester.pump();
    expect(find.text('Work Done'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('technician-working-status')),
      findsOneWidget,
    );
  });

  testWidgets('Working text types one character at a time without switching', (
    tester,
  ) async {
    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.working)),
    );
    await tester.pump();

    Text typingText() =>
        tester.widget<Text>(find.byKey(const ValueKey('working-typing-text')));

    expect(typingText().data, 'W');
    await tester.pump(const Duration(milliseconds: 180));
    expect(typingText().data, 'Wo');
    await tester.pump(const Duration(milliseconds: 180));
    expect(typingText().data, 'Wor');
  });

  testWidgets('backend status updates drive working and completion once', (
    tester,
  ) async {
    final status = ValueNotifier<TechnicianJobStatus>(
      TechnicianJobStatus.enRoute,
    );
    addTearDown(status.dispose);
    var completionBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicianActiveJobScreen(
          job: job(status: TechnicianJobStatus.enRoute),
          repository: MockTechnicianJobRepository(delay: Duration.zero),
          routeService: const MockTechnicianRouteService(delay: Duration.zero),
          statusListenable: status,
          enableDemoFlow: false,
          showMapTiles: false,
          completionScreenBuilder: (context, completedJob) {
            completionBuilds++;
            return const Scaffold(body: Text('Backend completed job'));
          },
        ),
      ),
    );
    await tester.pump();

    status.value = TechnicianJobStatus.working;
    await tester.pump();
    expect(find.text('Work Done'), findsOneWidget);

    status.value = TechnicianJobStatus.completed;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Backend completed job'), findsOneWidget);
    expect(completionBuilds, 1);
  });

  testWidgets('mock lifecycle advances through travel, arrival, and working', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicianActiveJobScreen(
          job: job(),
          repository: MockTechnicianJobRepository(delay: Duration.zero),
          routeService: const MockTechnicianRouteService(delay: Duration.zero),
          acceptedDisplayDuration: const Duration(milliseconds: 20),
          demoTravelDuration: const Duration(milliseconds: 80),
          demoLocationInterval: const Duration(milliseconds: 10),
          arrivedDisplayDuration: const Duration(milliseconds: 20),
          showMapTiles: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Accepted'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 21));
    expect(find.text('In Progress'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 81));
    expect(find.text('Arrived'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 21));
    expect(find.text('Working'), findsWidgets);
    expect(find.text('Work Done'), findsOneWidget);
  });

  testWidgets('No in completion dialog keeps the working screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.working)),
    );
    await tester.pump();
    final workDone = find.byKey(const ValueKey('work-done-button'));
    await tester.ensureVisible(workDone);
    await tester.tap(workDone);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Complete this work?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('keep-working-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Complete this work?'), findsNothing);
    expect(
      find.byKey(const ValueKey('technician-working-status')),
      findsOneWidget,
    );
  });

  testWidgets('Yes with mock success opens technician completion screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      activeApp(job(status: TechnicianJobStatus.working)),
    );
    await tester.pump();
    final workDone = find.byKey(const ValueKey('work-done-button'));
    await tester.ensureVisible(workDone);
    await tester.tap(workDone);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(
      find.byKey(const ValueKey('confirm-work-completed-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Your work is completed!'), findsOneWidget);
    expect(find.text('View My Bookings'), findsNothing);
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets('Back to Home gives visible frontend feedback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TechnicianWorkCompletedScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('technician-back-home-button')));
    await tester.pump();

    expect(
      find.text('Back to Technician Dashboard navigation is ready.'),
      findsOneWidget,
    );
  });
}
