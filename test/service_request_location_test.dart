import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rojgari_frontend_one/models/service_request/selected_service_location.dart';
import 'package:rojgari_frontend_one/models/service_request/service_request_payload.dart';
import 'package:rojgari_frontend_one/repositories/service_request/mock_service_request_repository.dart';
import 'package:rojgari_frontend_one/repositories/service_request/api_service_request_repository.dart';
import 'package:rojgari_frontend_one/repositories/service_request/service_request_repository.dart';
import 'package:rojgari_frontend_one/services/location/location_service.dart';
import 'package:rojgari_frontend_one/services/location/open_street_map_search_service.dart';
import 'package:rojgari_frontend_one/widgets/customer/service_request/location/service_location_section.dart';
import 'package:rojgari_frontend_one/widgets/customer/service_request/service_request_notification.dart';

void main() {
  test('location JSON keeps raw coordinates and landmark', () {
    const location = SelectedServiceLocation(
      latitude: 27.671234,
      longitude: 85.339876,
      landmark: 'Near NCIT College',
      accuracyMeters: 18.5,
    );

    expect(location.hasValidCoordinates, isTrue);
    expect(location.toJson(), containsPair('latitude', 27.671234));
    expect(location.toJson(), containsPair('landmark', 'Near NCIT College'));
    expect(location.toJson(), isNot(contains('formattedAddress')));
  });

  test('mock repository returns frontend success', () async {
    const location = SelectedServiceLocation(
      latitude: 27.671234,
      longitude: 85.339876,
    );
    const payload = ServiceRequestPayload(
      categoryId: 1,
      categorySlug: 'plumber',
      categoryName: 'Plumber',
      description: 'Kitchen sink is leaking.',
      serviceLocation: location,
    );

    final result = await const MockServiceRequestRepository()
        .createServiceRequest(payload);

    expect(result.status, 'active');
    expect(result.id, greaterThan(0));
  });

  test('place suggestions prioritize Nepal before other countries', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api');
      expect(request.url.queryParameters['q'], 'Pabitra School');
      expect(request.url.queryParameters['lat'], isNotNull);
      expect(request.url.queryParameters['lon'], isNotNull);
      expect(request.headers['User-Agent'], contains('Rojgari'));
      return http.Response(
        jsonEncode({
          'features': [
            {
              'geometry': {
                'coordinates': [-74.0060, 40.7128],
              },
              'properties': {
                'name': 'Pabitra School',
                'city': 'New York',
                'country': 'United States',
                'countrycode': 'US',
              },
            },
            {
              'geometry': {
                'coordinates': [85.339534, 27.645342],
              },
              'properties': {
                'name': 'Pabitra School',
                'city': 'Lalitpur',
                'country': 'Nepal',
                'countrycode': 'NP',
              },
            },
          ],
        }),
        200,
      );
    });
    final service = OpenStreetMapSearchService(client: client);

    final results = await service.search('Pabitra School');

    expect(results, hasLength(2));
    expect(results.first.latitude, 27.645342);
    expect(results.first.displayName, contains('Lalitpur'));
    expect(results.first.isInNepal, isTrue);
    expect(results.last.displayName, contains('United States'));
    service.dispose();
  });

  test('API repository sends text and real media bytes as multipart', () async {
    final client = _RecordingMultipartClient();
    final photo1 = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'issue-one.jpg',
      mimeType: 'image/jpeg',
    );
    final photo2 = XFile.fromData(
      Uint8List.fromList([4, 5, 6]),
      name: 'issue-two.png',
      mimeType: 'image/png',
    );
    final video = XFile.fromData(
      Uint8List.fromList([7, 8, 9]),
      name: 'issue.mp4',
      mimeType: 'video/mp4',
    );
    final repository = ApiServiceRequestRepository(
      client: client,
      endpoint: Uri.parse('https://example.test/service-requests/'),
      accessTokenProvider: () async => 'test-token',
    );
    final payload = ServiceRequestPayload(
      categoryId: 7,
      categorySlug: 'mechanic',
      categoryName: 'Mechanic',
      description: 'My bike is not starting.',
      serviceLocation: const SelectedServiceLocation(
        latitude: 27.671234,
        longitude: 85.339876,
        accuracyMeters: 18.5,
        landmark: 'Near NCIT College',
        source: 'map',
      ),
      scheduleType: ServiceRequestScheduleType.laterToday,
      scheduledTime: '20:11:00',
      media: [
        RequestMediaPayload(type: 'image', localFile: photo1),
        RequestMediaPayload(type: 'image', localFile: photo2),
        RequestMediaPayload(type: 'video', localFile: video),
      ],
    );

    final result = await repository.createServiceRequest(payload);
    final request = client.request!;

    expect(result.id, 123);
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(request.fields['category'], '7');
    expect(request.fields['latitude'], '27.671234');
    expect(request.fields, isNot(contains('category_id')));
    expect(request.fields, isNot(contains('schedule_type')));
    expect(request.fields, isNot(contains('scheduled_time')));
    expect(request.fields, isNot(contains('timezone')));
    expect(request.fields, isNot(contains('landmark')));
    expect(request.fields, isNot(contains('preferredDate')));
    expect(request.fields, isNot(contains('preferredTime')));
    expect(request.fields, isNot(contains('scheduleForLater')));
    expect(request.fields, isNot(contains('formatted_address')));
    expect(request.files.where((file) => file.field == 'photos'), hasLength(2));
    expect(request.files.where((file) => file.field == 'video'), hasLength(1));
  });

  test('now multipart omits scheduled time and optional media', () async {
    final client = _RecordingMultipartClient();
    final repository = ApiServiceRequestRepository(
      client: client,
      endpoint: Uri.parse('https://example.test/service-requests/'),
      accessTokenProvider: () async => 'test-token',
    );
    const payload = ServiceRequestPayload(
      categoryId: 7,
      categorySlug: 'mechanic',
      categoryName: 'Mechanic',
      description: 'My bike is not starting.',
      serviceLocation: SelectedServiceLocation(
        latitude: 27.671234,
        longitude: 85.339876,
        source: 'map',
      ),
    );

    await repository.createServiceRequest(payload);
    final request = client.request!;

    expect(request.fields['category'], '7');
    expect(request.fields, isNot(contains('schedule_type')));
    expect(request.fields, isNot(contains('timezone')));
    expect(request.fields, isNot(contains('scheduled_time')));
    expect(request.files, isEmpty);
  });

  test('later-today validation rejects a past time or tomorrow', () {
    final now = DateTime(2026, 7, 15, 16);

    expect(
      isValidLaterTodayTime(
        scheduledFor: DateTime(2026, 7, 15, 15, 59),
        now: now,
      ),
      isFalse,
    );
    expect(
      isValidLaterTodayTime(scheduledFor: DateTime(2026, 7, 16, 17), now: now),
      isFalse,
    );
    expect(
      isValidLaterTodayTime(scheduledFor: DateTime(2026, 7, 15, 17), now: now),
      isTrue,
    );
  });

  test('API repository exposes readable structured backend errors', () async {
    final repository = ApiServiceRequestRepository(
      client: _ValidationErrorClient(),
      endpoint: Uri.parse('https://example.test/service-requests/'),
      accessTokenProvider: () async => 'test-token',
    );
    const payload = ServiceRequestPayload(
      categoryId: 7,
      categorySlug: 'mechanic',
      categoryName: 'Mechanic',
      description: 'My bike is not starting.',
      serviceLocation: SelectedServiceLocation(
        latitude: 27.671234,
        longitude: 85.339876,
      ),
    );

    await expectLater(
      repository.createServiceRequest(payload),
      throwsA(
        isA<ServiceRequestException>().having(
          (error) => error.message,
          'message',
          'This field may not be blank.',
        ),
      ),
    );
  });

  testWidgets('shows real-settings action when location is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceLocationSection(
            locationService: const _DisabledLocationService(),
            onLocationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location is turned off'), findsOneWidget);
    expect(find.text('Turn on location'), findsOneWidget);
  });

  testWidgets('shows app-settings action when permission is blocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceLocationSection(
            locationService: const _BlockedLocationService(),
            onLocationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location permission is blocked'), findsOneWidget);
    expect(find.text('Open app settings'), findsOneWidget);
  });

  testWidgets('shows service errors in the floating top notification', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ServiceRequestNotifier.show(
                  context,
                  message: 'Please select a service location.',
                ),
                child: const Text('Show message'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show message'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Action needed'), findsOneWidget);
    expect(find.text('Please select a service location.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Action needed')).dy, lessThan(100));

    await tester.pump(const Duration(seconds: 5));
  });
}

class _DisabledLocationService extends LocationService {
  const _DisabledLocationService();

  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

class _BlockedLocationService extends LocationService {
  const _BlockedLocationService();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<AppLocationPermission> checkPermission() async =>
      AppLocationPermission.blocked;
}

class _RecordingMultipartClient extends http.BaseClient {
  http.MultipartRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.MultipartRequest;
    final body = jsonEncode({
      'id': 123,
      'category': 'Mechanic',
      'description': 'My bike is not starting.',
      'address_text': null,
      'status': 'active',
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      201,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _ValidationErrorClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({
      'description': ['This field may not be blank.'],
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      400,
      headers: {'content-type': 'application/json'},
    );
  }
}
