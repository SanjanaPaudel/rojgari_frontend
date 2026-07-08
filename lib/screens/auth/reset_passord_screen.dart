import 'package:flutter/material.dart';

import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';
import 'package:rojgari_frontend_one/widgets/password_requirement.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';


class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecial = false;

  String? newPasswordError;
  String? confirmPasswordError;

  @override
  void initState() {
    super.initState();

    newPasswordController.addListener(() {
      validatePassword(newPasswordController.text);
    });
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void validateFields() {

    setState(() {
      newPasswordError = null;
      confirmPasswordError = null;
    });

    if (newPasswordController.text.trim().isEmpty) {
      newPasswordError =
      "Password is required";
    }
    if(
    !hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasNumber ||
        !hasSpecial
    ){
      newPasswordError =
      "Password doesn't meet requirements";
    }

    if(confirmPasswordController.text.isEmpty) {
      confirmPasswordError =
      "Please confirm your password";
    }

    if(
    newPasswordController.text !=
        confirmPasswordController.text
    ){
      confirmPasswordError =
      "Passwords do not match";
    }

  }

  void validatePassword(String password) {
    setState(() {
      hasMinLength = password.length >= 8;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasLowercase = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightPurple,
      body: Stack( //Allows widgets ot overlap
        children: [
        //=====================
        // MANDALA
        //=====================
        Positioned(
        top: -18,
        left: -80,
        right: -80,
        child: Opacity(
          opacity: 0.6,
          child: Image.asset("assets/images/mandala.png", height: 600),
        ),
      ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              // padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  const SizedBox(height: 25),
                  SizedBox(
                    width: 180,
                    height: 125,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -15,
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        Positioned(
                            top:120,
                            child: Image.asset(
                              "assets/images/lock.png",
                              height: 150,
                            )
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "Create New Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "Your new password must be different\nfrom your previous password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 40),
                  CustomTextField(
                    label: "New Password",
                    hintText: "Enter your new password",
                    fieldType: FieldType.password,
                    controller: newPasswordController,
                    showLabel: true,
                    errorMsg: newPasswordError,
                  ),

                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Confirm Password",
                    hintText: "Re-enter your password",
                    fieldType: FieldType.password,
                    controller: confirmPasswordController,
                    showLabel: true,
                    errorMsg: confirmPasswordError,
                  ),

                  const SizedBox(height: 28),
                  PasswordRequirement(
                    text: "At least 8 characters",
                    isValid: hasMinLength,
                  ),

                  PasswordRequirement(
                    text: "One uppercase letter",
                    isValid: hasUppercase,
                  ),

                  PasswordRequirement(
                    text: "One lowercase letter",
                    isValid: hasLowercase,
                  ),

                  PasswordRequirement(
                    text: "One number",
                    isValid: hasNumber,
                  ),

                  PasswordRequirement(
                    text: "One special character",
                    isValid: hasSpecial,
                  ),

                  const SizedBox(height: 30),
                  CustomButton(
                    text: "Reset Password",
                    onPressed: validateFields,
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Remember your password? ",
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 15,
                          ),
                        ),

                        InkWell(
                          //This navigation removes all the pages above login from the page stack and navigate directly to login screen
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                                  (route) => false,
                            );

                            //This navigation replaces only the current screen(reset_password_screen) with the navigated screen(login_screen).
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const LoginScreen(),
                            //   ),
                            // );

                          },

                          // The following controls the tapable effect of Inkwell
                          // splashColor: Colors.transparent,
                          // highlightColor: Colors.transparent,
                          // hoverColor: Colors.transparent,
                          // focusColor: Colors.transparent,
                          // borderRadius: BorderRadius.circular(6),
                          child: const Padding(//We add padding to increase the clickable area around the text.
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
          )
      ]
      )
    );
  }
}
