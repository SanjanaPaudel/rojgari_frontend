import 'package:image_picker/image_picker.dart';

import 'service_category.dart';
import 'service_location.dart';

class ServiceRequestDraft {
  const ServiceRequestDraft({
    required this.category,
    required this.problemDescription,
    required this.photos,
    required this.video,
    required this.videoDuration,
    required this.location,
    required this.scheduledFor,
  });

  final ServiceCategory category;
  final String problemDescription;
  final List<XFile> photos;
  final XFile? video;
  final Duration? videoDuration;
  final ServiceLocation location;
  final DateTime? scheduledFor;

  /// Contains metadata only. Local media paths are intentionally excluded.
  Map<String, dynamic> toJson() => {
    'category_id': category.id,
    'category_slug': category.slug,
    'category_name': category.name,
    'problem_description': problemDescription,
    'location': location.toJson(),
    'photo_count': photos.length,
    'has_video': video != null,
    'video_duration_seconds': videoDuration?.inSeconds,
    'schedule_mode': scheduledFor == null ? 'now' : 'scheduled',
    // Always send UTC. The UI displays device-local time and currently permits
    // scheduling only for a future time on the device's current calendar day.
    'scheduled_for': scheduledFor?.toUtc().toIso8601String(),
  };
}
