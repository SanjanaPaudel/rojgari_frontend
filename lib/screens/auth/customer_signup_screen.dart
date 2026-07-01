import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';

class CustomerSignupScreen extends StatelessWidget {
  const CustomerSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Background Mandala
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child:Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    "assets/images/mandala.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              //temple background
              Positioned(
                top: 200,
                left: 0,
                right: 0,
                child: Image.asset(
                  "assets/images/bg.png",
                  fit: BoxFit.cover,
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.black,
                        ),
                      ),
                    ),

                  //logo and logo_text
                    Center(
                      child: SizedBox(
                        width: 170,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Image.asset(
                              "assets/images/logo_r.png",
                              height: 75,
                            ),

                            Positioned(
                              top: 44,
                              child: Image.asset(
                                "assets/images/logo_text.png",
                                height: 65,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    // Orange line
                    const SizedBox(height: 0),
                    Center(
                      child: Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: SizedBox(
                        height: 260,
                        child: Stack(
                          children: [
                            // Left side - Text
                            Positioned(
                              left: 10,
                              top: 55,
                              right: 80, // Leaves room for the illustration
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),

                                  SizedBox(
                                    width: 170,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.grey,
                                          height: 1.5,
                                        ),
                                        children: [
                                          TextSpan(text: "Join Rojgari today and "),
                                          TextSpan(
                                            text: "connect with us",
                                            style: TextStyle(
                                              color: AppColors.primary, // Purple
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " to discover better opportunities",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),


                                  const SizedBox(height: 8),
                                  Text(
                                    "Create Your Account",
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),



                                ],
                              ),
                            ),

                            // Right side - Illustration (overlaps text)
                            Positioned(
                              right: 3,
                              top: 3,
                              child: Image.asset(
                                "assets/images/girl(_cus-sign).png",
                                height: 230,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -115),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35),
                            topRight: Radius.circular(35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPurple,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  const Text(
                                    "Account Information",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Phone
                              const CustomTextField(
                                label: "Phone Number",
                                hintText: "Enter your phone number",
                                fieldType: FieldType.phone,
                              ),

                              const SizedBox(height: 20),

                              // Password
                              const CustomTextField(
                                label: "Password",
                                hintText: "Create a password",
                                fieldType: FieldType.password,
                              ),

                              const SizedBox(height: 20),

                              // Confirm Password
                              const CustomTextField(
                                label: "Confirm Password",
                                hintText: "Confirm your password",
                                fieldType: FieldType.password,
                              ),

                              const SizedBox(height: 30),

// SECTION TITLE
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPurple,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Personal Information",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 25),
                              CustomTextField(
                                label: "Full Name",
                                hintText: "Enter your full name",
                                fieldType: FieldType.text,
                              ),

                              const SizedBox(height: 20),

// EMAIL
                              CustomTextField(
                                label: "Email Address (Optional)",
                                hintText: "Enter your email address",
                                fieldType: FieldType.email,
                              ),

                              const SizedBox(height: 25),

// PROFILE PHOTO UPLOAD UI (ONLY UI FOR NOW)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightPurple,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    const Expanded(
                                      child: Text(
                                        "Add Profile Photo (Optional)",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Upload",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
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