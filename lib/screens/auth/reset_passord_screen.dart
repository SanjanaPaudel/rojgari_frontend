import 'package:flutter/material.dart';

import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';
import 'package:rojgari_frontend_one/widgets/password_requirement.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecial = false;

  bool isLoading = false;
  String? newPasswordError;
  String? confirmPasswordError;
  String? generalError;

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

  Future<void> validateFields() async {
    String? newError;
    String? confirmError;

    if (newPasswordController.text.trim().isEmpty) {
      newError = "Password is required";
    } else if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasNumber ||
        !hasSpecial) {
      newError = "Password doesn't meet requirements";
    }

    if (confirmPasswordController.text.isEmpty) {
      confirmError = "Please confirm your password";
    } else if (newPasswordController.text != confirmPasswordController.text) {
      confirmError = "Passwords do not match";
    }

    setState(() {
      newPasswordError = newError;
      confirmPasswordError = confirmError;
      generalError = null;
    });

    if (newError != null || confirmError != null) return;

    setState(() => isLoading = true);

    try {
      final response = await _authService.resetPassword(
        email: widget.email,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      // reset-password's error body has two distinct shapes: bare DRF
      // field-array errors (no "success" key) for confirm_password/
      // new_password, and a flat {success: false, message} for stale-flow
      // cases (OTP not verified/expired, no pending request, account not
      // found) — those have no single field to blame, so they show as a
      // general banner instead.
      final confirmPasswordFieldError = response["confirm_password"];
      final newPasswordFieldError = response["new_password"];

      if (confirmPasswordFieldError is List ||
          newPasswordFieldError is List) {
        setState(() {
          if (newPasswordFieldError is List && newPasswordFieldError.isNotEmpty) {
            newPasswordError = newPasswordFieldError.first.toString();
          }
          if (confirmPasswordFieldError is List && confirmPasswordFieldError.isNotEmpty) {
            confirmPasswordError = confirmPasswordFieldError.first.toString();
          }
        });
        return;
      }

      if (response["success"] == false) {
        setState(() {
          generalError = response["message"] ?? "Could not reset your password.";
        });
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        generalError = "Something went wrong. Please try again.";
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            //=========================
            // MANDALA
            //=========================
            Positioned(
              top: -18,
              left: -80,
              right: -80,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset("assets/images/mandala.png", height: 600),
              ),
            ),

            //=========================
            // TEMPLE BACKGROUND
            //=========================
            Positioned(
              top: 125,
              left: 0,
              right: 0,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.9, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: .5,
                  child: Image.asset(
                    "assets/images/bg_signup.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  //--------------------------------
                  // BACK BUTTON
                  //--------------------------------
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  //--------------------------------
                  // LOGO
                  //--------------------------------
                  Center(
                    child: SizedBox(
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
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  //--------------------------------
                  // TITLE + ILLUSTRATION
                  //--------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Create New Password",
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Your new password must be different "
                              "from your previous password.",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.grey,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Same overlap concept as ForgotPasswordEmailScreen and
                      // OTPScreen: keeps a fixed footprint the title/message
                      // column is laid out around, while letting the actual
                      // lock image render larger and overflow past it.
                      SizedBox(
                        width: 80,
                        height: 90,
                        child: OverflowBox(
                          maxWidth: 180,
                          maxHeight: 180,
                          child: Image.asset(
                            "assets/images/lock.png",
                            width: 130,
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  //--------------------------------
                  // WHITE CARD
                  //--------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 35, 20, 26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background,
                          Colors.white,
                          Colors.white,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.08, 0.92, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        const SizedBox(height: 22),
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

                        if (generalError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            generalError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 12),
                        CustomButton(
                          text: "Reset Password",
                          icon: Icons.arrow_forward_rounded,
                          isLoading: isLoading,
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
                                  fontSize: 13,
                                ),
                              ),
                              InkWell(
                                // Removes all pages above Login from the
                                // stack and navigates straight to it.
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    "Back to Login",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
