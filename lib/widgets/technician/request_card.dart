import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class RequestCard extends StatelessWidget {

  final String title;
  final String location;
  final String issue;
  final String time;
  final String image;
  final VoidCallback? onTap;

  const RequestCard({

    super.key,
    required this.title,
    required this.location,
    required this.issue,
    required this.time,
    required this.image,
    this.onTap,

  });

  @override
  Widget build(BuildContext context){

    return Padding(

      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.center,

        children:[

          Container(

            width: 78,
            height: 78,

            decoration: const BoxDecoration(
              color: Color(0xffF7F7FA),
              shape: BoxShape.circle,
            ),

            child: Center(

              child: Transform.scale(

                scale: 1.35,

                child: Image.asset(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),

              ),

            ),

          ),

          const SizedBox(width: 18),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children:[

                Row(

                  children:[

                    Flexible(

                      child: Text(

                        title,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff171725),
                        ),

                      ),

                    ),

                    const SizedBox(width: 8),

                    Container(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xffF4EEFF),
                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: const Text(

                        "New",

                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 9),

                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: location,
                ),

                const SizedBox(height: 7),

                _InfoLine(
                  icon: Icons.chat_bubble_outline,
                  text: issue,
                ),

                const SizedBox(height: 7),

                _InfoLine(
                  icon: Icons.access_time,
                  text: time,
                ),

              ],

            ),

          ),

          const SizedBox(width: 8),

          Padding(

            padding: const EdgeInsets.only(
              top: 34,
            ),

            child: InkWell(

              borderRadius: BorderRadius.circular(12),

              onTap: onTap,

              child: Container(

                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: const Color(0xffF3ECFF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}

class _InfoLine extends StatelessWidget {

  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context){

    return Row(

      children:[

        Icon(
          icon,
          size: 16,
          color: Color(0xff5F6A8A),
        ),

        SizedBox(width: 8),

        Expanded(

          child: Text(

            text,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 14,
              color: Color(0xff5F6A8A),
              fontWeight: FontWeight.w500,
            ),

          ),

        ),

      ],

    );

  }

}