import 'package:flutter/material.dart';

class OnlineStatusCard extends StatelessWidget {

  const OnlineStatusCard({super.key});

  @override
  Widget build(BuildContext context){

    return Container(

        margin: const EdgeInsets.all(20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

            color: Colors.green.shade50,

            borderRadius:
            BorderRadius.circular(25)

        ),

        child: Row(

            children:[

              CircleAvatar(

                radius:30,

                backgroundColor: Colors.green,

                child: IconButton(

                    onPressed: (){

                      print("Power clicked");

                    },

                    icon: const Icon(
                        Icons.power_settings_new,
                        color: Colors.white
                    )

                ),

              ),

              const SizedBox(width:20),

              const Expanded(

                  child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children:[

                        Text(

                          "You are Online",

                          style: TextStyle(

                              fontWeight: FontWeight.bold,
                              fontSize:20

                          ),

                        ),

                        SizedBox(height:8),

                        Text(

                            "You will receive job requests"

                        )

                      ]

                  )

              ),

              ElevatedButton(

                  onPressed: (){

                    print("Go offline");

                  },

                  child: const Text(
                      "Go Offline"
                  )

              )

            ]

        )

    );

  }

}