import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';
import 'package:rojgari_frontend_one/screens/auth/signup_screen.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  String? loginError;
  bool showLoginError = false;

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }

    if (value.length != 10) {
      return "Enter a valid phone number";
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      showLoginError = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    //====================
    // Temporary test
    //====================
    if (phoneController.text != "9812345678" ||
        passwordController.text != "password123") {
      setState(() {
        isLoading = false;
        showLoginError = true;
        loginError = "Incorrect phone number or password.";
      });
      return;
    }
    // later replace with API response:
    // if (response.statusCode == 401) {
    //   setState(() {
    //     showLoginError = true;
    //     loginError = "Incorrect phone number or password.";
    //   });
    // }

    setState(() {
      isLoading = false;
      showLoginError = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login Successful"),
      ),
    );
  }
  //================================

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
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

            //=====================
            // TEMPLE BACKGROUND
            //=====================
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  "assets/images/bg(login).png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height:60),

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

                    //========================
                    // CONNECTING SKILL
                    //========================

                    const SizedBox(height: 0),
                    const Text(
                      "Connecting skilled hands\nwith every home.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w700
                      ),
                    ),

                    //=========================
                    //FORM BOX
                    //=========================

                    const SizedBox(height: 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Transform.translate(
                        offset: const Offset(0, 60),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.04),
                                blurRadius: 18,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),

                          child: Transform.translate(
                            offset: const Offset(0, -50),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 130,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        //=======================================
                                        //WELCOME BACK ,MSG AND HOUSE
                                        //=======================================
                                        Positioned(
                                          left: 0,
                                          top: 50,
                                          right: 110,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                "Welcome Back",
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                              SizedBox(height: 0),
                                              Text(
                                                "Login to your Rojgari account",
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Positioned(
                                          right: -10,
                                          bottom: 5,
                                          child: Image.asset(
                                            "assets/images/house(login).png",
                                            height: 140,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  //==========================
                                  //PHONE NUMBER
                                  //==========================
                                  const SizedBox(height: 0),
                                  CustomTextField(
                                    label: "Phone Number",
                                    hintText: "Enter your phone number",
                                    fieldType: FieldType.phone,
                                    controller: phoneController,
                                    validator: validatePhone,
                                    showLabel: true,
                                  ),


                                  //==============================
                                  //PASSWORD
                                  //==============================
                                  const SizedBox(height: 10),
                                  CustomTextField(
                                    label: "Password",
                                    hintText: "Enter password",
                                    fieldType: FieldType.password,
                                    controller: passwordController,
                                    validator: validatePassword,
                                    showLabel: true,
                                  ),

                                  if (showLoginError) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      loginError ?? "",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],


                                  //=================================
                                  //FORGET PASSWORD
                                  //=================================
                                  const SizedBox(height: 0),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) {
                                        //       return const ForgotPasswordScreen();
                                        //     },
                                        //   ),
                                        // );
                                      },
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 15,

                                        ),
                                      ),
                                    ),
                                  ),

                                  //================================
                                  //LOGIN
                                  //================================
                                  const SizedBox(height: 10),
                                  CustomButton(
                                    text: "Login",
                                    isLoading: isLoading,
                                    onPressed: login,
                                  ),

                                  //==================================
                                  //SIGN UP
                                  //==================================
                                  const SizedBox(height:8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                          "Don't have an account?",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppColors.black,
                                          )
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return const CustomerSignupScreen();
                                              },
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.only(bottom: 0),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        )

                                      ),
                                    ],
                                  ),

                                  //==============================
                                  // SECURITY
                                  //==============================
                                  // const SizedBox(height: 5),
                                  // Container(
                                  //   width: double.infinity,
                                  //   padding: const EdgeInsets.symmetric(
                                  //     vertical: 0,
                                  //     horizontal: 28,
                                  //   ),
                                  //   // decoration: BoxDecoration(
                                  //   //   color: const Color(0xffFAFAFC),
                                  //   //   borderRadius: BorderRadius.circular(18),
                                  //   // ),
                                  //   child: Row(
                                  //     children: [
                                  //       Icon(
                                  //         Icons.gpp_good_outlined,
                                  //         color: AppColors.primary,
                                  //         size: 18,
                                  //       ),
                                  //
                                  //       const SizedBox(width: 5),
                                  //       const Expanded(
                                  //         child: Column(
                                  //           crossAxisAlignment:
                                  //               CrossAxisAlignment.start,
                                  //           children: [
                                  //             Text(
                                  //               "Your information is safe with us.",
                                  //               style: TextStyle(
                                  //                 fontWeight: FontWeight.w600,
                                  //                 fontSize: 16,
                                  //                 color: AppColors.grey,
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
