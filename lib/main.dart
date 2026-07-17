import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
import 'package:rojgari_frontend_one/services/navigation_service.dart';
// import 'package:rojgari_frontend_one/screens/auth/logIn_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/otp_screen.dart';
// import 'screens/welcome/welcome_screen.dart';
// import 'core/theme/app_theme.dart';
// import 'screens/technician/technician_home_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/reset_passord_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/forget_password_email_screen.dart';
// import 'package:rojgari_frontend_one/screens/auth/skill_selection_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/customer/service_request/finding_service_person_preview.dart';
// import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
// import 'core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
// import 'package:rojgari_frontend_one/screens/customer/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

// TEMPORARY FEATURE PREVIEW:
// A normal debug `flutter run` opens the finding-service-person preview so the
// UI can be reviewed without authentication or a backend connection. Release
// builds always use SplashScreen. To run the normal debug app, use:
// flutter run --dart-define=FINDING_SERVICE_PERSON_PREVIEW=false
const bool _findingServicePersonPreviewEnabled = bool.fromEnvironment(
  'FINDING_SERVICE_PERSON_PREVIEW',
  defaultValue: true,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // The global navigator key used by ApiService._logoutUser() to push the
      // LoginScreen when the session expires anywhere in the app — including
      // inside background service calls that have no BuildContext of their own.
      navigatorKey: NavigationService.navigatorKey,

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
      home: kDebugMode && _findingServicePersonPreviewEnabled
          ? const FindingServicePersonPreview()
          : SplashScreen(),

      // home: const CustomerHomeScreen(),
      // home: const CustomerProfileScreen(),
      // home: const TechnicianHomeScreen(),
      //home: const TechnicianProfileScreen(),
    );
  }
}
