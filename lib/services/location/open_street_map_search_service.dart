import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/map_config.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.countryCode,
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final String? countryCode;

  bool get isInNepal =>
      countryCode?.toUpperCase() == 'NP' || displayName.endsWith(', Nepal');
}

class LocationSearchException implements Exception {
  const LocationSearchException(this.message);
  final String message;
}

class OpenStreetMapSearchService {
  OpenStreetMapSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Object> _cache = {};
  DateTime? _lastRequestAt;

  // ========================================================================
  // BACKEND INTEGRATION: LOCATION SEARCH AND DISPLAY LABELS
  //
  // CURRENT FRONTEND BEHAVIOUR:
  // - Uses Photon (OpenStreetMap data) for debounced search suggestions.
  // - Uses Nominatim only for a reverse lookup after the map stops moving.
  // - Sends raw latitude/longitude as the authoritative request location.
  // - Caches results, debounces typing in the UI, and rate-limits requests.
  // - Biases results toward Nepal and sorts Nepal matches before other places.
  //
  // PRODUCTION BACKEND DEVELOPER:
  // - Prefer proxying autocomplete and reverse lookup through cached backend
  //   endpoints or a production geocoding provider.
  // - Public Nominatim must not be used for client-side autocomplete.
  // - Set PHOTON_BASE_URL and NOMINATIM_BASE_URL with --dart-define to switch
  //   providers without modifying the Request or Location UI.
  // - Keep final reverse geocoding, service-area validation, and trusted
  //   address storage on the backend.
  // - Never treat the display label/landmark as a replacement for coordinates.
  // ========================================================================
  Future<List<LocationSearchResult>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 3) {
      throw const LocationSearchException(
        'Enter at least 3 characters to search.',
      );
    }
    final cacheKey = 'search:${cleanQuery.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached is List<LocationSearchResult>) return cached;

    await _respectRateLimit();
    final uri = Uri.parse('${MapConfig.photonBaseUrl}/api').replace(
      queryParameters: {
        'q': cleanQuery,
        'limit': '10',
        'lang': 'en',
        'lat': MapConfig.nepalSearchLatitude.toString(),
        'lon': MapConfig.nepalSearchLongitude.toString(),
      },
    );
    final response = await _client.get(uri, headers: MapConfig.photonHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LocationSearchException(
        'Location search is unavailable. Please try again.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final features = decoded['features'];
    if (features is! List) return const [];
    final indexedResults = features
        .whereType<Map<String, dynamic>>()
        .map(_parsePhotonResult)
        .whereType<LocationSearchResult>()
        .toList();
    indexedResults.sort((left, right) {
      if (left.isInNepal == right.isInNepal) return 0;
      return left.isInNepal ? -1 : 1;
    });
    final results = indexedResults.take(8).toList(growable: false);
    _cache[cacheKey] = results;
    return results;
  }

  Future<LocationSearchResult?> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey =
        'reverse:${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final cached = _cache[cacheKey];
    if (cached is LocationSearchResult) return cached;

    await _respectRateLimit();
    final uri = Uri.parse('${MapConfig.nominatimBaseUrl}/reverse').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
      },
    );
    final response = await _client.get(
      uri,
      headers: MapConfig.nominatimHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final result = _parseNominatimResult(decoded);
    if (result != null) _cache[cacheKey] = result;
    return result;
  }

  LocationSearchResult? _parseNominatimResult(Map<String, dynamic> json) {
    final latitude = double.tryParse(json['lat']?.toString() ?? '');
    final longitude = double.tryParse(json['lon']?.toString() ?? '');
    final displayName = json['display_name']?.toString().trim();
    if (latitude == null ||
        longitude == null ||
        displayName == null ||
        displayName.isEmpty) {
      return null;
    }
    return LocationSearchResult(
      latitude: latitude,
      longitude: longitude,
      displayName: displayName,
      countryCode: (json['address'] as Map<String, dynamic>?)?['country_code']
          ?.toString(),
    );
  }

  LocationSearchResult? _parsePhotonResult(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final properties = feature['properties'];
    if (geometry is! Map<String, dynamic> ||
        properties is! Map<String, dynamic>) {
      return null;
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final longitude = _toDouble(coordinates[0]);
    final latitude = _toDouble(coordinates[1]);
    if (latitude == null || longitude == null) return null;

    final addressParts = <String>[];
    for (final key in const [
      'name',
      'street',
      'locality',
      'district',
      'city',
      'county',
      'state',
      'country',
    ]) {
      final value = properties[key]?.toString().trim();
      if (value != null && value.isNotEmpty && !addressParts.contains(value)) {
        addressParts.add(value);
      }
    }
    if (addressParts.isEmpty) return null;
    return LocationSearchResult(
      latitude: latitude,
      longitude: longitude,
      displayName: addressParts.join(', '),
      countryCode: properties['countrycode']?.toString(),
    );
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _respectRateLimit() async {
    final previous = _lastRequestAt;
    if (previous != null) {
      final remaining =
          const Duration(seconds: 1) - DateTime.now().difference(previous);
      if (!remaining.isNegative) await Future<void>.delayed(remaining);
    }
    _lastRequestAt = DateTime.now();
  }

  void dispose() => _client.close();
}
