import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() =>
      _CustomerSignupScreenState();
}

class _CustomerSignupScreenState
    extends State<CustomerSignupScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                opacity: 0.5,
                child: Image.asset(
                  "assets/images/mandala.png",
                  height: 600,
                  // fit: BoxFit.cover,
                ),
              ),
            ),

            //=========================
            // TEMPLE BACKGROUND
            //=========================
            Positioned(
              top: 135,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  "assets/images/bg.png",
                  fit: BoxFit.cover,
                ),
              )
            ),

            SingleChildScrollView(
              child: Column(
                children: [

                  const SizedBox(height: 15),
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

                  const SizedBox(height: 0),
                  //--------------------------------
                  // LOGO AND ORANGE LINE
                  //--------------------------------
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
                            "assets/images/logo_text.png",
                            height: 130,
                          ),
                        ),

                        Positioned(
                          top: 105,
                          child: Container(
                            width: 24,
                            height: 1,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 0),
                  //--------------------------------
                  // TITLE AND GIRL
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
                            // TITLE & SUBTITLE
                            //==========================
                            Positioned(
                              left: 0,
                              top: 60,
                              right: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "Create Your Account",
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),

                                  const SizedBox(height: 0),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.grey,
                                        height: 1.5,
                                      ),
                                      children: [

                                        TextSpan(
                                          text: "Connect, collaborate, and grow\n",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),

                                        TextSpan(
                                          text: "with the Rojgari community.",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            //==========================
                            // GIRL ILLUSTRATION
                            //==========================
                            Positioned(
                              right: -10,
                              bottom: -15,
                              child: Image.asset(
                                "assets/images/girl(_cus-sign).png",
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  //--------------------------------
                  // WHITE CARD
                  //--------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Transform.translate(
                      offset: const Offset(0, -100),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.04),
                              blurRadius: 18,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),

                        padding: const EdgeInsets.fromLTRB(
                          22,
                          30,
                          22,
                          30,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            //====================================================
                            // ACCOUNT INFORMATION
                            //====================================================

                            _buildSectionTitle(
                              icon: Icons.person_outline_rounded,
                              title: "Account Information",
                            ),

                            const SizedBox(height: 10),

                            CustomTextField(
                              controller: phoneController,
                              label: "Phone Number",
                              hintText: "Enter your phone number",
                              fieldType: FieldType.phone,
                            ),

                            const SizedBox(height: 10),

                            CustomTextField(
                              controller: passwordController,
                              label: "Password",
                              hintText: "Create your password",
                              fieldType: FieldType.password,
                            ),

                            const SizedBox(height: 10),

                            CustomTextField(
                              controller: confirmPasswordController,
                              label: "Confirm Password",
                              hintText: "Re-enter your password",
                              fieldType: FieldType.password,
                            ),

                            const SizedBox(height: 30),

                            //====================================================
                            // PERSONAL INFORMATION
                            //====================================================

                            _buildSectionTitle(
                              icon: Icons.badge_outlined,
                              title: "Personal Information",
                            ),

                            const SizedBox(height: 15),

                            CustomTextField(
                              controller: fullNameController,
                              label: "Full Name",
                              hintText: "Enter your full name",
                              fieldType: FieldType.text,
                            ),

                            const SizedBox(height: 10),

                            CustomTextField(
                              controller: emailController,
                              label: "Email Address (Optional)",
                              hintText: "Enter your email address",
                              fieldType: FieldType.email,
                            ),

                            const SizedBox(height: 30),

                            //====================================================
                            // PROFILE PHOTO
                            //====================================================

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [

                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPurple,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Text(
                                          "Profile Photo",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),

                                        SizedBox(height: 0),

                                        Text(
                                          "Upload a profile picture (Optional)",
                                          style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Upload",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            //====================================================
                            // SIGN UP BUTTON
                            //====================================================
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    // gradient: const LinearGradient(
                                    //   begin: Alignment.centerLeft,
                                    //   end: Alignment.centerRight,
                                    //   colors: [
                                    //     Color(0xff9A6BFF),
                                    //     Color(0xff6C3BFF),
                                    //   ],
                                    // ),
                                    // borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            //====================================================
                            // LOGIN
                            //====================================================

                            Center(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.grey,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Already have an account? ",
                                    ),
                                    TextSpan(
                                      text: "Log In",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            //====================================================
                            // SECURITY
                            //====================================================

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffFAFAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.gpp_good_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),

                                  const SizedBox(width: 15),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Text(
                                          "Your information is safe with us.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.black,
                                          ),
                                        ),

                                        SizedBox(height: 4),

                                        Text(
                                          "We use industry-standard security to protect your personal information.",
                                          style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
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
    );
  }
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.lightPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}