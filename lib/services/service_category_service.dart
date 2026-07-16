import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_urls.dart';
import '../models/service_request/service_category.dart';
import 'storage_service.dart';

class ServiceCategoryException implements Exception {
  const ServiceCategoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServiceCategoryService {
  ServiceCategoryService({
    http.Client? client,
    Uri? endpoint,
    Future<String?> Function()? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? Uri.parse(ApiUrls.serviceCategories),
       _accessTokenProvider =
           accessTokenProvider ?? StorageService().getAccessToken;

  final http.Client _client;
  final Uri _endpoint;
  final Future<String?> Function() _accessTokenProvider;

  Future<List<ServiceCategory>> fetchCategories() async {
    final accessToken = (await _accessTokenProvider())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ServiceCategoryException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final response = await _client.get(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 401) {
        throw const ServiceCategoryException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode == 403) {
        throw const ServiceCategoryException(
          'This account cannot load customer service categories.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ServiceCategoryException(
          'Unable to load service categories. Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['categories'] is! List) {
        throw const ServiceCategoryException(
          'The service categories response is invalid.',
        );
      }
      final categories =
          (decoded['categories'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ServiceCategory.fromJson)
              .toList()
            ..sort(
              (left, right) => left.displayOrder.compareTo(right.displayOrder),
            );
      return categories;
    } on ServiceCategoryException {
      rethrow;
    } on FormatException {
      throw const ServiceCategoryException(
        'The service categories response is invalid.',
      );
    } catch (_) {
      throw const ServiceCategoryException(
        'Unable to load service categories. Please try again.',
      );
    }
  }

  void dispose() => _client.close();
}
