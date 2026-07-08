import 'package:flutter/material.dart';

class DashboardAppbar extends StatelessWidget {

  final int messageCount;
  final int notificationCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onNotificationTap;

  const DashboardAppbar({

    super.key,
    required this.messageCount,
    required this.notificationCount,
    this.onMenuTap,
    this.onMessageTap,
    this.onNotificationTap,

  });

  @override
  Widget build(BuildContext context){

    return Padding(

      padding: const EdgeInsets.symmetric(
        horizontal:20,
      ),

      child: Row(

        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children:[

          // MENU ICON

          IconButton(

            onPressed: onMenuTap,

            icon: const Icon(

              Icons.menu,
              size:28,

            ),

          ),

          // ROJGARI LOGO

          Transform.translate(

            offset: const Offset(35,-12),

            child: Row(

              children:[

                // If you want to show R logo again later:
                //
                // Image.asset(
                //   "assets/images/logo_r.png",
                //   height:52,
                // ),

                Transform.translate(

                  offset: const Offset(-19,0),

                  child: Image.asset(

                    "assets/images/logo_text.png",

                    height:70,

                  ),

                )

              ],

            ),

          ),

          // RIGHT ICONS

          Row(

            children:[

              _TopIconWithBadge(

                icon: Icons.chat_bubble_outline,

                count: messageCount,

                onTap: onMessageTap,

              ),

              _TopIconWithBadge(

                icon: Icons.notifications_none,

                count: notificationCount,

                onTap: onNotificationTap,

              ),

            ],

          )

        ],

      ),

    );

  }

}

class _TopIconWithBadge extends StatelessWidget {

  final IconData icon;
  final int count;
  final VoidCallback? onTap;

  const _TopIconWithBadge({

    required this.icon,
    required this.count,
    this.onTap,

  });

  @override
  Widget build(BuildContext context){

    return Stack(

      clipBehavior: Clip.none,

      children:[

        IconButton(

          onPressed: onTap,

          icon: Icon(

            icon,
            size:28,

          ),

        ),

        if(count > 0)

          Positioned(

            right:4,
            top:4,

            child: Container(

              width:18,
              height:18,

              decoration: const BoxDecoration(

                color: Colors.red,
                shape: BoxShape.circle,

              ),

              child: Center(

                child: Text(

                  count > 9 ? "9+" : count.toString(),

                  style: const TextStyle(

                    color: Colors.white,
                    fontSize:10,
                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ),

          )

      ],

    );

  }

}