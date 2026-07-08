import 'package:flutter/material.dart';
// import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
import 'package:rojgari_frontend_one/screens/auth/reset_passord_screen.dart';



void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: OTPScreen(
      //   email: "email",
      // ),

      // theme: AppTheme.lightTheme,

      // home: const CustomerSignupScreen(),
      // home: WelcomeScreen(),
      // home: LoginScreen(),
      // home: const TechnicianHomeScreen(),
      home: ResetPasswordScreen(),

    );
  }
}
