import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';
import '../../models/technician_model.dart';
import '../../services/worker_dashboard_service.dart';

class TechnicianEditProfileScreen extends StatefulWidget {
  const TechnicianEditProfileScreen({super.key, required this.technician});

  final TechnicianModel technician;

  @override
  State<TechnicianEditProfileScreen> createState() =>
      _TechnicianEditProfileScreenState();
}

class _TechnicianEditProfileScreenState
    extends State<TechnicianEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _about;
  late final TextEditingController _serviceArea;
  String? _localImagePath;
  Uint8List? _localImageBytes;
  String? _photoError;
  bool _isSaving = false; // Tracks API call in progress to disable the button

  @override
  void initState() {
    super.initState();
    final technician = widget.technician;
    _name = TextEditingController(text: technician.fullName);
    final phoneDigits = technician.phone.replaceAll(RegExp(r'\D'), '');
    _phone = TextEditingController(
      text: phoneDigits.length > 10
          ? phoneDigits.substring(phoneDigits.length - 10)
          : phoneDigits,
    );
    _email = TextEditingController(text: technician.email);
    _about = TextEditingController(text: technician.about);
    _serviceArea = TextEditingController(
      text: technician.serviceAreas.join(', '),
    );
    _localImagePath = technician.localProfileImagePath;
    _localImageBytes = technician.localProfileImageBytes;
    _recoverLostImage();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _about.dispose();
    _serviceArea.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      (_localImagePath?.isNotEmpty ?? false) ||
      (_localImageBytes?.isNotEmpty ?? false) ||
      (widget.technician.profileImageUrl?.trim().isNotEmpty ?? false);

  Future<void> _recoverLostImage() async {
    final response = await _picker.retrieveLostData();
    if (!mounted || response.isEmpty || response.files == null) return;
    final file = response.files!.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _localImagePath = file.path;
      _localImageBytes = bytes;
      _photoError = null;
    });
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = source == ImageSource.gallery
          ? await _picker.pickMedia(imageQuality: 85)
          : await _picker.pickImage(source: source, imageQuality: 85);
      if (!mounted || image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _localImagePath = image.path;
        _localImageBytes = bytes;
        _photoError = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'camera_access_denied' ||
                    error.code == 'photo_access_denied'
                ? 'Photo access was denied. Enable it in device settings.'
                : 'Unable to select a profile picture (${error.code}).',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select a profile picture. Try again.'),
        ),
      );
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^9\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number starting with 9.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (email != email.toLowerCase()) {
      return 'Email must use lowercase letters only.';
    }
    final valid = RegExp(
      r'^[a-z0-9]+(?:[._][a-z0-9]+)*@[a-z0-9]+(?:-[a-z0-9]+)*(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)+$',
    ).hasMatch(email);
    return valid ? null : 'Enter a valid email without special symbols.';
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!_hasPhoto) {
      setState(() => _photoError = 'Profile picture is required.');
    }
    if (!valid || !_hasPhoto) return;

    setState(() => _isSaving = true);

    try {
      // Build the service_area string — join comma-separated areas as a single string
      final serviceAreaText = _serviceArea.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(', ');

      // PUT /api/auth/worker/profile/
      await WorkerDashboardService().updateProfile(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        about: _about.text.trim(),
        serviceArea: serviceAreaText,
      );

      if (!mounted) return;

      // Return the updated TechnicianModel to the calling screen
      Navigator.pop(
        context,
        widget.technician.copyWith(
          fullName: _name.text.trim(),
          phone: '+977 ${_phone.text.trim()}',
          email: _email.text.trim(),
          about: _about.text.trim(),
          localProfileImagePath: _localImagePath,
          localProfileImageBytes: _localImageBytes,
          serviceAreas: _serviceArea.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _avatar() {
    Widget image;
    if (_localImageBytes?.isNotEmpty ?? false) {
      image = Image.memory(
        _localImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(),
      );
    } else if (_localImagePath?.isNotEmpty ?? false) {
      image = Image.file(
        File(_localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(),
      );
    } else if (widget.technician.profileImageUrl?.trim().isNotEmpty ?? false) {
      image = Image.network(
        widget.technician.profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(),
      );
    } else {
      image = _fallbackAvatar();
    }
    return ClipOval(child: SizedBox.square(dimension: 112, child: image));
  }

  Widget _fallbackAvatar() => Image.asset(
    'assets/images/technician_avatar.png',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: AppColors.lightPurple,
      child: Icon(Icons.person, size: 58, color: AppColors.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _avatar(),
                      Positioned(
                        right: -4,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _chooseSource,
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_photoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _photoError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                _field(_name, 'Full name', validator: _required),
                _field(
                  _phone,
                  'Phone number',
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                _field(
                  _email,
                  'Email',
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(_about, 'About Me', validator: _required, maxLines: 4),
                _field(_serviceArea, 'Service areas (optional)', maxLines: 2),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
