import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/service_category.dart';
import '../../../models/service_request/service_category_presentation.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/service_request_payload.dart';
import '../../../models/service_request/service_request_validation.dart';
import '../../../repositories/service_request/service_request_repository.dart';
import '../../../repositories/service_request/service_request_repository_provider.dart';
import '../../../services/service_request/request_media_picker.dart';
import '../../../widgets/customer/service_request/photo_upload_section.dart';
import '../../../widgets/customer/service_request/problem_description_field.dart';
import '../../../widgets/customer/service_request/service_location_card.dart';
import '../../../widgets/customer/service_request/service_request_header.dart';
import '../../../widgets/customer/service_request/service_request_notification.dart';
import '../../../widgets/customer/service_request/service_request_submit_button.dart';
import '../../../widgets/customer/service_request/service_schedule_card.dart';
import '../../../widgets/customer/service_request/video_upload_card.dart';
import 'service_location_picker_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({
    required this.category,
    this.initialLocation,
    this.repository,
    super.key,
  });

  final ServiceCategory category;
  final SelectedServiceLocation? initialLocation;
  final ServiceRequestRepository? repository;

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _mediaPicker = RequestMediaPicker();
  final List<XFile?> _photoSlots = List<XFile?>.filled(3, null);
  late final ServiceRequestRepository _repository;

  SelectedServiceLocation? _selectedServiceLocation;
  XFile? _video;
  Duration? _videoDuration;
  DateTime? _scheduledFor;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? serviceRequestRepository;
    _selectedServiceLocation = widget.initialLocation;
    _recoverLostMedia();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _recoverLostMedia() async {
    try {
      final recovered = await _mediaPicker.retrieveLostMedia();
      if (!mounted || recovered.isEmpty) return;
      final existingPaths = _photoSlots
          .whereType<XFile>()
          .map((e) => e.path)
          .toSet();
      for (final file in recovered) {
        if (existingPaths.contains(file.path)) continue;
        final emptyIndex = _photoSlots.indexWhere((item) => item == null);
        if (emptyIndex == -1) break;
        _photoSlots[emptyIndex] = file;
        existingPaths.add(file.path);
      }
      setState(() {});
    } catch (error) {
      debugPrint('Lost media recovery failed: $error');
    }
  }

  Future<ImageSource?> _showSourceSheet({required bool video}) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                video ? Icons.videocam_outlined : Icons.camera_alt_outlined,
              ),
              title: Text(video ? 'Record Video' : 'Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                video ? 'Upload from Gallery' : 'Choose from Gallery',
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(int index) async {
    final source = await _showSourceSheet(video: false);
    if (source == null || !mounted) return;
    try {
      final file = await _mediaPicker.pickPhoto(source);
      if (!mounted || file == null) return;
      setState(() => _photoSlots[index] = file);
    } catch (error) {
      if (mounted) _showMessage('Unable to select photo. Please try again.');
    }
  }

  Future<void> _pickVideo() async {
    final source = await _showSourceSheet(video: true);
    if (source == null || !mounted) return;
    try {
      final picked = await _mediaPicker.pickVideo(source);
      if (!mounted || picked == null) return;
      if (picked.duration > const Duration(seconds: 30)) {
        _showMessage('Please select a video that is 30 seconds or shorter.');
        return;
      }
      setState(() {
        _video = picked.file;
        _videoDuration = picked.duration;
      });
    } catch (error) {
      if (mounted) _showMessage('The selected video could not be read.');
    }
  }

  Future<void> _toggleSchedule(bool enabled) async {
    if (!enabled) {
      setState(() => _scheduledFor = null);
      return;
    }
    await _selectScheduleTime();
  }

  Future<void> _selectServiceLocation() async {
    final result = await Navigator.push<SelectedServiceLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceLocationPickerScreen(
          initialLocation: _selectedServiceLocation,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedServiceLocation = result);
  }

  Future<void> _selectScheduleTime() async {
    final now = DateTime.now();
    final suggested = now.add(const Duration(hours: 1));
    final initial = suggested.day == now.day
        ? TimeOfDay.fromDateTime(suggested)
        : TimeOfDay.fromDateTime(now);
    final selected = await showTimePicker(
      context: context,
      initialTime: _scheduledFor == null
          ? initial
          : TimeOfDay.fromDateTime(_scheduledFor!),
      helpText: 'Select a time today',
    );
    if (!mounted || selected == null) return;

    final current = DateTime.now();
    final candidate = DateTime(
      current.year,
      current.month,
      current.day,
      selected.hour,
      selected.minute,
    );
    if (!candidate.isAfter(current)) {
      _showMessage('Please select a future time today.');
      return;
    }
    setState(() => _scheduledFor = candidate);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final locationError = ServiceRequestValidation.location(
      _selectedServiceLocation,
    );
    if (locationError != null) {
      _showMessage(locationError);
      return;
    }
    if (widget.category.id <= 0 ||
        widget.category.name.trim().isEmpty ||
        widget.category.slug.trim().isEmpty) {
      _showMessage('A valid service category is required.');
      return;
    }
    final now = DateTime.now();
    if (_scheduledFor != null &&
        !isValidLaterTodayTime(scheduledFor: _scheduledFor!, now: now)) {
      _showMessage('Please select a future time today.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final photos = _uniqueSelectedPhotos;
      final mediaError = await _validateSelectedMedia(
        photos: photos,
        video: _video,
      );
      if (!mounted) return;
      if (mediaError != null) {
        _showMessage(mediaError);
        return;
      }
      if (_video != null &&
          (_videoDuration == null ||
              _videoDuration! > const Duration(seconds: 30))) {
        _showMessage('Please select a video that is 30 seconds or shorter.');
        return;
      }

      final payload = ServiceRequestPayload(
        categoryId: widget.category.id,
        categorySlug: widget.category.slug,
        categoryName: widget.category.name,
        description: _descriptionController.text.trim(),
        serviceLocation: _selectedServiceLocation!,
        scheduleType: _scheduledFor == null
            ? ServiceRequestScheduleType.now
            : ServiceRequestScheduleType.laterToday,
        scheduledTime: _scheduledFor == null
            ? null
            : '${_scheduledFor!.hour.toString().padLeft(2, '0')}:'
                  '${_scheduledFor!.minute.toString().padLeft(2, '0')}:00',
        media: [
          ...photos.map(
            (file) => RequestMediaPayload(type: 'image', localFile: file),
          ),
          if (_video != null)
            RequestMediaPayload(type: 'video', localFile: _video),
        ],
      );
      // BACKEND TODO: The approved schedule and landmark UI remain local-only
      // until Django adds documented fields for them. This repository call
      // intentionally submits neither value.
      final result = await _repository.createServiceRequest(payload);
      if (mounted) {
        _showMessage(
          result.message,
          type: ServiceRequestNotificationType.success,
        );
      }

      // BACKEND SUCCESS NAVIGATION TODO:
      // POST /api/services/bookings/ only creates an active booking. It does
      // not assign a worker and provides no matching/polling flow. Add a real
      // booking confirmation/history navigation here only when that screen and
      // its documented backend flow exist.
    } on ServiceRequestException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Unable to submit request. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<XFile> get _uniqueSelectedPhotos {
    final paths = <String>{};
    final files = <XFile>{};
    return _photoSlots
        .whereType<XFile>()
        .where((file) {
          if (!files.add(file)) return false;
          return file.path.isEmpty || paths.add(file.path);
        })
        .toList(growable: false);
  }

  Future<String?> _validateSelectedMedia({
    required List<XFile> photos,
    required XFile? video,
  }) async {
    const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
    const videoExtensions = {'mp4', 'mov', 'm4v', 'webm', 'avi'};

    for (final photo in photos) {
      if (!_hasSupportedExtension(photo.name, imageExtensions)) {
        return 'The photo "${photo.name}" uses an unsupported file type.';
      }
      if (!await _isReadable(photo)) {
        return 'The photo "${photo.name}" is no longer readable. Select it again.';
      }
    }
    if (video != null) {
      if (!_hasSupportedExtension(video.name, videoExtensions)) {
        return 'The video "${video.name}" uses an unsupported file type.';
      }
      if (!await _isReadable(video)) {
        return 'The selected video is no longer readable. Select it again.';
      }
    }
    return null;
  }

  bool _hasSupportedExtension(String name, Set<String> supported) {
    final separator = name.lastIndexOf('.');
    if (separator < 0 || separator == name.length - 1) return false;
    return supported.contains(name.substring(separator + 1).toLowerCase());
  }

  Future<bool> _isReadable(XFile file) async {
    try {
      return await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(
    String message, {
    ServiceRequestNotificationType type = ServiceRequestNotificationType.error,
  }) => ServiceRequestNotifier.show(context, message: message, type: type);

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category.name.trim();
    final buttonLabel = categoryName.length <= 18
        ? 'Start Finding $categoryName'
        : 'Start Finding Service Person';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceRequestHeader(category: widget.category),
                const SizedBox(height: 28),
                const _SectionLabel(
                  title: 'Describe the Problem',
                  required: true,
                ),
                const SizedBox(height: 9),
                ProblemDescriptionField(
                  controller: _descriptionController,
                  hint: ServiceCategoryPresentation.problemHintFor(
                    widget.category.slug,
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel(title: 'Add Photos', detail: '(up to 3)'),
                const SizedBox(height: 10),
                PhotoUploadSection(
                  photos: _photoSlots,
                  onTap: _pickPhoto,
                  onRemove: (index) =>
                      setState(() => _photoSlots[index] = null),
                ),
                const SizedBox(height: 26),
                const _SectionLabel(
                  title: 'Add Video',
                  detail: '(30 sec max · optional)',
                ),
                const SizedBox(height: 10),
                VideoUploadCard(
                  fileName: _video?.name,
                  duration: _videoDuration,
                  onTap: _pickVideo,
                  onRemove: () => setState(() {
                    _video = null;
                    _videoDuration = null;
                  }),
                ),
                const SizedBox(height: 26),
                const _SectionLabel(title: 'Service Location', required: true),
                const SizedBox(height: 10),
                ServiceLocationCard(
                  location: _selectedServiceLocation,
                  onChange: _selectServiceLocation,
                ),
                const SizedBox(height: 24),
                ServiceScheduleCard(
                  isEnabled: _scheduledFor != null,
                  scheduledFor: _scheduledFor,
                  onToggle: _toggleSchedule,
                  onSelectTime: _selectScheduleTime,
                ),
                const SizedBox(height: 30),
                ServiceRequestSubmitButton(
                  label: buttonLabel,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.detail,
    this.required = false,
  });

  final String title;
  final String? detail;
  final bool required;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: title),
        if (required) const TextSpan(text: ' *'),
        if (detail != null)
          TextSpan(
            text: ' $detail',
            style: const TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    ),
    style: const TextStyle(
      color: AppColors.black,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}
