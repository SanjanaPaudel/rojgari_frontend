import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/screens/auth/logIn_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: OTPScreen(
      //   phoneNumber: "9812345678",
      // ),

      // home: const CustomerSignupScreen(),
      home: LoginScreen(),

    );
  }
}