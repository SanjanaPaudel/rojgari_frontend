import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends State<ForgotPasswordEmailScreen> {
  final TextEditingController emailController = TextEditingController();

  String? emailError;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => emailError = "Email address is required");
      return false;
    }

    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      setState(() => emailError = "Enter a valid email address");
      return false;
    }

    setState(() => emailError = null);
    return true;
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
                opacity: .5,
                child: Image.asset(
                  "assets/images/mandala.png",
                  height: 480,
                ),
              ),
            ),

            //=========================
            // TEMPLE BACKGROUND
            //=========================
            Positioned(
              top: 155,
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

                  const SizedBox(height: 35),

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
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Don't worry!Enter your email."
                              " We'll send you a verification code.",
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
                      // Keeps the same 88x88 footprint the title/description
                      // column was laid out around (so that Row/Expanded
                      // sizing — and thus the text — doesn't shift), while
                      // letting the actual image render larger and overlap
                      // whatever is behind/around it via OverflowBox.
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: OverflowBox(
                          maxWidth: 150,
                          maxHeight: 150,
                          child: Image.asset(
                            "assets/images/email.png",
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  //--------------------------------
                  // WHITE CARD
                  //--------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 35, 20, 280),
                    decoration: BoxDecoration(
                      // Fades from the page's own background tint into solid
                      // white at both the top and bottom edges of the card
                      // (staying solid white through the middle, where the
                      // actual content sits), so neither edge cuts in as a
                      // flat, hard-edged line against what's behind it.
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background,
                          Colors.white,
                          Colors.white,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.18, 0.1, 1.0],
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
                          label: "Email Address",
                          hintText: "Enter your email address",
                          fieldType: FieldType.email,
                          controller: emailController,
                          showLabel: true,
                          errorMsg: emailError,
                        ),

                        const SizedBox(height: 30),
                        CustomButton(
                          text: "Send OTP",
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            if (!_validateEmail()) return;

                            // Navigation-only for now — no send-OTP API call
                            // yet. OTPScreen's `phone` is a required
                            // constructor field (used for the resend-OTP
                            // API), but this email-based reset flow has no
                            // phone number to give it; left blank as a
                            // placeholder until the real backend contract
                            // for email-based reset is wired up.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OTPScreen(
                                  email: emailController.text.trim(),
                                  phone: '',
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        //--------------------------------
                        // SECURITY TEXT
                        //--------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Your information is safe with us.",
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
