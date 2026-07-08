import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ProTipCard extends StatelessWidget {

  final VoidCallback? onTap;

  const ProTipCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context){

    return Container(

      margin: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        50,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      decoration: BoxDecoration(

        color: const Color(0xffF6F0FF),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: const Color(0xffEFE6FF),
        ),

      ),

      child: Row(

        children:[

          Container(

            width: 54,
            height: 54,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffEFE6FF),
            ),

            child: const Icon(
              Icons.lightbulb_outline,
              size: 32,
              color: AppColors.primary,
            ),

          ),

          const SizedBox(width: 15),

          const Expanded(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children:[

                Text(

                  "Pro Tip",

                  maxLines: 1,

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),

                ),

                SizedBox(height: 6),

                Text(

                  "Keep your profile updated and respond quickly to get more jobs.",

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xff5F6A8A),
                    fontWeight: FontWeight.w500,
                  ),

                ),

              ],

            ),

          ),

          const SizedBox(width: 6),

          Image.asset(

            "assets/images/toolbox.png",
            width: 105,
            height: 88,
            fit: BoxFit.contain,

          ),

          InkWell(

            borderRadius: BorderRadius.circular(10),

            onTap: onTap,

            child: const Padding(

              padding: EdgeInsets.all(5),

              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 20,
              ),

            ),

          ),

        ],

      ),

    );

  }

}