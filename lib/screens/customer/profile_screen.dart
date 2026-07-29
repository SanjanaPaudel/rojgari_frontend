import 'package:flutter/material.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../models/customer_profile_model.dart';
import '../../services/customer_profile_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/customer/customer_address_sheet.dart';
import '../../widgets/customer/customer_profile_header.dart';
import '../../widgets/customer/logout_confirmation_dialog.dart';
import '../../widgets/customer/profile_menu_tile.dart';
import '../../widgets/customer/profile_photo_viewer.dart';
import '../auth/login_screen.dart';
import 'customer_home_screen.dart';
import 'edit_profile_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  static const _fallbackPhoto =
      'assets/images/customer_profile_placeholder.png';
  static const _photoHeroTag = 'customer-profile-photo';

  // Address isn't part of GET /customer/profile — left empty until a real
  // address source (e.g. CustomerAddressSheet's persistence) is wired up.
  EditableCustomerProfile _profile = const EditableCustomerProfile(
    name: '',
    address: '',
    phone: '',
    email: '',
  );
  bool _isVerified = false;
  String? _networkImageUrl;
  bool _loggingOut = false;
  bool _isLoading = true;
  String? _errorMessage;
  final CustomerProfileService _profileService = CustomerProfileService();

  // Raw server model, kept alongside the split display fields above so the
  // dashboard can receive the exact server-confirmed data when this screen
  // pops — mirrors TechnicianProfileScreen popping with its TechnicianModel.
  CustomerProfileModel? _serverProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = EditableCustomerProfile(
          name: profile.fullName,
          address: _profile.address,
          phone: profile.phoneNumber,
          email: profile.email,
        );
        _isVerified = profile.isVerified;
        _networkImageUrl = profile.profilePhoto == null
            ? null
            : ApiUrls.resolveMediaUrl(profile.profilePhoto!);
        _isLoading = false;
        _serverProfile = profile;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _editProfile() async {
    final updated = await EditProfileScreen.show(
      context,
      profile: _profile,
      assetImagePath: _fallbackPhoto,
      networkImageUrl: _networkImageUrl,
    );
    if (!mounted || updated == null) return;
    // EditProfileScreen only pops with real data once its own PATCH
    // /customer/profile/update/ call succeeds (see EditProfileScreen._save),
    // so this is already the server-confirmed profile.
    setState(() {
      _profile = updated;
      // resolveMediaUrl() is idempotent on an already-absolute URL, so
      // storing the resolved value back into profilePhoto here is safe —
      // a future _loadProfile() re-resolve is a no-op.
      final updatedPhoto = updated.networkImageUrl ?? _serverProfile?.profilePhoto;
      if (updated.networkImageUrl != null) {
        _networkImageUrl = updated.networkImageUrl;
      }
      // Keep id/isVerified from the last known server model — the edit
      // form never touches those.
      _serverProfile = CustomerProfileModel(
        id: _serverProfile?.id ?? 0,
        fullName: updated.name,
        phoneNumber: updated.phone,
        email: updated.email,
        isVerified: _isVerified,
        profilePhoto: updatedPhoto,
      );
    });
  }

  Future<void> _manageAddress() async {
    final address = await CustomerAddressSheet.show(
      context,
      initialAddress: _profile.address,
    );
    if (!mounted || address == null) return;
    // BACKEND TODO: Once address persistence is implemented, update this local
    // profile only with the address returned by the successful API response.
    // Do not show the success message when the request fails.
    setState(
      () => _profile = EditableCustomerProfile(
        name: _profile.name,
        address: address,
        phone: _profile.phone,
        email: _profile.email,
        localImagePath: _profile.localImagePath,
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Address updated.')));
  }

  Future<void> _logout() async {
    final confirmed = await LogoutConfirmationDialog.show(context);
    if (!mounted || !confirmed) return;
    setState(() => _loggingOut = true);
    try {
      // BACKEND TODO: If supported, revoke/invalidate the refresh token with a
      // backend logout request before deleting local credentials.
      // clearTokens currently calls secureStorage.deleteAll(), clearing access
      // token, refresh token, saved role, next-screen value, and any cached
      // customer profile stored in the same secure storage. If separate cache
      // storage is added, clear that customer profile here as well.
      await StorageService.clearTokens();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  void _showPhoto() {
    // Image.network is used for future backend URLs with the asset fallback and
    // errorBuilder in both the header and viewer, so a broken URL stays safe.
    ProfilePhotoViewer.show(
      context,
      heroTag: _photoHeroTag,
      assetPath: _fallbackPhoto,
      networkUrl: _networkImageUrl,
      localImagePath: _profile.localImagePath,
    );
  }

  void _openCustomerDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Hands the already-fetched server profile back to whoever pushed this
      // screen (CustomerHomeScreen), the same way TechnicianProfileScreen
      // pops with its TechnicianModel — no extra network call happens here.
      navigator.pop(_serverProfile);
      return;
    }

    // The profile is temporarily configured as `home` in main.dart for UI
    // testing. Replace that route with the existing dashboard so pressing the
    // Android back button does not reopen this temporary profile home route.
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CustomerHomeScreen()),
    );
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<CustomerProfileModel>(
      // Blocks the automatic pop from the system back button/gesture so it
      // funnels through the exact same _openCustomerDashboard() logic the
      // on-screen back arrow already uses — otherwise a system-back pop
      // returns null (no data), and the dashboard silently never learns
      // about a profile edit that actually saved successfully.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _openCustomerDashboard();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _ProfileErrorBody(
                  message: _errorMessage!,
                  onRetry: _loadProfile,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 380
                        ? 14.0
                        : 20.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        6,
                        horizontalPadding,
                        28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 58,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        tooltip: 'Back',
                                        onPressed: _openCustomerDashboard,
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'My Profile',
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomerProfileHeader(
                                name: _profile.name,
                                phone: _profile.phone,
                                email: _profile.email,
                                isVerified: _isVerified,
                                assetImagePath: _fallbackPhoto,
                                networkImageUrl: _networkImageUrl,
                                localImagePath: _profile.localImagePath,
                                heroTag: _photoHeroTag,
                                onPhotoTap: _showPhoto,
                                onEdit: _editProfile,
                              ),
                              const SizedBox(height: 34),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Material(
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      ProfileMenuTile(
                                        icon: Icons.location_on_outlined,
                                        title: 'Addresses',
                                        subtitle: 'Manage your saved addresses',
                                        onTap: _manageAddress,
                                      ),
                                      const Divider(height: 1, indent: 74),
                                      ProfileMenuTile(
                                        icon: Icons.settings_outlined,
                                        title: 'Settings',
                                        subtitle:
                                            'App settings and preferences',
                                        onTap: () {
                                          // NAVIGATION TODO: Open the customer settings screen when available.
                                          _comingSoon('Settings');
                                        },
                                      ),
                                      const Divider(height: 1, indent: 74),
                                      ProfileMenuTile(
                                        icon: Icons.help_outline_rounded,
                                        title: 'Help & Support',
                                        subtitle:
                                            'Get help and contact support',
                                        onTap: () {
                                          // NAVIGATION TODO: Open the support screen when available.
                                          _comingSoon('Help & Support');
                                        },
                                      ),
                                      const Divider(height: 1, indent: 74),
                                      ProfileMenuTile(
                                        icon: Icons.info_outline_rounded,
                                        title: 'About Rojgari',
                                        subtitle: 'Learn more about Rojgari',
                                        trailingText: 'v1.0.0',
                                        onTap: () {
                                          // NAVIGATION TODO: Open the about screen when available.
                                          _comingSoon('About Rojgari');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              OutlinedButton.icon(
                                onPressed: _loggingOut ? null : _logout,
                                icon: _loggingOut
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.logout_rounded),
                                label: const Text('Log Out'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.red,
                                  backgroundColor: const Color(0xFFFFF4F3),
                                  side: const BorderSide(
                                    color: Color(0xFFFFC9C5),
                                  ),
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ProfileErrorBody extends StatelessWidget {
  const _ProfileErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.black),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
