import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';

class ForgotPasswordEmailScreen extends StatelessWidget {
  ForgotPasswordEmailScreen({super.key});

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightPurple,
      body: Stack(
        children: [
          //=========================
          // MANDALA
          //=========================

          Positioned(
            top: -18,
            left: -80,
            right: -80,
            child: Opacity(
              opacity: .6,
              child: Image.asset(
                "assets/images/mandala.png",
                height: 600,
              ),
            ),
          ),

          //=========================
          // TEMPLE BACKGROUND
          //=========================

          Positioned(
            top: 500,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: .5,
              child: Image.asset(
                "assets/images/bg_signup.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    //================
                    // BACK BUTTON
                    //==============
                    Align(    // Used alignment to keep the container on the left defying the parent(column)'s crossAxisAlignment: CrossAxisAlignment.center,
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          //Each navigation creates a stack of page.
                          // The below way of navigation makes Flutter removes the top screen. so it navigates to the page just before
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    //--------------------------------
                    // LOGO
                    //--------------------------------
                    SizedBox(
                      width: 180,
                      height: 125,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: -20,
                            child: Image.asset(
                              "assets/images/logo_r.png",
                              height: 100,
                            ),
                          ),

                          Positioned(
                            bottom: -20,
                            child: Image.asset(
                              "assets/images/logo_text_J.png",
                              height: 130,
                            ),
                          ),

                          Positioned(
                            top: 105,
                            child: Container(
                              width: 24,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 45),
                    //-----------------------------------
                    /// Heading + Illustration
                    //-----------------------------------

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                "Don't worry! Enter your email address associated with your account and we'll send you a verification code.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 0),
                        Image.asset(
                          "assets/images/email.png",
                          height: 100,
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    //-----------------------------------
                    /// White Card
                    //-----------------------------------

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          const SizedBox(height: 15),
                          CustomTextField(
                            label: "Email Address",
                            hintText: "Enter your email address",
                            fieldType: FieldType.email,
                            controller: emailController,
                            showLabel: true,
                          ),

                          const SizedBox(height: 28),
                          CustomButton(
                            text: "Send OTP",
                            onPressed: () {},
                          ),

                          const SizedBox(height: 28),

                          //-----------------------------------
                          /// Security Text
                          //-----------------------------------

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: const [

                              Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.primary,
                              ),

                              SizedBox(width: 8),

                              Text(
                                "Your information is safe with us.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              )
                            ],
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
    );
  }
}