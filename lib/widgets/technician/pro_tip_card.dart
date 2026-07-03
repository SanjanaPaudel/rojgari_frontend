import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ProTipCard extends StatelessWidget {

  const ProTipCard({super.key});

  @override
  Widget build(BuildContext context){

    return Container(

        margin: const EdgeInsets.all(20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

            color: AppColors.lightPurple,

            borderRadius:
            BorderRadius.circular(25)

        ),

        child: Row(

            children:[

              const Icon(

                  Icons.lightbulb_outline,
                  size:40,
                  color: AppColors.primary

              ),

              const SizedBox(width:15),

              const Expanded(

                  child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children:[

                        Text(

                          "Pro Tip",

                          style: TextStyle(

                              fontWeight: FontWeight.bold,
                              fontSize:22

                          ),

                        ),

                        SizedBox(height:8),

                        Text(

                            "Keep your profile updated and respond quickly to get more jobs."

                        )

                      ]

                  )

              ),

              Image.asset(

                  "assets/images/toolbox.png",

                  height:70

              ),

              IconButton(

                  onPressed: (){

                    print("Tip Clicked");

                  },

                  icon: const Icon(
                      Icons.arrow_forward_ios
                  )

              )

            ]

        )

    );

  }

}