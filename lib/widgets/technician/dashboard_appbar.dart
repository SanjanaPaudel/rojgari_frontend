import 'package:flutter/material.dart';

class DashboardAppbar extends StatelessWidget {

  const DashboardAppbar({super.key});

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

            onPressed: (){},

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

                // Image.asset(
                //
                //   "assets/images/logo_r.png",
                //
                //   height:52,
                //
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

              Stack(

                children:[

                  IconButton(

                    onPressed:(){},

                    icon: const Icon(

                      Icons.chat_bubble_outline,
                      size:28,

                    ),

                  ),

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

                      child: const Center(

                        child: Text(

                          "2",

                          style: TextStyle(

                            color: Colors.white,
                            fontSize:10,

                          ),

                        ),

                      ),

                    ),

                  )

                ],

              ),

              Stack(

                children:[

                  IconButton(

                    onPressed:(){},

                    icon: const Icon(

                      Icons.notifications_none,
                      size:30,

                    ),

                  ),

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

                      child: const Center(

                        child: Text(

                          "3",

                          style: TextStyle(

                            color: Colors.white,
                            fontSize:10,

                          ),

                        ),

                      ),

                    ),

                  )

                ],

              )

            ],

          )

        ],

      ),

    );

  }

}