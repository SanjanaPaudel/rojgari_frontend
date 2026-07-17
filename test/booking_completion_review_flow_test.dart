import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/models/service_request/accepted_worker_ui_model.dart';
import 'package:rojgari_frontend_one/models/service_request/request_search_status.dart';
import 'package:rojgari_frontend_one/models/service_request/selected_service_location.dart';
import 'package:rojgari_frontend_one/models/service_request/service_category.dart';
import 'package:rojgari_frontend_one/models/service_request/service_review_payload.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/rate_your_experience_screen.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/review_thank_you_screen.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/service_on_the_way_screen.dart';
import 'package:rojgari_frontend_one/widgets/customer/service_request/horizontal_service_status_tracker.dart';

const _category = ServiceCategory(id: '2', name: 'Mechanic', slug: 'mechanic');
const _unknownCategory = ServiceCategory(
  id: 'future',
  name: 'Solar Installer',
  slug: 'solar-installer',
);
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
  profileDescription: 'Careful professional for everyday repairs.',
  distanceKm: 1.2,
  estimatedArrivalMinutes: 2,
);

void main() {
  testWidgets('working tracker fills through Working without narrow overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 290,
              child: HorizontalServiceStatusTracker(
                status: RequestSearchStatus.working,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('status-line-3')))
          .color,
      AppColors.primary,
    );
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('status-line-4')))
          .color,
      AppColors.lightPurple,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'accepted, on the way, arrived, and completed tracker states work',
    (tester) async {
      for (final status in <RequestSearchStatus>[
        RequestSearchStatus.accepted,
        RequestSearchStatus.workerOnTheWay,
        RequestSearchStatus.arrived,
        RequestSearchStatus.completed,
      ]) {
        await tester.pumpWidget(
          MaterialApp(home: HorizontalServiceStatusTracker(status: status)),
        );
        expect(
          find.byKey(const ValueKey('horizontal-service-status-tracker')),
          findsOneWidget,
        );
      }
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
    },
  );

  testWidgets('arrived advances to working, completed, and rating once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var ratingNavigationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ServiceOnTheWayScreen(
          requestId: 'REQ-LIFECYCLE',
          category: _category,
          serviceLocation: _location,
          requestDescription: 'Dynamic request.',
          requestedAt: DateTime.now(),
          worker: _worker,
          initialStatus: RequestSearchStatus.arrived,
          arrivedAcknowledgementDuration: const Duration(milliseconds: 50),
          workingPreviewDuration: const Duration(milliseconds: 100),
          completedDisplayDuration: const Duration(milliseconds: 50),
          onRatingNavigation: () => ratingNavigationCalls++,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('arrival-status-card')), findsNothing);
    expect(
      find.byKey(const ValueKey('horizontal-service-status-tracker')),
      findsOneWidget,
    );
    expect(find.text('Arrived'), findsWidgets);
    final cancelAction = find.descendant(
      of: find.byKey(const ValueKey('tracking-cancel-button')),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(cancelAction).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 51));
    expect(find.text('Working'), findsWidgets);
    expect(tester.widget<OutlinedButton>(cancelAction).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text('Completed'), findsWidgets);
    expect(tester.widget<OutlinedButton>(cancelAction).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 51));
    expect(ratingNavigationCalls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(ratingNavigationCalls, 1);
  });

  testWidgets('rating page is dynamic and submit starts disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RateYourExperienceScreen(
          requestId: 'REQ-RATE',
          category: _unknownCategory,
          worker: _worker,
          enableDemoSubmission: false,
        ),
      ),
    );

    expect(find.text('Aarav Sharma'), findsOneWidget);
    expect(find.text('Solar Installer'), findsOneWidget);
    expect(find.text('Support'), findsNothing);
    expect(find.text('Skip for Now'), findsNothing);
    expect(find.byKey(const ValueKey('review-worker-avatar')), findsOneWidget);
    final submit = find.byKey(const ValueKey('submit-review-button'));
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('rating-star-4')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Great!'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
  });

  testWidgets('optional empty review submits once and opens Thank You', (
    tester,
  ) async {
    ServiceReviewPayload? submittedPayload;
    var submissionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RateYourExperienceScreen(
          requestId: 'REQ-SUCCESS',
          category: _category,
          worker: _worker,
          onSubmitReview: (payload) async {
            submissionCalls++;
            submittedPayload = payload;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('rating-star-5')));
    await tester.pump();
    final submit = find.byKey(const ValueKey('submit-review-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submissionCalls, 1);
    expect(submittedPayload?.rating, 5);
    expect(submittedPayload?.reviewText, isNull);
    expect(submittedPayload?.requestId, 'REQ-SUCCESS');
    expect(find.text('Thank You!'), findsOneWidget);
    expect(find.text('View My Bookings'), findsNothing);
    expect(find.byKey(const ValueKey('review-confetti')), findsOneWidget);
  });

  testWidgets('review failure stays on rating page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RateYourExperienceScreen(
          requestId: 'REQ-FAIL',
          category: _category,
          worker: _worker,
          onSubmitReview: (_) async => false,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('rating-star-2')));
    await tester.pump();
    final submit = find.byKey(const ValueKey('submit-review-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Rate Your Experience'), findsOneWidget);
    expect(find.text('Thank You!'), findsNothing);
    expect(
      find.text('Could not submit your review. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('rapid review taps submit only once', (tester) async {
    final response = Completer<bool>();
    var submissionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RateYourExperienceScreen(
          requestId: 'REQ-ONCE',
          category: _category,
          worker: _worker,
          onSubmitReview: (_) {
            submissionCalls++;
            return response.future;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('rating-star-3')));
    await tester.pump();
    final submit = find.byKey(const ValueKey('submit-review-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit, warnIfMissed: false);
    expect(submissionCalls, 1);

    response.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Thank You!'), findsOneWidget);
  });

  testWidgets('Thank You home and system back invoke dashboard callback once', (
    tester,
  ) async {
    var homeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(home: ReviewThankYouScreen(onBackToHome: () => homeCalls++)),
    );

    expect(find.text('Thank You!'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
    expect(find.text('View My Bookings'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('back-to-home-button')));
    await tester.tap(find.byKey(const ValueKey('back-to-home-button')));
    expect(homeCalls, 1);

    homeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewThankYouScreen(
          key: const ValueKey('system-back-thank-you'),
          onBackToHome: () => homeCalls++,
        ),
      ),
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(homeCalls, 1);
  });
}
