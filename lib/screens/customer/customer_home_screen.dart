import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/api_urls.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/models/category_model.dart';
import 'package:rojgari_frontend_one/screens/customer/profile_screen.dart';
import 'package:rojgari_frontend_one/services/api_service.dart';
import 'package:rojgari_frontend_one/widgets/category_card.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  // BACKEND TODO:
  // Replace _userName with response.userName from GET /customer/dashboard.
  // Example:
  // final dashboard = await customerDashboardService.getDashboard();
  // userName: dashboard.userName
  static const String _userName = 'Sunita';
  // BACKEND TODO:
  // Replace _notificationCount with response.notificationCount from:
  // GET /customer/dashboard
  // Example:
  // final dashboard = await customerDashboardService.getDashboard();
  // notificationCount: dashboard.notificationCount
  static const int _notificationCount = 2;

  // BACKEND TODO:
  // Replace _recentJobs with response.recentJobs from GET /customer/dashboard.
  // Backend fields should replace these values:
  // bookingId -> bookingId, serviceName -> title, issueDescription -> issue,
  // bookingStatus -> status, updatedAt/createdAt label -> timeLabel,
  // categoryIcon/imageUrl -> iconPath.
  // Keep status values close to: completed, in_progress, booked, pending, cancelled.
  static const List<_RecentJob> _recentJobs = [
    _RecentJob(
      bookingId: 'booking_001',
      title: 'Plumbing Service',
      issue: 'Leakage in bathroom pipe',
      status: 'Completed',
      timeLabel: '2 days ago',
      iconPath: 'assets/images/plumbing_icon.png',
    ),
    _RecentJob(
      bookingId: 'booking_002',
      title: 'Electrician Service',
      issue: 'Switch board not working',
      status: 'In Progress',
      timeLabel: 'Yesterday',
      iconPath: 'assets/images/electrician_icon.png',
    ),
    _RecentJob(
      bookingId: 'booking_003',
      title: 'AC Repair',
      issue: 'Cooling service check',
      status: 'Booked',
      timeLabel: 'Today, 4 PM',
      iconPath: 'assets/images/ac_repair_icon.png',
    ),
  ];

  // BACKEND TODO:
  // Replace _infoCards with response.verificationInfo and response.supportInfo.
  // verificationInfo.title/subtitle/imageUrl/actionLabel replace first card.
  // supportInfo.title/subtitle/imageUrl/actionLabel replace second card.
  static const List<_InfoCardData> _infoCards = [
    _InfoCardData(
      title: 'Verified & Trusted Professionals',
      subtitle: 'Verified Professionals.',
      buttonText: 'Learn More',
      imagePath: 'assets/images/verified_and__trusted_professional.png',
    ),
    _InfoCardData(
      title: 'Need help?',
      subtitle: 'We are here to help you 24/7.',
      buttonText: 'Contact Support',
      imagePath: 'assets/images/need_help.png',
    ),
  ];

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
                child: _TopBar(notificationCount: _notificationCount),
              ),
              const SizedBox(height: 4),
              const _ProfileHeader(userName: _userName),
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
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InfoCardsRow(infoCards: _infoCards),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Bookings',
                  trailing: _ViewAllButton(
                    onTap: () {
                      // NAVIGATION TODO:
                      // Replace with all-bookings screen route when ready.
                      // Example:
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerBookingsScreen()));
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
                          child: _RecentJobCard(job: job),
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
  const _TopBar({required this.notificationCount});

  final int notificationCount;

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomerProfileScreen(),
                  ),
                );
              },
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
                  onTap: () {
                    // NAVIGATION TODO:
                    // Replace with notifications screen route when ready.
                    // Example:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerNotificationsScreen()));
                  },
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

  final String userName;

  @override
  Widget build(BuildContext context) {
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
                  'Hello, $userName 👋',
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
                      debugPrint('Selected category: ${category.name} (ID: ${category.id})');
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

class _InfoCardsRow extends StatelessWidget {
  const _InfoCardsRow({required this.infoCards});

  final List<_InfoCardData> infoCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _InfoCard(data: infoCards.first)),
        const SizedBox(width: 14),
        Expanded(child: _InfoCard(data: infoCards.last)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final _InfoCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (data.buttonText == 'Learn More') {
            // NAVIGATION TODO:
            // Replace with verification information screen later.
            // Use response.verificationInfo.actionRoute/actionUrl when backend sends it.
          } else {
            // NAVIGATION TODO:
            // Replace with support screen or phone/chat action later.
            // Use response.supportInfo.actionRoute/actionUrl when backend sends it.
          }
        },
        child: Container(
          height: 210,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9DFFF)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.buttonText == 'Learn More'
                  ? const [Color(0xFFFBF8FF), Color(0xFFFFFFFF)]
                  : const [Color(0xFFFFFFFF), Color(0xFFFBF9FF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                padding: EdgeInsets.all(
                  data.buttonText == 'Contact Support' ? 8 : 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: AppColors.white,
                    child: Image.asset(data.imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (data.buttonText == 'Learn More') {
                      // NAVIGATION TODO:
                      // Replace with verification information screen later.
                    } else {
                      // NAVIGATION TODO:
                      // Replace with support screen or phone/chat action later.
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    data.buttonText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentJobCard extends StatelessWidget {
  const _RecentJobCard({required this.job});

  final _RecentJob job;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _BookingStatusStyle.fromBackend(job.status);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // NAVIGATION TODO:
          // Replace with booking details screen later.
          // Pass job.bookingId to the details page:
          // Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: job.bookingId)));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFE9FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(job.iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          job.timeLabel,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.issue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusStyle.label,
                        style: TextStyle(
                          color: statusStyle.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // NAVIGATION TODO:
                    // Replace with booking details screen later.
                    // Pass job.bookingId to the details page:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: job.bookingId)));
                  },
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
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



class _RecentJob {
  final String bookingId;
  final String title;
  final String issue;
  final String status;
  final String timeLabel;
  final String iconPath;

  const _RecentJob({
    required this.bookingId,
    required this.title,
    required this.issue,
    required this.status,
    required this.timeLabel,
    required this.iconPath,
  });
}

class _BookingStatusStyle {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _BookingStatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  // BACKEND TODO:
  // Keep backend bookingStatus values simple and consistent:
  // completed, in_progress, booked, pending, cancelled.
  // If backend sends a new status, add one case here only; the booking card UI
  // will update automatically without changing the widget layout.
  factory _BookingStatusStyle.fromBackend(String status) {
    switch (status.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'completed':
        return _BookingStatusStyle(
          label: 'Completed',
          textColor: AppColors.green,
          backgroundColor: AppColors.green.withValues(alpha: .12),
        );
      case 'in_progress':
        return const _BookingStatusStyle(
          label: 'In Progress',
          textColor: Color(0xFF1877F2),
          backgroundColor: Color(0xFFEAF2FF),
        );
      case 'booked':
        return const _BookingStatusStyle(
          label: 'Booked',
          textColor: AppColors.primary,
          backgroundColor: AppColors.lightPurple,
        );
      case 'cancelled':
        return const _BookingStatusStyle(
          label: 'Cancelled',
          textColor: AppColors.red,
          backgroundColor: Color(0xFFFFECEC),
        );
      default:
        return const _BookingStatusStyle(
          label: 'Pending',
          textColor: Color(0xFF8A5A00),
          backgroundColor: Color(0xFFFFF3D6),
        );
    }
  }
}

class _InfoCardData {
  final String title;
  final String subtitle;
  final String buttonText;
  final String imagePath;

  const _InfoCardData({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imagePath,
  });
}
