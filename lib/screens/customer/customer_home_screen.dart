import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/api_urls.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/models/category_model.dart';
import 'package:rojgari_frontend_one/models/customer/booking_history_item.dart';
import 'package:rojgari_frontend_one/models/customer_profile_model.dart';
import 'package:rojgari_frontend_one/screens/customer/customer_bookings_history_screen.dart';
import 'package:rojgari_frontend_one/screens/customer/profile_screen.dart';
import 'package:rojgari_frontend_one/screens/notifications_screen.dart';
import 'package:rojgari_frontend_one/services/api_service.dart';
import 'package:rojgari_frontend_one/services/customer_profile_service.dart';
import 'package:rojgari_frontend_one/services/fcm_service.dart';
import 'package:rojgari_frontend_one/widgets/category_card.dart';
import 'package:rojgari_frontend_one/widgets/customer/booking_history_card.dart';
import 'package:rojgari_frontend_one/screens/customer/service_request/service_request_screen.dart';
import '../../models/service_request/service_category.dart';
import 'package:rojgari_frontend_one/services/notification_service.dart';

void openServiceRequestPage(BuildContext context, ServiceCategory category) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ServiceRequestScreen(category: category)),
  );
}

String _temporaryCategorySlug(String title) => title
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final NotificationService _notificationService = NotificationService();
  int _notificationCount = 0;

  // The 3 most recent entries of the shared booking-history source — the
  // same list CustomerBookingsHistoryScreen ("View All") shows in full, so
  // this preview can never drift out of sync with it.
  static final List<BookingHistoryItem> _recentJobs = sampleBookingHistory
      .take(3)
      .toList();

  final CustomerProfileService _profileService = CustomerProfileService();
  CustomerProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount();
    // Fire-and-forget: shows the OS/browser notification permission prompt
    // after this screen has rendered, rather than blocking login/splash
    // navigation on it. See FcmService for why failures here are swallowed.
    FcmService.initialize();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // This is just the header greeting, not a page that should block on
      // a network error — it silently falls back to a nameless "Hello 👋"
      // (see _ProfileHeader) and the profile screen itself already shows
      // its own real error/retry state if something's actually wrong.
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.fetchUnreadCount();
      if (!mounted) return;
      setState(() => _notificationCount = count);
    } catch (_) {
      // Same reasoning as _loadProfile(): this is just a badge, not a
      // page that should block or show an error — it silently stays at
      // its last known value (0 on first load) if the fetch fails.
    }
  }

  // Re-fetches the unread count once the user comes back from the
  // notifications screen — NotificationsScreen is pushed on top of this one
  // rather than replacing it, so this screen's initState() (where the count
  // is normally loaded) never runs again on its own when popping back.
  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadUnreadCount();
  }

  /// Pushes the profile screen and applies whatever it pops with — mirrors
  /// TechnicianHomeScreen's onMenuTap: CustomerProfileScreen only pops with
  /// non-null data once it actually has a server-confirmed profile (see
  /// CustomerProfileScreen._openCustomerDashboard), so no extra fetch is
  /// needed here — just applying data that already came from the network.
  Future<void> _openProfile() async {
    final updated = await Navigator.push<CustomerProfileModel>(
      context,
      MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
    );
    if (!mounted || updated == null) return;
    setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TopBar(
                  notificationCount: _notificationCount,
                  onMenuTap: _openProfile,
                  onNotificationTap: _openNotifications,
                ),
              ),
              const SizedBox(height: 4),
              _ProfileHeader(userName: _profile?.fullName),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(title: 'Categories'),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _CategoryCarousel(),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Bookings',
                  trailing: _ViewAllButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerBookingsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: _recentJobs
                      .map(
                        (job) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookingHistoryCard(booking: job),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.notificationCount,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  final int notificationCount;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleIconButton(
              icon: Icons.menu_rounded,
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              iconSize: 30,
              onTap: onMenuTap,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo_text.png',
              height: 58,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  backgroundColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  iconSize: 30,
                  onTap: onNotificationTap,
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -1,
                    top: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userName});

  /// Null while the initial fetch (owned by _CustomerHomeScreenState) is
  /// still in flight or failed — falls back to a nameless greeting rather
  /// than blocking this header on a network error.
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim();
    final greeting = (name == null || name.isEmpty)
        ? 'Hello 👋'
        : 'Hello, $name 👋';
    return SizedBox(
      width: double.infinity,
      height: 132,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFBF9FF),
                    Color(0xFFFBF9FF),
                    Color(0xFFF0E9FF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -34,
            top: -54,
            child: Opacity(
              opacity: .48,
              child: Image.asset(
                'assets/images/house(login).png',
                width: 318,
                height: 205,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 43, 36, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'What service do you need today?',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCarousel extends StatefulWidget {
  const _CategoryCarousel();

  @override
  State<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<_CategoryCarousel> {
  static const int _itemsPerPage = 6;
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  Future<List<Category>>? _categoriesFuture;
  List<Category> _categories = [];
  int _activePage = 0;

  int get _pageCount => (_categories.length / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    _scrollController.addListener(_syncActiveDot);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncActiveDot)
      ..dispose();
    super.dispose();
  }

  Future<List<Category>> _fetchCategories() async {
    try {
      final response = await _apiService.get(ApiUrls.categories);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> categoriesList = data['categories'] ?? [];
        final parsed = categoriesList
            .map((json) => Category.fromJson(json))
            .toList();

        // Sort by display_order if present
        parsed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        // Update the local list so pagination calculations work dynamically
        setState(() {
          _categories = parsed;
        });
        return parsed;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
        'Failed to load categories. Please check your connection.',
      );
    }
  }

  void _syncActiveDot() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0 || _pageCount <= 1) return;

    final nextPage = (_scrollController.offset / (maxScroll / (_pageCount - 1)))
        .round()
        .clamp(0, _pageCount - 1);

    if (nextPage != _activePage) {
      setState(() => _activePage = nextPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      snapshot.error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _categoriesFuture = _fetchCategories();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No categories available.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final categories = snapshot.data!;

        return Column(
          children: [
            SizedBox(
              height: 300,
              child: GridView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    category: category,
                    onTap: () {
                      // TODO: Navigate to category technician list / booking screen when ready
                      // Example:
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => BookingScreen(category: category),
                      //   ),
                      // );
                      openServiceRequestPage(
                        context,
                        ServiceCategory(
                          id: category.id.toString(),
                          name: category.name,
                          slug: _temporaryCategorySlug(category.name),
                        ),
                      );
                      debugPrint(
                        'Selected category: ${category.name} (ID: ${category.id})',
                      );
                    },
                  );
                },
              ),
            ),
            if (_pageCount > 1) ...[
              const SizedBox(height: 14),
              _CategoryDots(count: _pageCount, activeIndex: _activePage),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryDots extends StatelessWidget {
  const _CategoryDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 10 : 8,
          height: index == activeIndex ? 10 : 8,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppColors.primary
                : const Color(0xFFD8D4E4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = AppColors.white,
    this.borderColor = const Color(0xFFEDE7FF),
    this.iconSize = 23,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: AppColors.black, size: iconSize),
        ),
      ),
    );
  }
}
