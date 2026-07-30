import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches the logged-in user's notification history.
///
/// Built on [ApiService] (not a raw http.Client) so this call inherits the
/// app's existing JWT-refresh-on-401 and forced-logout-on-expired-session
/// behavior for free, same as every other authenticated endpoint.
class NotificationService {
  NotificationService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<List<NotificationItem>> fetchNotifications() async {
    final response = await _api.get(ApiUrls.notifications);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map(
              (item) => NotificationItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      throw const NotificationServiceException(
        'Unexpected response while loading notifications.',
      );
    }

    throw NotificationServiceException(
      'Unable to load notifications (${response.statusCode}).',
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _api.get(ApiUrls.unreadNotificationCount);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['unread_count'] is int) {
        return decoded['unread_count'] as int;
      }
      throw const NotificationServiceException(
        'Unexpected response while loading the unread count.',
      );
    }

    throw NotificationServiceException(
      'Unable to load the unread count (${response.statusCode}).',
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await _api.patch(
      ApiUrls.markNotificationRead(notificationId),
      {},
    );

    if (response.statusCode != 200) {
      throw NotificationServiceException(
        'Unable to mark notification as read (${response.statusCode}).',
      );
    }
  }
}
