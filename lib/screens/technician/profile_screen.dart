import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../models/technician_model.dart';
import '../../models/worker_dashboard_response.dart';
import '../../services/storage_service.dart';
import '../../services/worker_dashboard_service.dart';
import '../../widgets/customer/logout_confirmation_dialog.dart';
import '../../widgets/customer/profile_menu_tile.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'identity_documents_screen.dart';
import 'technician_home_screen.dart';
import 'technician_skill_selection_screen.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({
    super.key,
    this.initialSelectedSkills,
    this.dashboardResponse,
  });

  // Skills returned by the technician signup skill selection screen, or from
  // the dashboard API. My Skills and Add Skill will read and update this.
  final List<String>? initialSelectedSkills;

  /// Dashboard API response used to seed the profile on first open.
  /// When provided, real API data (name, phone, photo, skills, verified status)
  /// is shown instead of placeholder text.
  final WorkerDashboardResponse? dashboardResponse;

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  static const _avatarAsset = 'assets/images/technician_avatar.png';

  // FRONTEND SESSION CACHE: This static model keeps edits, selected skills and
  // document bytes while the app is running, so reopening this screen does not
  // reset verification. It intentionally does not write citizenship images to
  // SharedPreferences or other insecure local storage. It resets on app/web
  // restart and is not a permanent source of truth.
  //
  // When a dashboardResponse is passed, the session is seeded from the API
  // on first open. Subsequent local edits (profile, skills, documents) update
  // the session cache exactly as before.
  static TechnicianModel? _sessionTechnician;
  late TechnicianModel _technician;
  bool _loggingOut = false;
  bool _isLoadingProfile = false;

  // ---------------------------------------------------------------------------
  // _loadProfile
  //
  // Calls GET /api/auth/worker/profile/ and merges the returned fields into
  // the existing model via copyWith.  The endpoint now also returns:
  //   • citizenship_front / citizenship_back URLs
  //   • is_verified flag
  // fromProfileJson() converts these into the correct TechnicianVerificationStatus:
  //   verified  → admin approved
  //   pending   → docs submitted, awaiting review
  //   incomplete → no docs uploaded yet
  //
  // All three values (verificationStatus, citizenshipFrontUrl, citizenshipBackUrl)
  // are merged into the live model so the profile screen always reflects the
  // real backend state after every refresh.
  // ---------------------------------------------------------------------------
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);
    try {
      final fetched = await WorkerDashboardService().getProfile();
      if (!mounted) return;
      // Merge all backend-supplied fields, including verification status and
      // citizenship document URLs that now come from the profile endpoint.
      final merged = _technician.copyWith(
        fullName: fetched.fullName,
        phone: fetched.phone,
        email: fetched.email,
        about: fetched.about,
        profileImageUrl: fetched.profileImageUrl ?? _technician.profileImageUrl,
        serviceAreas: fetched.serviceAreas,
        // These are the critical fields for pending-state persistence:
        citizenshipFrontUrl: fetched.citizenshipFrontUrl,
        citizenshipBackUrl: fetched.citizenshipBackUrl,
        verificationStatus: fetched.verificationStatus,
      );
      _updateTechnician(merged);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not refresh profile: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          action: SnackBarAction(label: 'Retry', onPressed: _loadProfile),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  /// Resolves a photo URL/path from the API into a usable string.
  static String? _resolvePhotoUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final base = ApiUrls.baseUrl.replaceFirst('/api', '');
    return '$base$raw';
  }

  @override
  void initState() {
    super.initState();

    // Seed session from dashboard API on first open (session is null).
    if (_sessionTechnician == null) {
      final d = widget.dashboardResponse;
      if (d != null) {
        // Seed basic data from the dashboard response.
        // verificationStatus is intentionally left at the default (incomplete)
        // here — _loadProfile() runs immediately below and will overwrite it
        // with the correct 3-way status (verified / pending / incomplete)
        // derived from the citizenship_front/back URLs that the profile
        // endpoint now returns.
        _sessionTechnician = TechnicianModel(
          fullName: d.worker.fullName,
          phone: d.worker.phoneNumber,
          email: '',
          about: '',
          profileImageUrl: _resolvePhotoUrl(d.worker.profilePhoto),
          selectedSkills: List<String>.from(d.worker.skills),
          verificationStatus: d.worker.verified
              ? TechnicianVerificationStatus.verified
              : TechnicianVerificationStatus.incomplete, // overwritten by _loadProfile below
        );
      } else {
        // Fallback to an empty placeholder when no API data is available yet.
        _sessionTechnician = TechnicianModel(
          fullName: '',
          phone: '',
          email: '',
          about: '',
          selectedSkills: const [],
        );
      }
    }

    // Honor skills passed from signup flow over the session cache.
    final incomingSkills = widget.initialSelectedSkills;
    if (incomingSkills != null) {
      _sessionTechnician = _sessionTechnician!.copyWith(
        selectedSkills: List<String>.from(incomingSkills),
      );
    }

    _technician = _sessionTechnician!;
    // Always fetch the latest profile from the backend on open.
    // This is what corrects verificationStatus to pending when docs are uploaded.
    _loadProfile();
  }

  void _updateTechnician(TechnicianModel technician) {
    setState(() {
      _technician = technician;
      _sessionTechnician = technician;
    });
  }

  void _backToDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(_technician);
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TechnicianHomeScreen(initialTechnician: _technician),
        ),
      );
    }
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push<TechnicianModel>(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianEditProfileScreen(technician: _technician),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      _updateTechnician(updated);
    }
    // Refresh to get the canonical profile photo URL and other backend details
    await _loadProfile();
  }

  void _viewProfilePhoto() {
    Widget image;
    final bytes = _technician.localProfileImageBytes;
    final localPath = _technician.localProfileImagePath;
    final networkUrl = _technician.profileImageUrl?.trim();
    if (bytes?.isNotEmpty ?? false) {
      image = Image.memory(bytes!, fit: BoxFit.contain);
    } else if (localPath?.isNotEmpty ?? false) {
      image = Image.file(
        File(localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Image.asset(_avatarAsset, fit: BoxFit.contain),
      );
    } else if (networkUrl?.isNotEmpty ?? false) {
      image = Image.network(
        networkUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Image.asset(_avatarAsset, fit: BoxFit.contain),
      );
    } else {
      image = Image.asset(_avatarAsset, fit: BoxFit.contain);
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 440,
              maxHeight: 560,
              minHeight: 300,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: image),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: 'Close photo',
                    onPressed: () => Navigator.pop(dialogContext),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editSkills() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianSkillSelectionScreen(
          initiallySelected: _technician.selectedSkills,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    _updateTechnician(_technician.copyWith(selectedSkills: selected));
  }

  Future<void> _openDocuments() async {
    final result = await Navigator.push<IdentityDocumentsResult>(
      context,
      MaterialPageRoute(
        builder: (_) => IdentityDocumentsScreen(
          hasExistingFront:
              _technician.citizenshipFrontUrl?.trim().isNotEmpty ?? false,
          hasExistingBack:
              _technician.citizenshipBackUrl?.trim().isNotEmpty ?? false,
          existingExperienceCertificateUrl:
              _technician.experienceCertificateUrl,
          existingCitizenshipFrontUrl: _technician.citizenshipFrontUrl,
          existingCitizenshipBackUrl: _technician.citizenshipBackUrl,
          verificationStatus: _technician.verificationStatus,
          citizenshipFrontBytes: _technician.localCitizenshipFrontBytes,
          citizenshipFrontName: _technician.localCitizenshipFrontName,
          citizenshipBackBytes: _technician.localCitizenshipBackBytes,
          citizenshipBackName: _technician.localCitizenshipBackName,
          experienceCertificateBytes:
              _technician.localExperienceCertificateBytes,
          experienceCertificateName: _technician.localExperienceCertificateName,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _updateTechnician(
      _technician.copyWith(
        hasLocalCitizenshipFront: result.citizenshipFrontUrl == null ? result.hasCitizenshipFront : false,
        hasLocalCitizenshipBack: result.citizenshipBackUrl == null ? result.hasCitizenshipBack : false,
        localCitizenshipFrontBytes: result.citizenshipFrontUrl == null ? result.citizenshipFrontBytes : null,
        localCitizenshipFrontName: result.citizenshipFrontUrl == null ? result.citizenshipFrontName : null,
        localCitizenshipBackBytes: result.citizenshipBackUrl == null ? result.citizenshipBackBytes : null,
        localCitizenshipBackName: result.citizenshipBackUrl == null ? result.citizenshipBackName : null,
        localExperienceCertificateBytes: result.experienceCertificateUrl == null ? result.experienceCertificateBytes : null,
        localExperienceCertificateName: result.experienceCertificateUrl == null ? result.experienceCertificateName : null,
        citizenshipFrontUrl: result.citizenshipFrontUrl ?? _technician.citizenshipFrontUrl,
        citizenshipBackUrl: result.citizenshipBackUrl ?? _technician.citizenshipBackUrl,
        experienceCertificateUrl: result.experienceCertificateUrl ?? _technician.experienceCertificateUrl,
        verificationStatus: result.verificationStatus ?? _technician.verificationStatus,
      ),
    );
  }

  Future<void> _completeProfile() async {
    if (!_technician.hasProfileImage) {
      await _editProfile();
      return;
    }
    await _openDocuments();
  }

  Future<void> _logout() async {
    final confirmed = await LogoutConfirmationDialog.show(context);
    if (!mounted || !confirmed) return;
    setState(() => _loggingOut = true);
    try {
      // AuthService currently has no logout method. Reuse the existing customer
      // flow by clearing secure authentication storage through StorageService.
      // BACKEND TODO: Revoke the refresh token when logout API support exists.
      await StorageService.clearTokens();
      _sessionTechnician = null;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  void _comingSoon(String section) {
    // NAVIGATION TODO: Replace this SnackBar with Navigator.push/route-name
    // navigation when the matching worker-profile section screen is created.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$section will be available soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 380 ? 14.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 4, padding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileAppBar(onBack: _backToDashboard),
                      if (_isLoadingProfile)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                            backgroundColor: Color(0xFFF5F0FF),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _TechnicianProfileHeader(
                        technician: _technician,
                        avatarAsset: _avatarAsset,
                        onEdit: _editProfile,
                        onViewPhoto: _viewProfilePhoto,
                      ),
                      if (_technician.verificationStatus != TechnicianVerificationStatus.verified) ...[
                        const SizedBox(height: 14),
                        _CompletionWarning(
                          verificationStatus: _technician.verificationStatus,
                          onComplete: _completeProfile,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('About Me', style: _Styles.sectionTitle),
                            const SizedBox(height: 7),
                            Text(
                              _technician.about.isEmpty
                                  ? 'No about information specified'
                                  : _technician.about,
                              style: _Styles.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Service Area', style: _Styles.sectionTitle),
                            const SizedBox(height: 7),
                            Text(
                              _technician.serviceAreas.isEmpty
                                  ? 'No service areas specified'
                                  : _technician.serviceAreas.join(', '),
                              style: _Styles.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SkillsCard(
                        skills: _technician.selectedSkills,
                        onAdd: _editSkills,
                      ),
                      const SizedBox(height: 14),
                      _menuCard(),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _loggingOut ? null : _logout,
                        icon: _loggingOut
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          backgroundColor: const Color(0xFFFFF7F6),
                          side: const BorderSide(color: Color(0xFFFFD2CE)),
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
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

  Widget _menuCard() {
    final items = [
      (Icons.work_outline, 'Work Experience', 'Manage your work experience'),
      (
        Icons.badge_outlined,
        'Identity Documents',
        _technician.identityDocumentSubtitle,
      ),
      (
        Icons.location_on_outlined,
        'Service Areas',
        'Manage areas where you provide services',
      ),
      (Icons.settings_outlined, 'Settings', 'App settings and preferences'),
      (
        Icons.headset_mic_outlined,
        'Help & Support',
        'Get help and contact support',
      ),
      (Icons.info_outline, 'About Rojgari', 'Learn more about Rojgari'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ProfileMenuTile(
                icon: items[index].$1,
                title: items[index].$2,
                subtitle: items[index].$3,
                trailingText: items[index].$2 == 'About Rojgari'
                    ? 'v1.0.0'
                    : null,
                onTap: items[index].$2 == 'Identity Documents'
                    ? _openDocuments
                    : () => _comingSoon(items[index].$2),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 74),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const Text('My Profile', style: _Styles.appBarTitle),
        ],
      ),
    );
  }
}

class _TechnicianProfileHeader extends StatelessWidget {
  const _TechnicianProfileHeader({
    required this.technician,
    required this.avatarAsset,
    required this.onEdit,
    required this.onViewPhoto,
  });

  final TechnicianModel technician;
  final String avatarAsset;
  final VoidCallback onEdit;
  final VoidCallback onViewPhoto;

  Widget _avatar() {
    Widget image;
    final local = technician.localProfileImagePath;
    final localBytes = technician.localProfileImageBytes;
    if (localBytes?.isNotEmpty ?? false) {
      image = Image.memory(
        localBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetAvatar(),
      );
    } else if (local?.isNotEmpty ?? false) {
      image = Image.file(
        File(local!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetAvatar(),
      );
    } else if (technician.profileImageUrl?.trim().isNotEmpty ?? false) {
      image = Image.network(
        technician.profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetAvatar(),
      );
    } else {
      image = _assetAvatar();
    }
    return ClipOval(child: image);
  }

  Widget _assetAvatar() => Image.asset(
    avatarAsset,
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: AppColors.lightPurple,
      child: Icon(Icons.person, color: AppColors.primary, size: 62),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEEAF9)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 115,
            child: Opacity(
              opacity: .22,
              child: Image.asset(
                'assets/images/technician_profile_header_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 430;
              return narrow ? _narrowHeader() : _wideHeader();
            },
          ),
        ],
      ),
    );
  }

  Widget _photo(double size) => Stack(
    clipBehavior: Clip.none,
    children: [
      Semantics(
        button: true,
        label: 'View full profile photo',
        child: GestureDetector(
          onTap: onViewPhoto,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8E3F3), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _avatar(),
          ),
        ),
      ),
      Positioned(
        right: -3,
        bottom: 2,
        child: IconButton.filled(
          tooltip: 'Edit profile picture',
          onPressed: onEdit,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
          icon: const Icon(Icons.camera_alt_outlined, size: 19),
        ),
      ),
    ],
  );

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        technician.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _Styles.name,
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          Icon(
            technician.verificationStatus ==
                        TechnicianVerificationStatus.verified ||
                    technician.canAcceptJobs
                ? Icons.verified_user_outlined
                : Icons.hourglass_top_rounded,
            color: AppColors.primary,
            size: 17,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              technician.verificationLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      _contact(Icons.phone_outlined, technician.phone),
      const SizedBox(height: 5),
      _contact(Icons.email_outlined, technician.email),
    ],
  );

  Widget _contact(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.grey),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _editButton() => OutlinedButton.icon(
    onPressed: onEdit,
    icon: const Icon(Icons.edit_outlined, size: 17),
    label: const Text('Edit Profile'),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      backgroundColor: Colors.white.withValues(alpha: .9),
      side: const BorderSide(color: AppColors.primary),
      visualDensity: VisualDensity.compact,
    ),
  );

  Widget _narrowHeader() => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _photo(104),
          const SizedBox(width: 16),
          Expanded(child: _details()),
        ],
      ),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerRight, child: _editButton()),
    ],
  );

  Widget _wideHeader() => Row(
    children: [
      _photo(132),
      const SizedBox(width: 22),
      Expanded(child: _details()),
      const SizedBox(width: 12),
      _editButton(),
    ],
  );
}

