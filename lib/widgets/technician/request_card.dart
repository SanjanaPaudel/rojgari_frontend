import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class RequestCard extends StatelessWidget {

  final String title;
  final String location;
  final String issue;
  final String time;
  final String image;

  const RequestCard({

    super.key,
    required this.title,
    required this.location,
    required this.issue,
    required this.time,
    required this.image,

  });

  @override
  Widget build(BuildContext context){

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical:15,
      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children:[

          Container(

            width:70,
            height:70,

            decoration: BoxDecoration(

              color: Colors.grey.shade100,
              shape: BoxShape.circle,

            ),

            child: Padding(

              padding: const EdgeInsets.all(14),

              child: Image.asset(image),

            ),

          ),

          const SizedBox(width:15),

          Expanded(

            child: Row(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children:[

                Expanded(

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children:[

                      Row(

                        children:[

                          Flexible(

                            child: Text(

                              title,

                              style: const TextStyle(

                                fontSize:20,
                                fontWeight:
                                FontWeight.bold,

                              ),

                              overflow:
                              TextOverflow.ellipsis,

                            ),

                          ),

                          const SizedBox(width:8),

                          Container(

                            padding:
                            const EdgeInsets.symmetric(
                              horizontal:8,
                              vertical:4,
                            ),

                            decoration: BoxDecoration(

                              color:
                              AppColors.lightPurple,

                              borderRadius:
                              BorderRadius.circular(8),

                            ),

                            child: const Text(
                              "New",
                              style: TextStyle(
                                fontSize:12,
                              ),
                            ),

                          )

                        ],

                      ),

                      const SizedBox(height:10),

                      Row(

                        children:[

                          const Icon(
                            Icons.location_on_outlined,
                            size:16,
                            color: Colors.grey,
                          ),

                          const SizedBox(width:5),

                          Expanded(

                            child: Text(

                              location,

                              style: const TextStyle(
                                color: Colors.grey,
                              ),

                            ),

                          )

                        ],

                      ),

                      const SizedBox(height:6),

                      Row(

                        children:[

                          const Icon(
                            Icons.message_outlined,
                            size:16,
                            color: Colors.grey,
                          ),

                          const SizedBox(width:5),

                          Expanded(

                            child: Text(

                              issue,

                              style: const TextStyle(
                                color: Colors.grey,
                              ),

                            ),

                          )

                        ],

                      ),

                      const SizedBox(height:6),

                      Row(

                        children:[

                          const Icon(
                            Icons.access_time,
                            size:16,
                            color: Colors.grey,
                          ),

                          const SizedBox(width:5),

                          Text(

                            time,

                            style: const TextStyle(
                              color: Colors.grey,
                            ),

                          )

                        ],

                      )

                    ],

                  ),

                ),

                const SizedBox(width:10),

                Padding(

                  padding: const EdgeInsets.only(
                    top:35,
                  ),

                  child: GestureDetector(

                    onTap:(){

                      print(
                          "Arrow clicked"
                      );

                    },

                    child: Container(

                      padding:
                      const EdgeInsets.all(10),

                      decoration: BoxDecoration(

                        color:
                        AppColors.lightPurple,

                        borderRadius:
                        BorderRadius.circular(12),

                      ),

                      child: const Icon(

                        Icons.arrow_forward_ios,

                        size:18,

                        color:
                        AppColors.primary,

                      ),

                    ),

                  ),

                )

              ],

            ),

          )

        ],

      ),

    );

  }

}