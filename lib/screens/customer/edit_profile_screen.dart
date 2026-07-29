import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../services/customer_profile_service.dart';

class EditableCustomerProfile {
  const EditableCustomerProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.localImagePath,
    this.networkImageUrl,
  });

  final String name;
  final String address;
  final String phone;
  final String email;
  final String? localImagePath;
  final String? networkImageUrl;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.assetImagePath,
    this.networkImageUrl,
  });

  final EditableCustomerProfile profile;
  final String assetImagePath;
  final String? networkImageUrl;

  static Future<EditableCustomerProfile?> show(
    BuildContext context, {
    required EditableCustomerProfile profile,
    required String assetImagePath,
    String? networkImageUrl,
  }) {
    return showModalBottomSheet<EditableCustomerProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileScreen(
        profile: profile,
        assetImagePath: assetImagePath,
        networkImageUrl: networkImageUrl,
      ),
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // The backend only validates/stores Nepal-format numbers (see
  // validate_nepal_phone: "+977" + 10 digits, no separator) — the login
  // lookup itself depends on that exact format, so this is no longer a
  // user-selectable option.
  static const _nepal = _CountryCode(
    name: 'Nepal',
    flag: '🇳🇵',
    dialCode: '+977',
    digits: 10,
  );

  final _formKey = GlobalKey<FormState>();
  final CustomerProfileService _profileService = CustomerProfileService();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _photoChanged = false;
  bool _pickingImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(
      text: _localNumber(widget.profile.phone, _nepal),
    );
    _emailController = TextEditingController(text: widget.profile.email);
    _selectedImagePath = widget.profile.localImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'Email');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (email != email.toLowerCase()) {
      return 'Email must use lowercase letters';
    }
    if (email.contains('..')) return 'Email cannot contain consecutive dots';
    final valid = RegExp(
      r'^[a-z0-9](?:[a-z0-9._%+-]*[a-z0-9])?@[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$',
    ).hasMatch(email);
    return valid ? null : 'Enter a valid email address';
  }

  String? _validatePhone(String? value) {
    final requiredError = _required(value, 'Phone number');
    if (requiredError != null) return requiredError;

    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length != _nepal.digits) {
      return 'Enter a valid ${_nepal.digits}-digit number';
    }
    if (!digits.startsWith('9')) {
      return 'Nepal mobile numbers must start with 9';
    }
    return null;
  }

  String _localNumber(String phone, _CountryCode country) {
    var compact = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (compact.startsWith(country.dialCode)) {
      compact = compact.substring(country.dialCode.length);
    }
    return compact;
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      // image_picker is already declared in pubspec.yaml. This local state is
      // temporary; keep the XFile path until the backend upload succeeds.
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      // Read bytes up front via XFile (not dart:io File) — on web, .path is
      // a blob: URL and File() throws UnsupportedError for any operation.
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImagePath = image.path;
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _photoChanged = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the photo library.')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // Upload the photo first (if changed) — it doesn't depend on the
      // name/phone update, so a failure here leaves nothing half-saved.
      String? uploadedPhotoUrl;
      if (_photoChanged && _selectedImageBytes != null) {
        final rawPhotoPath = await _profileService.uploadProfilePhoto(
          imageBytes: _selectedImageBytes!,
          imageName: _selectedImageName ?? 'profile_photo.jpg',
        );
        if (rawPhotoPath != null) {
          uploadedPhotoUrl = ApiUrls.resolveMediaUrl(rawPhotoPath);
        }
      }

      // Bare 10 digits, no "+977" — signup/login never actually normalize
      // to a "+977"-prefixed value (validate_nepal_phone is wired as a
      // DRF field validator, so its return value is discarded; only the
      // raw submitted string is stored/matched). phone_number doubles as
      // the login lookup key (USERNAME_FIELD), so this must match that
      // bare-digit convention or the account becomes unloginable.
      final updated = await _profileService.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;

      Navigator.pop(
        context,
        EditableCustomerProfile(
          name: updated.fullName,
          address: widget.profile.address,
          phone: updated.phoneNumber,
          // The backend doesn't accept email updates on this endpoint —
          // reflect the server's real value, not whatever was typed here,
          // so the form never claims a change that didn't actually save.
          email: updated.email,
          // Once the photo is confirmed uploaded, drop the local file path
          // so the UI displays the persisted server copy instead of a
          // stale local file — same reasoning as the worker profile photo
          // upload.
          localImagePath: uploadedPhotoUrl != null ? null : _selectedImagePath,
          networkImageUrl: uploadedPhotoUrl ?? widget.networkImageUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  ImageProvider _photoProvider() {
    // Prefer in-memory bytes (cross-platform, incl. web) — falls back to
    // FileImage only for a path carried over from a previous native-only
    // session where bytes were never cached.
    if (_selectedImageBytes != null) return MemoryImage(_selectedImageBytes!);
    if (_selectedImagePath != null) return FileImage(File(_selectedImagePath!));
    final url = widget.networkImageUrl?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return AssetImage(widget.assetImagePath);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 22, 22, keyboard + 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: AppColors.lightPurple,
                                  backgroundImage: _photoProvider(),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: 2,
                                  child: IconButton.filled(
                                    tooltip: 'Change profile photo',
                                    onPressed: _pickingImage
                                        ? null
                                        : _pickImage,
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _pickingImage
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.camera_alt_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _pickingImage ? null : _pickImage,
                            child: const Text('Change profile photo'),
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            controller: _nameController,
                            label: 'Customer name',
                            icon: Icons.person_outline_rounded,
                            validator: (value) => _required(value, 'Name'),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Static display only — no dropdown, since
                              // Nepal is the only supported country. Uses
                              // InputDecorator (the same decoration chrome
                              // TextFormField uses internally) so the
                              // "Country" label/border matches the phone
                              // field beside it.
                              SizedBox(
                                width: 108,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Country',
                                    filled: true,
                                    fillColor: const Color(0xFFFAF9FD),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${_nepal.flag} ${_nepal.dialCode}',
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProfileField(
                                  controller: _phoneController,
                                  label: 'Phone number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: _validatePhone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            controller: _emailController,
                            label: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    required this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFFAF9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _CountryCode {
  const _CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.digits,
  });

  final String name;
  final String flag;
  final String dialCode;
  final int digits;
}
