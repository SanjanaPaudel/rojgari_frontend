import 'package:image_picker/image_picker.dart';

import 'selected_service_location.dart';

enum ServiceRequestScheduleType {
  now('now'),
  laterToday('later_today');

  const ServiceRequestScheduleType(this.apiValue);
  final String apiValue;
}

bool isValidLaterTodayTime({
  required DateTime scheduledFor,
  required DateTime now,
}) =>
    scheduledFor.isAfter(now) &&
    scheduledFor.year == now.year &&
    scheduledFor.month == now.month &&
    scheduledFor.day == now.day;

class RequestMediaPayload {
  const RequestMediaPayload({
    required this.type,
    this.localFile,
    this.mediaId,
    this.url,
  });

  final String type;
  final XFile? localFile;
  final String? mediaId;
  final String? url;

  /// Local files are repository input only and are never serialized.
  Map<String, dynamic> toJson() => {
    'mediaId': mediaId,
    'type': type,
    'url': url,
  };
}

class ServiceRequestPayload {
  const ServiceRequestPayload({
    required this.categoryId,
    required this.categorySlug,
    required this.categoryName,
    required this.description,
    required this.serviceLocation,
    this.scheduleType = ServiceRequestScheduleType.now,
    this.scheduledTime,
    this.media = const [],
  });

  final String categoryId;
  final String categorySlug;
  final String categoryName;
  final String description;
  final SelectedServiceLocation serviceLocation;
  final ServiceRequestScheduleType scheduleType;
  final String? scheduledTime;
  final List<RequestMediaPayload> media;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categorySlug': categorySlug,
    'categoryName': categoryName,
    'description': description,
    'scheduleType': scheduleType.apiValue,
    'scheduledTime': scheduledTime,
    'serviceLocation': serviceLocation.toJson(),
    'media': media.map((item) => item.toJson()).toList(),
  };
}

class ServiceRequestResult {
  const ServiceRequestResult({
    required this.requestId,
    required this.status,
    required this.createdAt,
    required this.message,
  });

  final String requestId;
  final String status;
  final DateTime createdAt;
  final String message;
}
