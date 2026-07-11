import 'package:flutter/material.dart';
// import 'screens/welcome/welcome_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/reset_passord_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/forget_password_email_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/skill_selection_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: WelcomeScreen(),
        // home: OTPScreen(
        //   email: "email",
        // ),

        // theme: AppTheme.lightTheme,

        // home: const CustomerSignupScreen(),
        // home: WelcomeScreen(),
        // home: LoginScreen(),
    // home: const TechnicianHomeScreen(),
    // home: ResetPasswordScreen(),
    // home: ForgotPasswordEmailScreen(),
    // home: SkillSelectionScreen()
      home: SplashScreen(),
    );
  }
}