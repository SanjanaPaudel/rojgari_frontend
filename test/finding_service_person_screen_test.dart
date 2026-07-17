import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rojgari_frontend_one/models/service_request/request_search_status.dart';
import 'package:rojgari_frontend_one/models/service_request/selected_service_location.dart';
import 'package:rojgari_frontend_one/models/service_request/service_category.dart';
import 'package:rojgari_frontend_one/models/service_request/service_category_presentation.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/finding_service_person_preview.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/finding_service_person_screen.dart';
import 'package:rojgari_frontend_one/widgets/customer/service_request/service_search_map.dart';

const _plumber = ServiceCategory(id: '1', name: 'Plumber', slug: 'plumber');
const _location = SelectedServiceLocation(
  latitude: 27.671234,
  longitude: 85.339876,
  landmark: 'Balkumari Road, Lalitpur',
);

void main() {
  test(
    'category presentation uses dynamic labels and a safe icon fallback',
    () {
      const mechanic = ServiceCategory(
        id: '2',
        name: 'Mechanic',
        slug: 'mechanic',
      );
      const maid = ServiceCategory(id: '3', name: 'Maid', slug: 'maid');
      const future = ServiceCategory(
        id: '99',
        name: 'Solar Installer',
        slug: 'solar-installer',
      );

      expect(
        ServiceCategoryPresentation.issueLabelFor(_plumber),
        'Plumbing Issue',
      );
      expect(
        ServiceCategoryPresentation.issueLabelFor(mechanic),
        'Mechanic Issue',
      );
      expect(ServiceCategoryPresentation.issueLabelFor(maid), 'Cleaning Issue');
      expect(
        ServiceCategoryPresentation.issueLabelFor(future),
        'Solar Installer Issue',
      );
      expect(
        ServiceCategoryPresentation.iconFor(future.slug),
        Icons.home_repair_service_outlined,
      );
    },
  );

  testWidgets('searching status displays the animated searching label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedSearchingText(status: RequestSearchStatus.searching),
        ),
      ),
    );

    final statusFinder = find.byKey(const ValueKey('search-status-text'));
    final firstFrame = tester.widget<Text>(statusFinder).data!;
    expect(firstFrame, 'S');
    await tester.pump(const Duration(milliseconds: 400));
    final laterFrame = tester.widget<Text>(statusFinder).data!;
    expect(laterFrame.startsWith(firstFrame), isTrue);
    expect(laterFrame.length, greaterThan(firstFrame.length));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.widget<Text>(statusFinder).data, 'Searching...');
  });

  testWidgets('debug preview opens the searching screen directly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: FindingServicePersonPreview()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Finding Service Person'), findsOneWidget);
    expect(find.text('Plumber Service'), findsOneWidget);
    expect(find.text('Request ID: #PREVIEW-001'), findsOneWidget);
    expect(
      find.text('We\'re finding the best professional for you'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('search-status-text')))
          .data,
      startsWith('S'),
    );
    expect(find.text('Learn More'), findsOneWidget);

    await tester.tap(find.text('Learn More'));
    await tester.pump();
    expect(
      find.text('Professional verification details coming soon.'),
      findsWidgets,
    );
  });

  testWidgets(
    'search map shows three stable worker markers and opens full screen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ServiceSearchMap(location: _location)),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.engineering_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);

      await tester.tap(find.byTooltip('Open full-screen map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Nearby professionals'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ServiceSearchMap).last,
          matching: find.byIcon(Icons.engineering_rounded),
        ),
        findsNWidgets(3),
      );

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Nearby professionals'), findsNothing);
    },
  );

  testWidgets('found status invokes the worker-found callback only once', (
    tester,
  ) async {
    final status = ValueNotifier(RequestSearchStatus.searching);
    addTearDown(status.dispose);
    var callbackCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FindingServicePersonScreen(
          requestId: 'REQ-21',
          category: _plumber,
          serviceLocation: _location,
          requestDescription: 'Kitchen sink is leaking.',
          requestedAt: DateTime.now(),
          statusListenable: status,
          acceptedDisplayDuration: Duration.zero,
          onWorkerFound: () => callbackCount++,
        ),
      ),
    );
    await tester.pump();

    status.value = RequestSearchStatus.accepted;
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Accepted...'), findsOneWidget);
    expect(callbackCount, 1);

    status.value = RequestSearchStatus.searching;
    await tester.pump();
    status.value = RequestSearchStatus.accepted;
    await tester.pump();
    expect(callbackCount, 1);
  });

  testWidgets('demo search accepts and navigates only once', (tester) async {
    var callbackCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FindingServicePersonScreen(
          requestId: 'REQ-DEMO',
          category: _plumber,
          serviceLocation: _location,
          requestDescription: 'Kitchen sink is leaking.',
          requestedAt: DateTime.now(),
          demoSearchDuration: const Duration(milliseconds: 100),
          acceptedDisplayDuration: const Duration(milliseconds: 100),
          onWorkerFound: () => callbackCount++,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Accepted...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(callbackCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(callbackCount, 1);
  });

  testWidgets('demo accepted state opens Service on the Way automatically', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FindingServicePersonScreen(
          requestId: 'REQ-FLOW',
          category: _plumber,
          serviceLocation: _location,
          requestDescription: 'Kitchen sink is leaking.',
          requestedAt: DateTime.now(),
          demoSearchDuration: const Duration(milliseconds: 100),
          acceptedDisplayDuration: const Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Accepted...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Service on the Way'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
  });

  testWidgets('cancellation dialog keeps searching or confirms cancellation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var cancellationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FindingServicePersonScreen(
                      requestId: 'REQ-22',
                      category: _plumber,
                      serviceLocation: _location,
                      requestDescription: 'Kitchen sink is leaking.',
                      requestedAt: DateTime.now(),
                      onCancelRequested: () async {
                        cancellationCalls++;
                        return true;
                      },
                    ),
                  ),
                ),
                child: const Text('Open finding screen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open finding screen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(scrollable);
    scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cancel-request-button')));
    await tester.pump();
    expect(find.text('Cancel service request?'), findsOneWidget);

    await tester.tap(find.text('Keep Searching'));
    await tester.pump();
    expect(find.text('Cancel service request?'), findsNothing);
    expect(cancellationCalls, 0);

    await tester.tap(find.byKey(const ValueKey('cancel-request-button')));
    await tester.pump();
    await tester.tap(find.text('Yes, Cancel Request'));
    await tester.pumpAndSettle();
    expect(cancellationCalls, 1);
    expect(find.text('Open finding screen'), findsOneWidget);
  });

  testWidgets('request details renders selected address and safe fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RequestDetailsCard(
                location: _location,
                requestedAt: DateTime.now(),
              ),
              RequestDetailsCard(
                location: const SelectedServiceLocation(
                  latitude: 27.7,
                  longitude: 85.3,
                ),
                requestedAt: DateTime.now(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Balkumari Road, Lalitpur'), findsOneWidget);
    expect(find.text('Selected service location'), findsOneWidget);
    expect(find.text('Requested just now'), findsNWidgets(2));
  });
}
