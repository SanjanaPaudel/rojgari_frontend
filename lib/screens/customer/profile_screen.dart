import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../services/storage_service.dart';
import '../../widgets/customer/customer_address_sheet.dart';
import '../../widgets/customer/customer_profile_header.dart';
import '../../widgets/customer/logout_confirmation_dialog.dart';
import '../../widgets/customer/profile_menu_tile.dart';
import '../../widgets/customer/profile_photo_viewer.dart';
import '../auth/logIn_screen.dart';
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

  // TEMPORARY DUMMY DATA: replace this single local source with UserModel data.
  EditableCustomerProfile _profile = const EditableCustomerProfile(
    name: 'Sunita Shrestha',
    address: 'Kathmandu, Nepal',
    phone: '+977 9812345678',
    email: 'sunita.shrestha@email.com',
  );
  final bool _isVerified = true;
  String? _networkImageUrl;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    // BACKEND TODO: Fetch GET /customer/profile. Read the access token from
    // StorageService and send Authorization: Bearer <accessToken>. Parse the
    // response into UserModel, then populate name, address, phone, email,
    // verification status, and profile image URL. Show explicit loading and
    // error states while this request runs.
    //
    // VERIFICATION TODO: Do not hardcode verification after integration. Read
    // an isVerified boolean from UserModel/API and only show the verified badge
    // when it is true.
  }

  Future<void> _editProfile() async {
    final updated = await EditProfileScreen.show(
      context,
      profile: _profile,
      assetImagePath: _fallbackPhoto,
      networkImageUrl: _networkImageUrl,
    );
    if (!mounted || updated == null) return;
    // BACKEND TODO: The edit sheet currently returns locally edited values.
    // After PATCH /customer/profile is connected, return from the sheet only
    // after a successful response and build this state from the returned
    // UserModel. Keep the existing values and show the API error on failure.
    setState(() => _profile = updated);
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
      navigator.pop();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 14.0 : 20.0;
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
                                icon: const Icon(Icons.arrow_back_rounded),
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
                                subtitle: 'App settings and preferences',
                                onTap: () {
                                  // NAVIGATION TODO: Open the customer settings screen when available.
                                  _comingSoon('Settings');
                                },
                              ),
                              const Divider(height: 1, indent: 74),
                              ProfileMenuTile(
                                icon: Icons.help_outline_rounded,
                                title: 'Help & Support',
                                subtitle: 'Get help and contact support',
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
                          side: const BorderSide(color: Color(0xFFFFC9C5)),
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
    );
  }
}
