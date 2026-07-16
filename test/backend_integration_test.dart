import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rojgari_frontend_one/core/constants/api_urls.dart';
import 'package:rojgari_frontend_one/models/service_request/selected_service_location.dart';
import 'package:rojgari_frontend_one/models/service_request/service_request_payload.dart';
import 'package:rojgari_frontend_one/models/service_request/service_request_validation.dart';
import 'package:rojgari_frontend_one/repositories/service_request/api_service_request_repository.dart';
import 'package:rojgari_frontend_one/repositories/service_request/service_request_repository.dart';
import 'package:rojgari_frontend_one/repositories/service_request/service_request_repository_provider.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';
import 'package:rojgari_frontend_one/services/service_category_service.dart';
import 'package:rojgari_frontend_one/services/storage_service.dart';

void main() {
  group('authentication contract', () {
    test('login reads access and refresh and saves both tokens', () async {
      final storage = _MemoryStorageService();
      late Map<String, dynamic> sentBody;
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login/');
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'access': 'access-jwt',
            'refresh': 'refresh-jwt',
            'user': {
              'id': 1,
              'full_name': 'Customer Name',
              'phone_number': '+9779812345678',
              'role': 'customer',
            },
            'next_screen': 'customer_dashboard',
          }),
          200,
        );
      });
      final service = AuthService(
        client: client,
        storage: storage,
        loginEndpoint: Uri.parse('https://example.test/api/auth/login/'),
      );

      final session = await service.login(
        phoneNumber: '9812345678',
        password: 'password',
      );

      expect(sentBody, {
        'phone_number': '+9779812345678',
        'password': 'password',
      });
      expect(storage.accessToken, 'access-jwt');
      expect(storage.refreshToken, 'refresh-jwt');
      expect(session.user.role, 'customer');
      expect(session.nextScreen, 'customer_dashboard');
    });

    test('refresh sends refresh and saves the new access token', () async {
      final storage = _MemoryStorageService()..refreshToken = 'refresh-jwt';
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {'refresh': 'refresh-jwt'});
        return http.Response(jsonEncode({'access': 'new-access'}), 200);
      });
      final service = AuthService(
        client: client,
        storage: storage,
        refreshEndpoint: Uri.parse('https://example.test/api/auth/refresh/'),
      );

      expect(await service.refreshAccessToken(), 'new-access');
      expect(storage.accessToken, 'new-access');
    });
  });

  test('API URLs use the confirmed Django paths', () {
    expect(ApiUrls.login, endsWith('/api/auth/login/'));
    expect(ApiUrls.refresh, endsWith('/api/auth/refresh/'));
    expect(ApiUrls.serviceCategories, endsWith('/api/services/categories/'));
    expect(ApiUrls.createBooking, endsWith('/api/services/bookings/'));
  });

  test('wrapped categories parse integer IDs and display order', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer access-jwt');
      return http.Response(
        jsonEncode({
          'categories': [
            {
              'id': 7,
              'name': 'Mechanic',
              'description': 'Vehicle service',
              'icon': '/media/mechanic.png',
              'display_order': 2,
            },
            {
              'id': 1,
              'name': 'Plumber',
              'description': 'Plumbing service',
              'icon': null,
              'display_order': 0,
            },
          ],
        }),
        200,
      );
    });
    final service = ServiceCategoryService(
      client: client,
      endpoint: Uri.parse('https://example.test/api/services/categories/'),
      accessTokenProvider: () async => 'access-jwt',
    );

    final categories = await service.fetchCategories();

    expect(categories.first.id, isA<int>());
    expect(categories.first.id, 1);
    expect(categories.last.slug, 'mechanic');
    service.dispose();
  });

  group('real booking multipart contract', () {
    test(
      'sends integer category, coordinates, and no unsupported fields',
      () async {
        final client = _RecordingBookingClient();
        final repository = _repository(client);
        final payload = _payload(
          scheduleType: ServiceRequestScheduleType.laterToday,
          scheduledTime: '20:30:00',
          location: const SelectedServiceLocation(
            latitude: 27.7172,
            longitude: 85.3240,
            accuracyMeters: 12,
            landmark: 'Near Durbar Marg',
            source: 'search',
          ),
        );

        await repository.createServiceRequest(payload);
        final request = client.request!;

        expect(request.method, 'POST');
        expect(request.url.path, '/api/services/bookings/');
        expect(request.headers['Authorization'], 'Bearer access-jwt');
        expect(request.fields, {
          'category': '7',
          'description': 'Engine makes an unusual noise.',
          'latitude': '27.7172',
          'longitude': '85.324',
        });
        expect(request.fields.values, isNot(contains('mechanic')));
        for (final unsupported in const [
          'category_id',
          'schedule_type',
          'scheduled_time',
          'timezone',
          'accuracy_meters',
          'landmark',
          'location_source',
          'formatted_address',
          'address_text',
        ]) {
          expect(request.fields, isNot(contains(unsupported)));
        }
      },
    );

    test('zero photos and no video sends no files', () async {
      final client = _RecordingBookingClient();
      await _repository(client).createServiceRequest(_payload());
      expect(client.request!.files, isEmpty);
    });

    test(
      'one to three photos use repeated photos field with actual bytes',
      () async {
        final client = _RecordingBookingClient();
        final photos = List.generate(
          3,
          (index) => RequestMediaPayload(
            type: 'image',
            localFile: XFile.fromData(
              Uint8List.fromList([index + 1, index + 2]),
              name: 'photo-$index.jpg',
              mimeType: 'image/jpeg',
            ),
          ),
        );

        await _repository(client).createServiceRequest(_payload(media: photos));

        final photoFiles = client.request!.files
            .where((file) => file.field == 'photos')
            .toList();
        expect(photoFiles, hasLength(3));
        expect(await photoFiles.first.finalize().toBytes(), isNotEmpty);
      },
    );

    test('more than three photos is blocked before HTTP', () async {
      final client = _RecordingBookingClient();
      final photos = List.generate(
        4,
        (index) => RequestMediaPayload(
          type: 'image',
          localFile: XFile.fromData(
            Uint8List.fromList([index + 1]),
            name: 'photo-$index.jpg',
          ),
        ),
      );

      await expectLater(
        _repository(client).createServiceRequest(_payload(media: photos)),
        throwsA(
          isA<ServiceRequestException>().having(
            (error) => error.message,
            'message',
            contains('maximum of three'),
          ),
        ),
      );
      expect(client.sendCount, 0);
    });

    test('optional video uses only the video field', () async {
      final client = _RecordingBookingClient();
      final video = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'issue.mp4',
        mimeType: 'video/mp4',
      );

      await _repository(client).createServiceRequest(
        _payload(
          media: [RequestMediaPayload(type: 'video', localFile: video)],
        ),
      );

      expect(client.request!.files, hasLength(1));
      expect(client.request!.files.single.field, 'video');
    });

    test('blank and over-300 descriptions are blocked before HTTP', () async {
      final blankClient = _RecordingBookingClient();
      final longClient = _RecordingBookingClient();

      await expectLater(
        _repository(
          blankClient,
        ).createServiceRequest(_payload(description: '   ')),
        throwsA(isA<ServiceRequestException>()),
      );
      await expectLater(
        _repository(
          longClient,
        ).createServiceRequest(_payload(description: 'a' * 301)),
        throwsA(
          isA<ServiceRequestException>().having(
            (error) => error.message,
            'message',
            contains('300'),
          ),
        ),
      );
      expect(blankClient.sendCount, 0);
      expect(longClient.sendCount, 0);
    });

    test('invalid latitude or longitude is blocked before HTTP', () async {
      final client = _RecordingBookingClient();
      await expectLater(
        _repository(client).createServiceRequest(
          _payload(
            location: const SelectedServiceLocation(
              latitude: 91,
              longitude: 181,
            ),
          ),
        ),
        throwsA(isA<ServiceRequestException>()),
      );
      expect(client.sendCount, 0);
    });

    test('HTTP 201 accepts null address_text', () async {
      final result = await _repository(
        _RecordingBookingClient(),
      ).createServiceRequest(_payload());

      expect(result.id, 12);
      expect(result.category, 'Mechanic');
      expect(result.description, 'Engine makes an unusual noise.');
      expect(result.addressText, isNull);
      expect(result.status, 'active');
    });

    test('400 list and string field errors become readable messages', () async {
      final listRepository = _repository(
        _RecordingBookingClient(
          statusCode: 400,
          body: {
            'description': ['This field may not be blank.'],
          },
        ),
      );
      final stringRepository = _repository(
        _RecordingBookingClient(
          statusCode: 400,
          body: {'photos': 'You can upload a maximum of 3 photos.'},
        ),
      );

      await expectLater(
        listRepository.createServiceRequest(_payload()),
        throwsA(
          isA<ServiceRequestException>().having(
            (error) => error.message,
            'message',
            'This field may not be blank.',
          ),
        ),
      );
      await expectLater(
        stringRepository.createServiceRequest(_payload()),
        throwsA(
          isA<ServiceRequestException>().having(
            (error) => error.message,
            'message',
            'You can upload a maximum of 3 photos.',
          ),
        ),
      );
    });

    test('401 and 403 become readable authentication/role errors', () async {
      for (final statusCode in [401, 403]) {
        final repository = _repository(
          _RecordingBookingClient(
            statusCode: statusCode,
            body: {'detail': 'Backend detail'},
          ),
        );
        await expectLater(
          repository.createServiceRequest(_payload()),
          throwsA(
            isA<ServiceRequestException>().having(
              (error) => error.message,
              'message',
              statusCode == 401 ? contains('session') : contains('customer'),
            ),
          ),
        );
      }
    });

    test('missing access token stops before sending Bearer null', () async {
      final client = _RecordingBookingClient();
      final repository = ApiServiceRequestRepository(
        client: client,
        endpoint: Uri.parse('https://example.test/api/services/bookings/'),
        accessTokenProvider: () async => null,
      );

      await expectLater(
        repository.createServiceRequest(_payload()),
        throwsA(
          isA<ServiceRequestException>().having(
            (error) => error.message,
            'message',
            contains('sign in'),
          ),
        ),
      );
      expect(client.sendCount, 0);
    });
  });

  test('missing selected location is blocked by screen validation rule', () {
    expect(
      ServiceRequestValidation.location(null),
      'Please select a service location.',
    );
  });

  test('real API repository provider is active', () {
    expect(serviceRequestRepository, isA<ApiServiceRequestRepository>());
  });
}

