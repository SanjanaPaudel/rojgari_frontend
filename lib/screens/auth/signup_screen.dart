import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/widgets/custom_textfield.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:rojgari_frontend_one/services/auth_service.dart';

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
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();


  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;
  String? fullNameError;
  String? emailError;
  bool hasError = false;
  bool isWorker = false;
  bool isLoading = false;

  // Validation of the sign_up form. If every field is valid returns true otherwise false
  bool validateFields() {
    hasError = false; // false mean haven't found any error

    //Clear previous backend/frontend errors
    phoneError = null;
    passwordError = null;
    confirmPasswordError = null;
    fullNameError = null;
    emailError = null;

    // Full Name
    if (fullNameController.text.trim().isEmpty) {
      fullNameError = "Full name is required";
      hasError = true;
    }

    // Phone
    if (phoneController.text.trim().isEmpty) {
      phoneError = "Phone number is required";
      hasError = true;
    } else if (!RegExp(r'^(97|98)\d{8}$')
        .hasMatch(phoneController.text.trim())) {
      phoneError = "Enter a valid Nepal phone number";
      hasError = true;
    }

    // Email
    if (emailController.text.trim().isEmpty) {
      emailError = "Email is required";
      hasError = true;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(emailController.text.trim())) {
      emailError = "Enter a valid email address";
      hasError = true;
    }

    // Password
    final password = passwordController.text;
    if (password.isEmpty) {
      passwordError = "Password is required";
      hasError = true;
    } else if (password.length < 8) {
      passwordError = "Password must be at least 8 characters.";
      hasError = true;
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passwordError =
      "Password must contain at least one uppercase letter.";
      hasError = true;
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      passwordError =
      "Password must contain at least one lowercase letter.";
      hasError = true;
    } else if (!RegExp(r'\d').hasMatch(password)) {
      passwordError =
      "Password must contain at least one number.";
      hasError = true;
    } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
        .hasMatch(password)) {
      passwordError =
      "Password must contain at least one special character.";
      hasError = true;
    }

    // Confirm Password
    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError = "Please confirm your password";
      hasError = true;
    } else if (confirmPasswordController.text != password) {
      confirmPasswordError = "Passwords do not match";
      hasError = true;
    }

    setState(() {}); // tells the flutter to rebuild the textfield with the changes/errors
    return !hasError; // -> if validateFields() returns true means all fields are valid(validation pass) and continue else otherwise.
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
                  "assets/images/bg_signup.png",
                  fit: BoxFit.cover,
                ),
              )
            ),

            SingleChildScrollView(
              child: Form(
                key: _formKey,
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
                                errorMsg: phoneError,
                              ),

                              const SizedBox(height: 10),

                              CustomTextField(
                                controller: passwordController,
                                label: "Password",
                                hintText: "Create your password",
                                fieldType: FieldType.password,
                                errorMsg: passwordError,
                              ),

                              const SizedBox(height: 10),

                              CustomTextField(
                                controller: confirmPasswordController,
                                label: "Confirm Password",
                                hintText: "Re-enter your password",
                                fieldType: FieldType.password,
                                errorMsg: confirmPasswordError,
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
                                errorMsg: fullNameError,
                              ),

                              const SizedBox(height: 10),

                              CustomTextField(
                                controller: emailController,
                                label: "Email Address",
                                hintText: "Enter your email address",
                                fieldType: FieldType.email,
                                errorMsg: emailError,
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
                                        image: _selectedImage != null
                                            ? DecorationImage(
                                          image: FileImage(_selectedImage!),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),
                                      child: _selectedImage == null
                                          ? const Icon(
                                        Icons.image_outlined,
                                        color: AppColors.primary,
                                        size: 24,
                                      )
                                          : null,
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
                                      onPressed: pickImage,
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

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isWorker,
                                    onChanged: (value) {
                                      setState(() {
                                        isWorker = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text("I want to sign up as a worker"),
                                ],
                              ),

                              const SizedBox(height: 20),

                              //====================================================
                              // SIGN UP BUTTON
                              //====================================================
                              CustomButton(
                                text: "Sign Up",
                                icon: Icons.arrow_forward,
                                isLoading: isLoading,
                                onPressed: () async {

                                  if (!validateFields()) {
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  final response = await _authService.signup(
                                    phone: phoneController.text.trim(),
                                    password: passwordController.text,
                                    fullName: fullNameController.text.trim(),
                                    email: emailController.text.trim(),
                                    confirmPassword: confirmPasswordController.text,
                                    profilePhoto: _selectedImage,
                                    role: isWorker ? "worker" : "customer",
                                  );
                                  print("SIGNUP RESPONSE: $response");

                                  setState(() {
                                    isLoading = false;
                                  });

                                  //clear and store backend errors
                                  setState(() { //Due to the setState , the customFiled is rebuild by flutter immediately if any error msg (from backend) with error msg or if no error msg clears the variable and rebuilds
                                    phoneError = response["phone_number"]?.first; //"Look for a phone_number error in the backend response. If it exists, take the first error message from the list and store it in phoneError. If it doesn't exist, store null."
                                    emailError = response["email"]?.first;
                                    passwordError = response["password"]?.first;
                                    confirmPasswordError = response["confirm_password"]?.first;
                                    fullNameError = response["full_name"]?.first;
                                  });


                                  // Stop if backend returned validation error
                                  if (phoneError != null ||
                                      emailError != null ||
                                      passwordError != null ||
                                      confirmPasswordError != null ||
                                      fullNameError != null) {
                                    return; // Stops executing onPressed() i.e don't navigate to the OTP screen
                                  }
                                  // Signup successful
                                  if (response["message"] == "OTP sent successfully.") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OTPScreen(
                                          email: emailController.text.trim(),
                                          phone: phoneController.text.trim(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 20),
                              //====================================================
                              // LOGIN
                              //====================================================
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.grey,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "Already have an account? ",
                                      ),
                                      TextSpan(
                                        text: "Log In",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return const LoginScreen();
                                                },
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

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
              )

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