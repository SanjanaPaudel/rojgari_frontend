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

            style: const TextStyle(

              fontSize:20,
              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height:5),

          Text(

            title,

            textAlign: TextAlign.center,

            style: const TextStyle(

              fontSize:11,
              fontWeight: FontWeight.w500,

            ),

          ),

          const SizedBox(height:3),

          Text(

            subtitle,

            textAlign: TextAlign.center,

            style: TextStyle(

              fontSize:10,
              color: Colors.grey.shade600,

            ),

          )

        ],

      ),

    );

  }

}