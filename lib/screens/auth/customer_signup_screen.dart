import 'package:flutter/material.dart';

class CustomerSignupScreen extends StatelessWidget {
  const CustomerSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),

      body: SafeArea(

        child: SingleChildScrollView(

          child: Stack(
            children: [

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  "assets/images/mandala.png",
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 22,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Image.asset(
                        "assets/images/logo_r.png",
                        height: 70,
                      ),
                    ),

                    const SizedBox(height:20),
                    Center(
                      child: Image.asset(
                        "assets/images/logo_text.png",
                        height: 70,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 90,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A3D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Create Your Account",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Join Rojgari today and connect with trusted local workers or find jobs near you.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: Image.asset(
                        "assets/images/girl(_cus-sign).png",
                        height: 180,
                      ),
                    ),

                  ],

                ),
              ),
            ],

          ),

        ),

      ),

    );

  }
}