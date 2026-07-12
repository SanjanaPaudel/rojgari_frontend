import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../data/technician_dummy_data.dart';

import '../../widgets/technician/dashboard_appbar.dart';
import '../../widgets/technician/profile_header.dart';
import '../../widgets/technician/stat_card.dart';
import '../../widgets/technician/request_card.dart';
import '../../widgets/technician/pro_tip_card.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  late bool isOnline;

  // BACKEND READY:
  // Later these counts will come from backend dashboard API.
  // Example:
  // unreadMessageCount = dashboardData.unreadMessageCount;
  // unreadNotificationCount = dashboardData.unreadNotificationCount;

  int unreadMessageCount = 2;
  int unreadNotificationCount = 3;

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

    // BACKEND READY:
    // For now this comes from dummy data.
    // Later this value will come from dashboard API.
    isOnline = technicianData.online;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 0),

              Transform.translate(
                offset: const Offset(0, -3),

                child: DashboardAppbar(
                  messageCount: unreadMessageCount,

                  notificationCount: unreadNotificationCount,

                  onMenuTap: () {
                    // NAVIGATION PLACE:
                    // Later open drawer/menu here:
                    // Scaffold.of(context).openDrawer();
                    // OR:
                    // Navigator.pushNamed(context, AppRoutes.menu);

                    print("Menu clicked");
                  },

                  onMessageTap: () {
                    // NAVIGATION PLACE:
                    // Later create messages page and use:
                    // Navigator.pushNamed(context, AppRoutes.messages);

                    print("Messages clicked");
                  },

                  onNotificationTap: () {
                    // NAVIGATION PLACE:
                    // Later create notifications page and use:
                    // Navigator.pushNamed(context, AppRoutes.notifications);

                    print("Notifications clicked");
                  },
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -20),

                child: ProfileHeader(
                  name: technicianData.name,

                  rating: technicianData.rating,

                  profession: technicianData.profession,

                  experienceText: technicianData.experienceText,

                  isVerified: technicianData.isVerified,

                  avatarImage: technicianData.avatarImage,

                  isOnline: isOnline,

                  onStatusChanged: (newStatus) {
                    setState(() {
                      isOnline = newStatus;
                    });

                    // BACKEND PLACE:
                    // Later call technicianService.updateOnlineStatus(isOnline)
                    // When offline, backend should not send new job request
                    // notifications to this technician.
                  },
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(12, 5, 12, 20),

                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 22,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(color: const Color(0xffEEEEEE)),
                ),

                child: Row(
                  children: [
                    StatCard(
                      number: technicianData.completedJobs.toString(),
                      title: "Jobs Done",
                      subtitle: "This Month",
                      icon: Icons.work_outline,
                      iconColor: const Color(0xff6A35FF),
                      bgColor: const Color(0xffF4EEFF),
                    ),

                    Container(
                      width: 1,
                      height: 100,
                      color: const Color(0xffEEEEEE),
                    ),

                    const StatCard(
                      number: "12",
                      title: "Update Skills",
                      subtitle: "In Progress",
                      icon: Icons.sync,
                      iconColor: Color(0xff246BFD),
                      bgColor: Color(0xffEDF4FF),
                    ),

                    Container(
                      width: 1,
                      height: 100,
                      color: const Color(0xffEEEEEE),
                    ),

                    StatCard(
                      number: technicianData.reviews.toString(),
                      title: "Reviews",
                      subtitle: "This Week",
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
                      number: technicianData.rating.toStringAsFixed(1),
                      title: "Avg Rating",
                      subtitle: "Out of 5",
                      icon: Icons.star_border,
                      iconColor: const Color(0xff246BFD),
                      bgColor: const Color(0xffEDF4FF),
                    ),
                  ],
                ),
              ),

              _incomingRequestsSection(),

              ProTipCard(
                onTap: () {
                  // NAVIGATION PLACE:
                  // Later create profile tips page and use:
                  // Navigator.pushNamed(context, AppRoutes.profileTips);

                  print("Pro Tip clicked");
                },
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _incomingRequestsSection() {
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
                                "Incoming Requests",

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
                                requests.length.toString(),

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
                        "New requests near you",

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

                    print("View All clicked");
                  },

                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),

                    child: Row(
                      children: [
                        Text(
                          "View All",

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

            separatorBuilder: (context, index) => const SizedBox(height: 10),

            itemBuilder: (context, index) {
              final request = requests[index];

              // BACKEND READY:
              // Later backend should send serviceTitle, location, issue,
              // postedTime, serviceType, and isNew.
              // Frontend should map serviceType to a local asset image.

              return RequestCard(
                title: request["title"]!,
                location: request["location"]!,
                issue: request["issue"]!,
                time: request["time"]!,
                image: request["image"]!,

                onTap: () {
                  // NAVIGATION PLACE:
                  // Later create request detail page and use:
                  // Navigator.pushNamed(
                  //   context,
                  //   AppRoutes.requestDetail,
                  //   arguments: request,
                  // );

                  print("${request["title"]} clicked");
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
