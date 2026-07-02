import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      height:145,

      child: Stack(

        children:[

          // TEMPLE IMAGE

          Positioned(

            right:-65,
            top:-10,

            child: Opacity(

              opacity:0.40,

              child: Image.asset(

                "assets/images/background_temple.png",

                width:290,
                height:165,

                fit: BoxFit.cover,

              ),

            ),

          ),

          Padding(

            padding: const EdgeInsets.symmetric(
              horizontal:20,
            ),

            child: Row(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children:[

                // PROFILE IMAGE

                Padding(

                  padding: const EdgeInsets.only(
                    top:28,
                  ),

                  child: Container(

                    width:120,
                    height:120,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,

                    ),

                    child: ClipOval(

                      child: Padding(

                        padding: const EdgeInsets.only(
                          top: 8,
                        ),

                        child: Transform.scale(

                          scale: 1.15,

                          child: Image.asset(

                            "assets/images/technician_avatar.png",

                            fit: BoxFit.contain,

                            alignment: Alignment.bottomCenter,

                          ),

                        ),

                      ),

                    ),

                  ),

                ),

                const SizedBox(width:12),

                Expanded(

                  child: Padding(

                    padding: const EdgeInsets.only(
                      top:28,
                    ),

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children:[

                        const Text(

                          "Hello, Rajan 👋",

                          style: TextStyle(

                            fontSize:18,
                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height:4),

                        Row(

                          children:[

                            Container(

                              padding:
                              const EdgeInsets.symmetric(
                                horizontal:7,
                                vertical:4,
                              ),

                              decoration: BoxDecoration(

                                color:
                                AppColors.primary,

                                borderRadius:
                                BorderRadius.circular(8),

                              ),

                              child: const Row(

                                children:[

                                  Icon(
                                    Icons.star,
                                    size:12,
                                    color: Colors.yellow,
                                  ),

                                  SizedBox(width:3),

                                  Text(

                                    "4.8",

                                    style: TextStyle(

                                      fontSize:12,
                                      fontWeight:
                                      FontWeight.bold,

                                      color: Colors.white,

                                    ),

                                  )

                                ],

                              ),

                            ),

                            const SizedBox(width:7),

                            const Flexible(

                              child: Text(

                                "Top Rated Worker",

                                overflow:
                                TextOverflow.ellipsis,

                                style: TextStyle(

                                  fontSize:12,
                                  color:
                                  AppColors.primary,

                                  fontWeight:
                                  FontWeight.w600,

                                ),

                              ),

                            )

                          ],

                        ),

                        const SizedBox(height:5),

                        const Text(

                          "Plumber • 3+ Years Experience",

                          overflow:
                          TextOverflow.ellipsis,

                          style: TextStyle(

                            fontSize:12,

                            color: Color(0xff555555),

                            fontWeight:
                            FontWeight.w500,

                          ),

                        ),

                        const SizedBox(height:5),

                        const Row(

                          children:[

                            Icon(

                              Icons.verified_user,

                              size:16,

                              color:
                              AppColors.primary,

                            ),

                            SizedBox(width:4),

                            Text(

                              "Verified",

                              style: TextStyle(

                                fontSize:12,

                                color:
                                AppColors.primary,

                                fontWeight:
                                FontWeight.w600,

                              ),

                            )

                          ],

                        )

                      ],

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