class _CompletionWarning extends StatelessWidget {
  const _CompletionWarning({
    required this.verificationStatus,
    required this.onComplete,
  });

  final TechnicianVerificationStatus verificationStatus;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isPending = verificationStatus == TechnicianVerificationStatus.pending;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD77A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPending
                  ? 'Your documents have been submitted and are pending review.'
                  : 'Complete your profile and citizenship documents before accepting jobs.',
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isPending ? null : onComplete,
            child: Text(isPending ? 'Pending' : 'Complete Now'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEAF9)),
        boxShadow: const [BoxShadow(color: Color(0x0A231447), blurRadius: 14)],
      ),
      child: child,
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills, required this.onAdd});
  final List<String> skills;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('My Skills', style: _Styles.sectionTitle),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Skill'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (skills.isEmpty)
            const Text('No skills selected yet', style: _Styles.body)
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: skills
                  .map(
                    (skill) => Chip(
                      avatar: Icon(
                        _skillIcon(skill),
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(skill),
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: const Color(0xFFF5F0FF),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  static IconData _skillIcon(String skill) => switch (skill.toLowerCase()) {
    'plumbing' => Icons.plumbing,
    'electrician' => Icons.electric_bolt,
    'gardening' => Icons.eco_outlined,
    'painting' => Icons.format_paint_outlined,
    'carpenter' => Icons.handyman_outlined,
    'mechanic' => Icons.build_outlined,
    'computer repair' => Icons.computer_outlined,
    'tv repair' => Icons.tv_outlined,
    'maid/cleaning' => Icons.cleaning_services_outlined,
    'ac repair' => Icons.ac_unit_outlined,
    _ => Icons.handyman_outlined,
  };
}

abstract final class _Styles {
  static const appBarTitle = TextStyle(
    color: AppColors.black,
    fontSize: 21,
    fontWeight: FontWeight.w700,
  );
  static const name = TextStyle(
    color: AppColors.black,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const sectionTitle = TextStyle(
    color: AppColors.black,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    color: AppColors.grey,
    fontSize: 13,
    height: 1.5,
  );
}
