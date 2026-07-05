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

/// Everything that changes while the screen is running
/// belongs inside this State class.
class _LoginScreenState extends State<LoginScreen> {
  /// Reads the phone number entered by the user.
  final phoneController = TextEditingController(); // stores object of TextEditingController() into variable phoneController

  /// Reads the password entered by the user.
  final passwordController = TextEditingController();

  /// Object used to communicate with backend APIs.
  final AuthService _authService = AuthService();

  bool isLoading = false; //Controls loading spinner of login button

  /// Stores backend error message.
  String? phoneError;
  String? passwordError;
  String? generalError;
  bool hasError = false;

  //=========================================================
  // Displays an error in the correct place on the screen.
  //=========================================================
  void showFieldError(String field, String message) {
    setState(() {
      switch (field) {
        case "phone":
          phoneError = message;
          break;

        case "password":
          passwordError = message;
          break;

        default:
          generalError = message;
      }
    });
  }

  //---------------------------------------------------------
  // Cleanup
  //---------------------------------------------------------
  @override
  void dispose() {
    /// Free memory used by controllers.
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  //---------------------------------------------------------
  // UI
  //---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // keyboard close when user taps outside textfield.
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack( //Allows widgets ot overlap
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

            child: Column(
              children: [

                const SizedBox(height: 60),

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
                                showLabel: true,
                                serverError: phoneError,
                                // validator: (value) {
                                //   // Empty field validation.
                                //   if (value == null ||
                                //       value.trim().isEmpty) {
                                //     showFieldError(
                                //       "phone",
                                //       "Phone number is required",
                                //     );
                                //   }
                                //
                                //   return;
                                // },

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
                                showLabel: true,
                                serverError: passwordError,

                                // validator: (value) {
                                //
                                //   if (value == null ||
                                //       value.isEmpty) {
                                //     showFieldError(
                                //       "password",
                                //       "Password is required",
                                //     );
                                //   }
                                //   return;
                                // },
                              ),

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
                                  onPressed: () async {

                                    if (phoneController.text.trim().isEmpty) {
                                      phoneError = "Phone number is required";
                                      hasError = true;
                                    }

                                    if (passwordController.text.isEmpty) {
                                      passwordError = "Password is required";
                                      hasError = true;
                                    }

                                    setState(() {
                                    });

                                    if (hasError) return;

                                    setState(() {
                                      isLoading = true;
                                    });

                                    await Future.delayed(const Duration(seconds: 2));

                                    setState(() {
                                      isLoading = false;
                                    });

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Login Successful!"),
                                        backgroundColor: Colors.green,
                                      )
                                    );

                                    //Backend call
                                    // final result = await _authService.login(
                                    //   phone: phoneController.text,
                                    //   password: passwordController.text,
                                    // );

                                    //Stops loading spinner
                                    // setState(() {
                                    //   isLoading = false;
                                    // });

                                    //Backend Response
                                    // if (result["success"] == true) {
                                    //
                                    //   // TODO
                                    //
                                    //   // Navigate Home Screen.
                                    //
                                    // } else {
                                    //
                                    //   setState(() {
                                    //     showFieldError(
                                    //       "general",
                                    //       result["message"],
                                    //     );
                                    //   });
                                    // }
                                  },
                              ),

                              //==================================
                              //SIGN UP
                              //==================================
                              const SizedBox(height: 8),
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
                                        padding: const EdgeInsets.only(
                                            bottom: 0),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
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
            ],
          ),
        ),
      )
    );
  }
}
