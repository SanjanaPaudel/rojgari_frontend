import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/otp_input.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(6, (_) => FocusNode());

  Timer? timer;

  int secondsRemaining = 165;

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

  void startTimer() {
    timer?.cancel();

    setState(() {
      secondsRemaining = 165;
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
          setState(() {
            canResend = true;
          });

          timer.cancel();
        }
      },
    );
  }

  String getOTP() {
    return controllers.map((e) => e.text).join();
  }

  void verifyOTP() {
    String otp = getOTP();

    if (otp.length != 6) {
      setState(() {
        showOtpError = true;
        otpErrorMessage = "Please enter the complete 6-digit OTP.";
      });
      return;
    }

    //=====================
    // Temporary: simulate backend verification
    //=====================
    if (otp != "123456") {
      setState(() {
        showOtpError = true;
        otpErrorMessage = "The OTP you entered is incorrect.";
      });
      return;
    }

    setState(() {
      showOtpError = false;
      otpErrorMessage = null;
    });

    debugPrint("OTP Verified");
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

  @override
  Widget build(BuildContext context) {
    final minutes =
    (secondsRemaining ~/ 60).toString().padLeft(2, "0");

    final seconds =
    (secondsRemaining % 60).toString().padLeft(2, "0");

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
              child: Opacity(
              opacity: .5,
                child: Image.asset(
                  "assets/images/bg_signup.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(10),
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
                              borderRadius:
                              BorderRadius.circular(12),
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
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  const SizedBox(height: 10),

                  const SizedBox(height: 0),
                  //--------------------------------
                  // TITLE AND PHONE
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
                            //==========================
                            // VERIFY AND MSG
                            //==========================
                            Positioned(
                              left: 0,
                              top: 60,
                              right: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "Verify Phone Number",
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
                                            text: "We've sent a verification code to\n",
                                    style: TextStyle(
                                              color: AppColors.grey,
                                              // fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            )
                                        ),

                                        TextSpan(
                                          text: "+977 ${widget.phoneNumber}",
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

                            //==========================
                            // PHONE
                            //==========================
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


                  const SizedBox(height: 10),
                  //--------------------------------
                  // WHITE CARD
                  //--------------------------------

                  Transform.translate(
                    offset: const Offset(0, -85),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        30,
                        22,
                        30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(.04),
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
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            "Please enter the 6-digit OTP sent to your mobile number.",
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
                                previousFocus: index == 0 ? null : focusNodes[index - 1],
                                nextFocus: index == 5 ? null : focusNodes[index + 1],
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
                                ? () {
                              for (final controller in controllers) {
                                controller.clear();
                              }

                              focusNodes.first.requestFocus();

                              startTimer();

                              // TODO:
                              // Resend OTP API
                            }
                                : null,
                            child: Text(
                              canResend ? "Resend OTP" : "Resend OTP",
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
                            onPressed: verifyOTP,
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