ApiServiceRequestRepository _repository(http.Client client) =>
    ApiServiceRequestRepository(
      client: client,
      endpoint: Uri.parse('https://example.test/api/services/bookings/'),
      accessTokenProvider: () async => 'access-jwt',
    );

ServiceRequestPayload _payload({
  int categoryId = 7,
  String description = 'Engine makes an unusual noise.',
  SelectedServiceLocation location = const SelectedServiceLocation(
    latitude: 27.7172,
    longitude: 85.3240,
  ),
  ServiceRequestScheduleType scheduleType = ServiceRequestScheduleType.now,
  String? scheduledTime,
  List<RequestMediaPayload> media = const [],
}) => ServiceRequestPayload(
  categoryId: categoryId,
  categorySlug: 'mechanic',
  categoryName: 'Mechanic',
  description: description,
  serviceLocation: location,
  scheduleType: scheduleType,
  scheduledTime: scheduledTime,
  media: media,
);

class _MemoryStorageService extends StorageService {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;
}

class _RecordingBookingClient extends http.BaseClient {
  _RecordingBookingClient({
    this.statusCode = 201,
    this.body = const {
      'id': 12,
      'category': 'Mechanic',
      'description': 'Engine makes an unusual noise.',
      'address_text': null,
      'status': 'active',
    },
  });

  final int statusCode;
  final Map<String, dynamic> body;
  http.MultipartRequest? request;
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sendCount++;
    this.request = request as http.MultipartRequest;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}
