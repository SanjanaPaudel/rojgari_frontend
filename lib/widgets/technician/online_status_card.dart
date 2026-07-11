import 'package:flutter/material.dart';

class OnlineStatusCard extends StatelessWidget {

  final bool isOnline;
  final VoidCallback? onToggle;

  const OnlineStatusCard({
    super.key,
    required this.isOnline,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context){

    final Color mainColor = isOnline
        ? const Color(0xff17B957)
        : const Color(0xff8E8E93);

    final Color bgColor = isOnline
        ? const Color(0xffECFAF2)
        : const Color(0xffF1F1F3);

    final Color borderColor = isOnline
        ? const Color(0xffD8F2E3)
        : const Color(0xffDDDDDF);

    return Container(

      margin: const EdgeInsets.fromLTRB(
        22,
        28,
        22,
        0,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      decoration: BoxDecoration(

        color: bgColor,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: borderColor,
        ),

      ),

      child: Row(

        children:[

          Container(

            width: 60,
            height: 60,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mainColor,
            ),

            child: const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 34,
            ),

          ),

          const SizedBox(width: 16),

          Expanded(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children:[

                Text(

                  isOnline ? "You are Online" : "You are Offline",

                  maxLines: 1,

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),

                ),

                const SizedBox(height: 6),

                Text(

                  isOnline
                      ? "You will receive job requests in your area"
                      : "You will not receive new job requests",

                  maxLines: 2,

                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xff171725),
                    fontWeight: FontWeight.w500,
                  ),

                ),

              ],

            ),

          ),

          const SizedBox(width: 10),

          InkWell(

            borderRadius: BorderRadius.circular(12),

            onTap: onToggle,

            child: Container(

              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(
                  color: mainColor,
                ),

              ),

              child: Text(

                isOnline ? "Go Offline" : "Go Online",

                maxLines: 1,

                style: TextStyle(
                  color: mainColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}