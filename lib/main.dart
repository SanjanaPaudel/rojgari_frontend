import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/screens/auth/logIn_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
import 'screens/welcome/welcome_screen.dart';

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
      //   phoneNumber: "9812345678",
      // ),

      // home: const CustomerSignupScreen(),
      //home: WelcomeScreen(),
      home: LoginScreen(),

    );
  }
}
