import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
import 'package:rojgari_frontend_one/models/technician/incoming_service_request_details.dart';
import 'package:rojgari_frontend_one/screens/technician/incoming_request_details_screen.dart';

const request = IncomingServiceRequestDetails(
  id: 'request-42',
  customerName: 'Ram Bahadur',
  categoryId: '1',
  categoryName: 'Plumbing Service',
  categorySlug: 'plumbing',
  description: '  Kitchen   pipe is leaking under the sink continuously. ',
  locationText: 'Lazimpat, Kathmandu',
  distanceKm: 2.4,
  photoUrls: ['missing-1.png', 'missing-2.png', 'missing-3.png'],
);

Widget app({
  IncomingServiceRequestDetails value = request,
  RequestActionCallback? accept,
  RequestActionCallback? decline,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: IncomingRequestDetailsScreen(
    request: value,
    onAcceptRequest: accept,
    onDeclineRequest: decline,
  ),
);

void main() {
  test('shortDescription normalizes spaces and returns four words', () {
    expect(request.shortDescription, 'Kitchen pipe is leaking…');
    expect(
      const IncomingServiceRequestDetails(
        id: '',
        customerName: '',
        categoryId: '',
        categoryName: '',
        categorySlug: '',
        description: 'Two words',
        locationText: '',
      ).shortDescription,
      'Two words',
    );
    expect(
      const IncomingServiceRequestDetails(
        id: '',
        customerName: '',
        categoryId: '',
        categoryName: '',
        categorySlug: '',
        description: '   ',
        locationText: '',
      ).shortDescription,
      '',
    );
  });

  testWidgets('renders request details and dynamic media count', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Ram Bahadur'), findsOneWidget);
    expect(find.text('Plumbing Service'), findsOneWidget);
    expect(find.text('Kitchen pipe is leaking…'), findsOneWidget);
    expect(find.text('Lazimpat, Kathmandu'), findsOneWidget);
    expect(find.text('2.4 km away'), findsOneWidget);
    expect(find.text('Photos (3)'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Video (1)'), findsNothing);
  });

  testWidgets('accept and decline callbacks receive request id', (
    tester,
  ) async {
    String? acceptedId;
    String? declinedId;
    await tester.pumpWidget(
      app(
        accept: (id) async => acceptedId = id,
        decline: (id) async => declinedId = id,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(acceptedId, 'request-42');

    await tester.ensureVisible(find.text('Decline'));
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(declinedId, 'request-42');
  });

  testWidgets('missing photos and video render safely', (tester) async {
    const emptyMedia = IncomingServiceRequestDetails(
      id: 'empty',
      customerName: 'Sita',
      categoryId: '2',
      categoryName: 'Electrician',
      categorySlug: 'electrician',
      description: '',
      locationText: 'Kathmandu',
    );
    await tester.pumpWidget(app(value: emptyMedia));
    await tester.pump();

    expect(find.textContaining('Photos ('), findsNothing);
    expect(find.text('Video (1)'), findsNothing);
    expect(find.text('No description provided.'), findsOneWidget);
  });
}
