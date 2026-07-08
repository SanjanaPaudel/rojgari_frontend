import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

import '../../widgets/technician/dashboard_appbar.dart';
import '../../widgets/technician/profile_header.dart';
import '../../widgets/technician/stat_card.dart';
import '../../widgets/technician/request_card.dart';
import '../../widgets/technician/online_status_card.dart';
import '../../widgets/technician/pro_tip_card.dart';

class TechnicianHomeScreen extends StatefulWidget {

  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();

}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {

  bool isOnline = true;

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
  Widget build(BuildContext context){

    return Scaffold(

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children:[

              const SizedBox(height:0),

              Transform.translate(

                offset: const Offset(0,-3),

                child: DashboardAppbar(

                  messageCount: unreadMessageCount,

                  notificationCount: unreadNotificationCount,

                  onMenuTap: (){

                    // NAVIGATION PLACE:
                    // Later open drawer/menu here:
                    // Scaffold.of(context).openDrawer();
                    // OR:
                    // Navigator.pushNamed(context, AppRoutes.menu);

                    print("Menu clicked");

                  },

                  onMessageTap: (){

                    // NAVIGATION PLACE:
                    // Later create messages page and use:
                    // Navigator.pushNamed(context, AppRoutes.messages);

                    print("Messages clicked");

                  },

                  onNotificationTap: (){

                    // NAVIGATION PLACE:
                    // Later create notifications page and use:
                    // Navigator.pushNamed(context, AppRoutes.notifications);

                    print("Notifications clicked");

                  },

                ),

              ),

              Transform.translate(

                offset: const Offset(0,-20),

                child: const ProfileHeader(),

              ),

              Container(

                margin: const EdgeInsets.fromLTRB(
                  12,
                  5,
                  12,
                  20,
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal:6,
                  vertical:22,
                ),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(
                    color: const Color(0xffEEEEEE),
                  ),

                ),

                child: Row(

                  children:[

                    const StatCard(

                      number:"28",
                      title:"Jobs Done",
                      subtitle:"This Month",
                      icon:Icons.work_outline,
                      iconColor: Color(0xff6A35FF),
                      bgColor: Color(0xffF4EEFF),

                    ),

                    Container(
                      width:1,
                      height:100,
                      color: Color(0xffEEEEEE),
                    ),

                    const StatCard(

                      number:"12",
                      title:"Update Skills",
                      subtitle:"In Progress",
                      icon:Icons.sync,
                      iconColor: Color(0xff246BFD),
                      bgColor: Color(0xffEDF4FF),

                    ),

                    Container(
                      width:1,
                      height:100,
                      color: Color(0xffEEEEEE),
                    ),

                    const StatCard(

                      number:"12",
                      title:"Reviews",
                      subtitle:"This Week",
                      icon:Icons.calendar_month,
                      iconColor: Color(0xffFF8C1A),
                      bgColor: Color(0xffFFF1E6),

                    ),

                    Container(
                      width:1,
                      height:100,
                      color: Color(0xffEEEEEE),
                    ),

                    const StatCard(

                      number:"4.8",
                      title:"Avg Rating",
                      subtitle:"Out of 5",
                      icon:Icons.star_border,
                      iconColor: Color(0xff246BFD),
                      bgColor: Color(0xffEDF4FF),

                    ),

                  ],

                ),

              ),

              _incomingRequestsSection(),

              OnlineStatusCard(

                isOnline: isOnline,

                onToggle:(){

                  setState(() {

                    isOnline = !isOnline;

                  });

                  // BACKEND PLACE:
                  // Later connect backend here:
                  // await technicianService.updateOnlineStatus(isOnline);

                },

              ),

              ProTipCard(

                onTap:(){

                  // NAVIGATION PLACE:
                  // Later create profile tips page and use:
                  // Navigator.pushNamed(context, AppRoutes.profileTips);

                  print("Pro Tip clicked");

                },

              ),

              const SizedBox(height:50),

            ],

          ),

        ),

      ),

    );

  }

  Widget _incomingRequestsSection(){

    return Container(

      margin: const EdgeInsets.symmetric(
        horizontal: 22,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(25),

        border: Border.all(
          color: const Color(0xffEFE6FF),
        ),

        boxShadow:[

          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),

        ],

      ),

      child: Column(

        children:[

          Container(

            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 20,
            ),

            decoration: const BoxDecoration(

              color: Color(0xffFCFAFF),

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),

            ),

            child: Row(

              children:[

                Container(

                  width: 52,
                  height: 52,

                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),

                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 28,
                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children:[

                      Row(

                        children:[

                          Expanded(

                            child: FittedBox(

                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,

                              child: const Text(

                                "Incoming Requests",

                                maxLines: 1,

                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),

                              ),

                            ),

                          ),

                          const SizedBox(width: 7),

                          Container(

                            width: 23,
                            height: 23,

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

                        "New service requests near you",

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

                const SizedBox(width: 6),

                InkWell(

                  borderRadius: BorderRadius.circular(10),

                  onTap:(){

                    // NAVIGATION PLACE:
                    // Later create requests page and use:
                    // Navigator.pushNamed(context, AppRoutes.requests);

                    print("View All clicked");

                  },

                  child: const Padding(

                    padding: EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),

                    child: Row(

                      children:[

                        Text(

                          "View All",

                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),

                        ),

                        SizedBox(width: 8),

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

            separatorBuilder: (context,index){

              return const Padding(

                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                ),

                child: Divider(
                  height: 1,
                  color: Color(0xffE6E1EF),
                ),

              );

            },

            itemBuilder: (context,index){

              final request = requests[index];

              return RequestCard(

                title: request["title"]!,
                location: request["location"]!,
                issue: request["issue"]!,
                time: request["time"]!,
                image: request["image"]!,

                onTap:(){

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