import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const StatCard({

    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,

  });

  @override
  Widget build(BuildContext context){

    return Expanded(

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children:[

          Container(

            width:40,
            height:40,

            decoration: BoxDecoration(

              shape: BoxShape.circle,

              color:bgColor,

            ),

            child: Icon(

              icon,

              color:iconColor,

              size:20,

            ),

          ),

          const SizedBox(height:10),

          Text(

            number,

            maxLines:1,

            style: const TextStyle(

              fontSize:20,
              fontWeight: FontWeight.bold,
              color: Color(0xff171725),

            ),

          ),

          const SizedBox(height:5),

          Text(

            title,

            maxLines:1,

            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,

            style: const TextStyle(

              fontSize:10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xff171725),

            ),

          ),

          const SizedBox(height:3),

          Text(

            subtitle,

            maxLines:1,

            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,

            style: TextStyle(

              fontSize:9.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,

            ),

          )

        ],

      ),

    );

  }

}