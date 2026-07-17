import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
import 'package:rojgari_frontend_one/models/technician/incoming_service_request_details.dart';
import 'package:rojgari_frontend_one/screens/technician/incoming_request_details_screen.dart';
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
// import 'screens/splash/splash_screen.dart';
// import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
// import 'core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/core/theme/app_theme.dart';
// import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
// import 'package:rojgari_frontend_one/screens/customer/profile_screen.dart';

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
      theme: AppTheme.lightTheme,

      // The global navigator key used by ApiService._logoutUser() to push the
      // LoginScreen when the session expires anywhere in the app — including
      // inside background service calls that have no BuildContext of their own.
      navigatorKey: NavigationService.navigatorKey,

      // home: OTPScreen(
      //   email: "email",
      // ),

      // home: const CustomerSignupScreen(),
      // home: WelcomeScreen(),
      // home: LoginScreen(),
      // home: const TechnicianHomeScreen(),
      // home: ResetPasswordScreen(),
      // home: ForgotPasswordEmailScreen(),
      // home: SkillSelectionScreen()
      // Temporarily disabled while previewing Incoming Request Details:
      // home: SplashScreen(),

      // FRONTEND PREVIEW DATA ONLY:
      // Replace this object with repository/API-mapped request details when the
      // technician dashboard is connected by the backend integrator.
      home: IncomingRequestDetailsScreen(
        request: const IncomingServiceRequestDetails(
          id: 'preview-request-001',
          customerName: 'Ram Bahadur',
          categoryId: 'plumbing',
          categoryName: 'Plumbing Service',
          categorySlug: 'plumbing',
          description:
              'Kitchen pipe is leaking under the sink and water is dripping continuously.',
          locationText: 'Lazimpat, Kathmandu',
          distanceKm: 2.4,
          photoUrls: [
            'assets/images/plumbing_icon.png',
            'assets/images/toolbox.png',
            'assets/images/technician.png',
          ],
          videoUrl: 'preview-video-not-connected',
          videoThumbnailUrl: 'assets/images/plumbing_icon.png',
          videoDurationSeconds: 18,
          status: 'new',
        ),
      ),

      // home: const CustomerHomeScreen(),
      // home: const CustomerProfileScreen(),
      // home: const TechnicianHomeScreen(),
      //home: const TechnicianProfileScreen(),
    );
  }
}
