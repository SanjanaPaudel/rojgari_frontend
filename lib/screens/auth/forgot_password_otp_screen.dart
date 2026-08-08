import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/screens/auth/reset_passord_screen.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/otp_input.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';

// Dedicated OTP screen for the forgot-password flow. Kept separate from
// OTPScreen (used by signup) because that screen is hardwired to
// phone-based verification and navigates straight to LoginScreen on
// success — this flow verifies by email and must continue on to
// ResetPasswordScreen instead.
class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  final int expiresIn; // seconds, from the forgot-password response

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
    this.expiresIn = 180,
  });

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Timer? timer;
  late int secondsRemaining = widget.expiresIn;
  bool canResend = false;

  bool showOtpError = false;
  String? otpErrorMessage;

  @override
  void initState() {
    super.initState();

    startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    timer?.cancel();

    for (final c in controllers) {
      c.dispose();
    }

    for (final f in focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  void startTimer() {
    timer?.cancel();

    setState(() {
      secondsRemaining = widget.expiresIn;
      canResend = false;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (secondsRemaining > 0) {
          setState(() {
            secondsRemaining--;
          });
        } else {
          timer.cancel();

          setState(() {
            canResend = true;
          });
        }
      },
    );
  }

  String getOTP() {
    return controllers.map((controller) => controller.text).join();
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email;

    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (local.length <= 2) {
      return '${local[0]}*$domain';
    }

    final visible = local.substring(0, 2);
    final masked = '*' * (local.length - 2);
    return '$visible$masked$domain';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, "0");
    final seconds = (secondsRemaining % 60).toString().padLeft(2, "0");

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
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  //--------------------------------
                  // BACK BUTTON
                  //--------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
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
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const SizedBox(height: 0),
                  //--------------------------------
                  // TITLE AND EMAIL
                  //--------------------------------
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 190,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              top: 60,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Verify Email Address",
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.grey,
                                        height: 1.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              "We've sent a verification code to\n",
                                          style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _maskEmail(widget.email),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: -60,
                              bottom: 13,
                              child: Image.asset(
                                "assets/images/phone_OTP.png",
                                height: 170,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  //--------------------------------
                  // WHITE CARD
                  //--------------------------------
                  Transform.translate(
                    offset: const Offset(0, -85),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 18,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Enter Verification Code",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Please enter the 6-digit OTP sent to your Email",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 15,
                            ),
                          ),

                          //====================
                          // OTP BOX
                          //====================
                          const SizedBox(height: 35),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => OTPInput(
                                controller: controllers[index],
                                focusNode: focusNodes[index],
                                previousFocus:
                                    index == 0 ? null : focusNodes[index - 1],
                                nextFocus:
                                    index == 5 ? null : focusNodes[index + 1],
                                hasError: showOtpError,
                                onChanged: () {
                                  if (showOtpError) {
                                    setState(() {
                                      showOtpError = false;
                                      otpErrorMessage = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          if (showOtpError) ...[
                            const SizedBox(height: 10),
                            Text(
                              otpErrorMessage ?? "",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 30),
                          //=========================
                          // TIMER
                          //=========================
                          Text(
                            "$minutes:$seconds",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),

                          const SizedBox(height: 6),
                          const Text(
                            "Didn't receive the code?",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),

                          TextButton(
                            onPressed: canResend
                                ? () async {
                                    try {
                                      final response = await _authService
                                          .resendForgotPasswordOtp(
                                        email: widget.email,
                                      );

                                      if (!mounted) return;

                                      if (response["success"] == false) {
                                        setState(() {
                                          showOtpError = true;
                                          otpErrorMessage =
                                              response["message"] ??
                                                  "Could not resend the code.";
                                        });
                                        return;
                                      }

                                      for (final controller in controllers) {
                                        controller.clear();
                                      }

                                      focusNodes.first.requestFocus();

                                      setState(() {
                                        showOtpError = false;
                                        otpErrorMessage = null;
                                      });

                                      startTimer();
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() {
                                        showOtpError = true;
                                        otpErrorMessage =
                                            "Something went wrong. Please try again.";
                                      });
                                    }
                                  }
                                : null,
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: canResend
                                    ? AppColors.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //=========================
                          // VERIFY BUTTON
                          //=========================
                          CustomButton(
                            text: "Verify & Continue",
                            isLoading: isLoading,
                            onPressed: () async {
                              final otp = getOTP();

                              if (otp.length != 6) {
                                setState(() {
                                  showOtpError = true;
                                  otpErrorMessage =
                                      "Please enter the complete 6-digit OTP.";
                                });
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final response =
                                    await _authService.verifyForgotPasswordOtp(
                                  email: widget.email,
                                  otp: otp,
                                );

                                if (!mounted) return;
                                setState(() {
                                  isLoading = false;
                                });

                                if (response["success"] == false) {
                                  setState(() {
                                    showOtpError = true;
                                    otpErrorMessage = response["message"];
                                  });
                                  return;
                                }

                                setState(() {
                                  showOtpError = false;
                                  otpErrorMessage = null;
                                });

                                timer?.cancel();

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResetPasswordScreen(
                                      email: widget.email,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                setState(() {
                                  isLoading = false;
                                  showOtpError = true;
                                  otpErrorMessage =
                                      "Something went wrong. Please try again.";
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
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
