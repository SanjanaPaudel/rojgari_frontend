import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class PickedVideo {
  const PickedVideo(this.file, this.duration);

  final XFile file;
  final Duration duration;
}

class RequestMediaPicker {
  RequestMediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickPhoto(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 82, maxWidth: 1600);

  /// Lets the user select several gallery photos in one visit, capped at
  /// [limit] so the native picker itself refuses further taps past that
  /// count (mirrors the disabled-card cap used on the skill-selection
  /// screens, just enforced inside the OS picker instead of a Flutter
  /// widget).
  Future<List<XFile>> pickMultiplePhotos({required int limit}) =>
      _picker.pickMultiImage(imageQuality: 82, maxWidth: 1600, limit: limit);

  Future<PickedVideo?> pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (file == null) return null;

    VideoPlayerController? controller;
    try {
      // image_picker returns a browser blob URL on web and a local file path
      // on mobile. video_player needs the matching source constructor.
      controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(file.path))
          : VideoPlayerController.contentUri(Uri.file(file.path));
      await controller.initialize();
      return PickedVideo(file, controller.value.duration);
    } finally {
      await controller?.dispose();
    }
  }

  /// Call once near application startup and pass recovered files to the active
  /// request flow. Android can terminate the activity while a picker is open.
  Future<List<XFile>> retrieveLostMedia() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return const [];
    if (response.exception != null) {
      debugPrint('Unable to recover picker data: ${response.exception}');
    }
    return response.files ?? const [];
  }
}
