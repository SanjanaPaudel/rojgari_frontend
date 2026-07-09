import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/otp_input.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';

import 'package:rojgari_frontend_one/screens/customer/customer_dashboard_screen.dart';
import 'package:rojgari_frontend_one/screens/worker/worker_dashboard_screen.dart';


class OTPScreen extends StatefulWidget {
  final String email; //the email to which the otp is send is now in widget.email
  final String phone; //needed because backend looks up the pending registration by phone number
  final String role; //"customer" or "worker" - decides which dashboard to open after verification

  const OTPScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.role,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> { //Everything that changes while the screen is running belongs here.
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController()); //Each OTP box gets one controller
  final List<FocusNode> focusNodes =  List.generate(6, (_) => FocusNode());
  final AuthService _authService = AuthService(); //For API connect

  bool isLoading = false;

  // Timer
  Timer? timer;
  int secondsRemaining = 180; // timer
  bool canResend = false; // When reaches to 0 the canResend = true and user can press Resend OTP

  // OTP Error
  bool showOtpError = false; // If error occurs showOtpError becomes true
  String? otpErrorMessage; //Stores Error Message

  @override
  void initState() {
    super.initState();

    startTimer(); //Starts counting down

    WidgetsBinding.instance.addPostFrameCallback((_) { //When the screen opens , the cursor automatically appears in the first box.
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
      secondsRemaining = 180;
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

          timer.cancel(); // cancel previous time to start new time

          setState(() {
            canResend = true;
          });
        }
      },
    );
  }

  String getOTP() {
    return controllers.map((controller) => controller.text).join(); // collects value inside six controllers.
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
                        InkWell( // makes the image tappable.
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

                  const SizedBox(height: 20),

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
                                    "Verify Email Address",
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
                                          text: widget.email,
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
                                ? () async {

                              final response =
                              await _authService.resendOTP(
                                phone: widget.phone,
                              );

                              if (response["success"] == false) {
                                setState(() {
                                  showOtpError = true;
                                  otpErrorMessage = response["message"];
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

                              // Frontend validation
                              if (otp.length != 6) {
                                setState(() {
                                  showOtpError = true;
                                  otpErrorMessage =
                                  "Please enter the complete 6-digit OTP.";
                                });
                                return;
                              }

                              setState(() {
                                isLoading = true; // Shows loading indicator
                              });

                              final response = await _authService.verifyOTP(
                                phone: widget.phone,
                                otp: otp,
                              );

                              setState(() {
                                isLoading = false; // hides loading indicator
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

                              // Send the user to the right dashboard based on
                              // the role they picked during signup, and wipe
                              // out the signup/otp screens from the back stack
                              // so they can't navigate back into them.
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => widget.role == "worker"
                                      ? const WorkerDashboardScreen()
                                      : const CustomerDashboardScreen(),
                                ),
                                (route) => false,

                              );
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