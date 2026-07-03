import 'package:flutter/material.dart';

import '../../widgets/technician/dashboard_appbar.dart';
import '../../widgets/technician/profile_header.dart';
import '../../widgets/technician/stat_card.dart';
import '../../widgets/technician/request_card.dart';
import '../../widgets/technician/online_status_card.dart';
import '../../widgets/technician/pro_tip_card.dart';

class TechnicianHomeScreen extends StatelessWidget {

  const TechnicianHomeScreen({super.key});

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

                        child: const DashboardAppbar(),

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

                          borderRadius:
                          BorderRadius.circular(25),

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

                      Container(

                          margin:
                          const EdgeInsets.symmetric(
                              horizontal:20
                          ),

                          padding:
                          const EdgeInsets.all(20),

                          decoration: BoxDecoration(

                              color: Colors.white,

                              borderRadius:
                              BorderRadius.circular(25)

                          ),

                          child: Column(

                              children:[

                                Row(

                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                    children:[

                                      const Text(

                                        "Incoming Requests",

                                        style: TextStyle(

                                            fontWeight: FontWeight.bold,
                                            fontSize:24

                                        ),

                                      ),

                                      TextButton(

                                          onPressed: (){

                                            print("View all");

                                          },

                                          child: const Text(
                                              "View All"
                                          )

                                      )

                                    ]

                                ),

                                RequestCard(

                                    title:"Plumbing Service",

                                    location:"Lazimpat Kathmandu",

                                    issue:"Leaking bathroom pipe",

                                    time:"Posted 5 mins ago",

                                    image:"assets/images/plumbing_icon.png"

                                ),

                                const Divider(),

                                RequestCard(

                                    title:"Electrician Service",

                                    location:"Maitidevi Kathmandu",

                                    issue:"Switch board not working",

                                    time:"Posted 12 mins ago",

                                    image:"assets/images/electrician_icon.png"

                                ),

                              ]

                          )

                      ),

                      const OnlineStatusCard(),

                      const ProTipCard(),

                      const SizedBox(
                          height:50
                      )

                    ]

                )

            )

        )

    );

  }

}