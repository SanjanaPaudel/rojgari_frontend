import 'package:flutter/material.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../models/technician_model.dart';
import '../../models/worker_dashboard_response.dart';
import '../../services/worker_dashboard_service.dart';

import '../../widgets/technician/dashboard_appbar.dart';
import '../../widgets/technician/profile_header.dart';
import '../../widgets/technician/stat_card.dart';
import '../../widgets/technician/request_card.dart';
import '../../widgets/technician/pro_tip_card.dart';
import 'profile_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({
    super.key,
    this.initialTechnician,
    this.signupSelectedSkills,
  });

  final TechnicianModel? initialTechnician;
  final List<String>? signupSelectedSkills;

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  final WorkerDashboardService _dashboardService = WorkerDashboardService();

  WorkerDashboardResponse? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  late bool isOnline;
  late TechnicianModel _profile;

  // Requests list remains local until a dedicated requests API is available.
  final List<Map<String, String>> requests = [
    {
      "title": "Plumbing Service",
      "location": "Lazimpat, Kathmandu",
      "issue": "Leaking in bathroom pipe",
      "time": "Posted 5 mins ago",
      "image": "assets/images/plumbing_icon.png",
    },
    {
      "title": "Electrician Service",
      "location": "Maitidevi, Kathmandu",
      "issue": "Switch board not working",
      "time": "Posted 12 mins ago",
      "image": "assets/images/electrician_icon.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set safe defaults before the API responds.
    isOnline = false;
    _profile =
        widget.initialTechnician ??
        TechnicianModel(
          fullName: '',
          phone: '',
          email: '',
          about: '',
          selectedSkills: widget.signupSelectedSkills ?? const [],
        );
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _dashboardService.fetchDashboard();
      final profile = await _dashboardService.getProfile();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
        isOnline = dashboard.worker.isOnline;
        // Merge the complete profile data with dashboard skills/verification
        _profile = profile.copyWith(
          selectedSkills: List<String>.from(dashboard.worker.skills),
          verificationStatus: dashboard.worker.verified
              ? TechnicianVerificationStatus.verified
              : TechnicianVerificationStatus.incomplete,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Resolves a profile photo URL/path from the API into a usable URL string.
  /// Returns null when the backend sends null (no photo uploaded yet).
  String? _resolvePhotoUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // Relative path from Django media — prefix with base URL.
    final base = ApiUrls.baseUrl.replaceFirst('/api', '');
    return '$base$raw';
  }

  TechnicianModel _buildProfileFromDashboard(WorkerDashboardResponse d) {
    final verification = d.worker.verified
        ? TechnicianVerificationStatus.verified
        : TechnicianVerificationStatus.incomplete;

    return TechnicianModel(
      fullName: d.worker.fullName,
      phone: d.worker.phoneNumber,
      email: '',
      about: '',
      profileImageUrl: _resolvePhotoUrl(d.worker.profilePhoto),
      selectedSkills: d.worker.skills,
      verificationStatus: verification,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorBody(message: _errorMessage!, onRetry: _loadDashboard)
            : _DashboardBody(
                dashboard: _dashboard!,
                profile: _profile,
                isOnline: isOnline,
                requests: requests,
                onStatusChanged: (newStatus) async {
                  // 1. Update UI immediately (optimistic update) for instant feel
                  setState(() => isOnline = newStatus);

                  try {
                    // 2. Inform backend: PATCH /worker/status/ {"is_online": newStatus}
                    await _dashboardService.updateOnlineStatus(newStatus);
                  } catch (e) {
                    // 3. Rollback if the API call failed
                    if (!mounted) return;
                    setState(() => isOnline = !newStatus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                },
                onProfileUpdated: (updatedProfile) {
                  setState(() => _profile = updatedProfile);
                },
                onMenuTap: () async {
                  final updatedProfile = await Navigator.push<TechnicianModel>(
                    context,
                    MaterialPageRoute<TechnicianModel>(
                      builder: (_) => TechnicianProfileScreen(
                        initialSelectedSkills: _profile.selectedSkills,
                        dashboardResponse: _dashboard,
                      ),
                    ),
                  );
                  if (!mounted || updatedProfile == null) return;
                  setState(() => _profile = updatedProfile);
                },
                resolvePhotoUrl: _resolvePhotoUrl,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted stateless body — keeps the build method lean.
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.profile,
    required this.isOnline,
    required this.requests,
    required this.onStatusChanged,
    required this.onProfileUpdated,
    required this.onMenuTap,
    required this.resolvePhotoUrl,
  });

  final WorkerDashboardResponse dashboard;
  final TechnicianModel profile;
  final bool isOnline;
  final List<Map<String, String>> requests;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<TechnicianModel> onProfileUpdated;
  final VoidCallback onMenuTap;
  final String? Function(String?) resolvePhotoUrl;

  @override
  Widget build(BuildContext context) {
    final w = dashboard.worker;
    final stats = w.stats;
    final avatarUrl = resolvePhotoUrl(w.profilePhoto);
    final avatarImage = avatarUrl ?? 'assets/images/technician_avatar.png';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 0),

          Transform.translate(
            offset: const Offset(0, -3),
            child: DashboardAppbar(
              messageCount: dashboard.messages,
              notificationCount: dashboard.notifications,
              onMenuTap: onMenuTap,
              onMessageTap: () {
                // NAVIGATION PLACE:
                // Later create messages page and use:
                // Navigator.pushNamed(context, AppRoutes.messages);
                debugPrint('Messages clicked');
              },
              onNotificationTap: () {
                // NAVIGATION PLACE:
                // Later create notifications page and use:
                // Navigator.pushNamed(context, AppRoutes.notifications);
                debugPrint('Notifications clicked');
              },
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: ProfileHeader(
              name: w.fullName.trim().split(RegExp(r'\s+')).first,
              rating: stats.rating,
              yearsOfExperience: w.yearsOfExperience,
              isVerified: w.verified,
              avatarImage: avatarImage,
              avatarBytes: profile.localProfileImageBytes,
              isOnline: isOnline,
              onStatusChanged: onStatusChanged,
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(12, 5, 12, 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xffEEEEEE)),
            ),
            child: Row(
              children: [
                StatCard(
                  number: stats.jobsDone.toString(),
                  title: 'Jobs Done',
                  subtitle: 'This Month',
                  icon: Icons.work_outline,
                  iconColor: const Color(0xff6A35FF),
                  bgColor: const Color(0xffF4EEFF),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.skills.toString(),
                  title: 'Skills',
                  subtitle: 'Registered',
                  icon: Icons.sync,
                  iconColor: const Color(0xff246BFD),
                  bgColor: const Color(0xffEDF4FF),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.reviews.toString(),
                  title: 'Reviews',
                  subtitle: 'This Week',
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xffFF8C1A),
                  bgColor: const Color(0xffFFF1E6),
                ),

                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xffEEEEEE),
                ),

                StatCard(
                  number: stats.rating.toStringAsFixed(1),
                  title: 'Avg Rating',
                  subtitle: 'Out of 5',
                  icon: Icons.star_border,
                  iconColor: const Color(0xff246BFD),
                  bgColor: const Color(0xffEDF4FF),
                ),
              ],
            ),
          ),

          _IncomingRequestsSection(
            requests: requests,
            incomingCount: dashboard.incomingRequestCount,
          ),

          ProTipCard(
            onTap: () {
              // NAVIGATION PLACE:
              // Later create profile tips page and use:
              // Navigator.pushNamed(context, AppRoutes.profileTips);
              debugPrint('Pro Tip clicked');
            },
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incoming requests section
// ---------------------------------------------------------------------------

class _IncomingRequestsSection extends StatelessWidget {
  const _IncomingRequestsSection({
    required this.requests,
    required this.incomingCount,
  });

  final List<Map<String, String>> requests;
  final int incomingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xffEFE6FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xffFCFAFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Incoming Requests',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 7),

                          // Badge driven by API incoming_request_count.
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                incomingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'New requests near you',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xff5F6A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // NAVIGATION PLACE:
                    // Later create requests page and use:
                    // Navigator.pushNamed(context, AppRoutes.requests);
                    debugPrint('View All clicked');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];
              // BACKEND READY:
              // Later backend should send serviceTitle, location, issue,
              // postedTime, serviceType, and isNew.
              return RequestCard(
                title: request['title']!,
                location: request['location']!,
                issue: request['issue']!,
                time: request['time']!,
                image: request['image']!,
                onTap: () {
                  // NAVIGATION PLACE:
                  // Later create request detail page and use:
                  // Navigator.pushNamed(
                  //   context,
                  //   AppRoutes.requestDetail,
                  //   arguments: request,
                  // );
                  debugPrint('${request["title"]} clicked');
                },
              );
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
