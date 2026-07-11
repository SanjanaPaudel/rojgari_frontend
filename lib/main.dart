import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
import 'package:rojgari_frontend_one/screens/customer/profile_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/logIn_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
// import 'screens/welcome/welcome_screen.dart';
// import 'core/theme/app_theme.dart';
// import 'screens/technician/technician_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // home: OTPScreen(
      //   phoneNumber: "9812345678",
      // ),
      theme: AppTheme.lightTheme,

      // home: const CustomerSignupScreen(),
      // home: WelcomeScreen(),
      // home: const CustomerHomeScreen(),
      home: const CustomerProfileScreen(),

      // home: const TechnicianHomeScreen(),
    );
  }
}
