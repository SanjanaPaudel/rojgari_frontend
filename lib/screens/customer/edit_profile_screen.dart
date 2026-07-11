import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';

class EditableCustomerProfile {
  const EditableCustomerProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.localImagePath,
  });

  final String name;
  final String address;
  final String phone;
  final String email;
  final String? localImagePath;
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
  static const _countries = <_CountryCode>[
    _CountryCode(name: 'Nepal', flag: '🇳🇵', dialCode: '+977', digits: 10),
    _CountryCode(name: 'India', flag: '🇮🇳', dialCode: '+91', digits: 10),
    _CountryCode(name: 'USA/Canada', flag: '🇺🇸', dialCode: '+1', digits: 10),
    _CountryCode(
      name: 'United Kingdom',
      flag: '🇬🇧',
      dialCode: '+44',
      digits: 10,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late _CountryCode _selectedCountry;
  String? _selectedImagePath;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedCountry = _countryFromPhone(widget.profile.phone);
    _phoneController = TextEditingController(
      text: _localNumber(widget.profile.phone, _selectedCountry),
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
    if (digits.length != _selectedCountry.digits) {
      return 'Enter a valid ${_selectedCountry.digits}-digit number';
    }
    if (_selectedCountry.dialCode == '+977' && !digits.startsWith('9')) {
      return 'Nepal mobile numbers must start with 9';
    }
    if (_selectedCountry.dialCode == '+91' &&
        !RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  _CountryCode _countryFromPhone(String phone) {
    final compact = phone.replaceAll(RegExp(r'[\s-]'), '');
    for (final country in _countries) {
      if (compact.startsWith(country.dialCode)) return country;
    }
    return _countries.first;
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
      setState(() => _selectedImagePath = image.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the photo library.')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // BACKEND TODO: PATCH /customer/profile (or the backend endpoint provided)
    // with {name, phone, email}; address is managed by CustomerAddressSheet.
    // Read the access token from
    // StorageService, send Authorization: Bearer <accessToken>, and only return
    // updated data to the profile after a successful response. Show an error
    // message and retain the form when the request fails.
    // Send phone as the selected dial code plus local number (E.164-style,
    // for example +9779841234567). If the backend expects separate fields,
    // send country_code and phone_number separately and map both in UserModel.
    //
    // PHOTO UPLOAD TODO: Use the selected image with multipart/form-data under
    // a field such as `profile_image`. Read the returned URL, save it in
    // UserModel, and refresh the displayed Image.network. Always retain
    // assets/images/customer.png plus errorBuilder as the broken-URL fallback.
    Navigator.pop(
      context,
      EditableCustomerProfile(
        name: _nameController.text.trim(),
        address: widget.profile.address,
        phone: '${_selectedCountry.dialCode} ${_phoneController.text.trim()}',
        email: _emailController.text.trim(),
        localImagePath: _selectedImagePath,
      ),
    );
  }

  ImageProvider _photoProvider() {
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
                              SizedBox(
                                width: 122,
                                child: DropdownButtonFormField<_CountryCode>(
                                  initialValue: _selectedCountry,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Country',
                                    filled: true,
                                    fillColor: const Color(0xFFFAF9FD),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
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
                                  items: _countries
                                      .map(
                                        (country) => DropdownMenuItem(
                                          value: country,
                                          child: Text(
                                            '${country.flag} ${country.dialCode}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (country) {
                                    if (country == null) return;
                                    setState(() => _selectedCountry = country);
                                    _formKey.currentState?.validate();
                                  },
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
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Save Changes'),
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
