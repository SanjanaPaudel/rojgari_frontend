import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';
import 'package:rojgari_frontend_one/screens/technician/technician_home_screen.dart';
import 'package:rojgari_frontend_one/screens/customer/customer_home_screen.dart';
import 'package:rojgari_frontend_one/screens/auth/skill_selection_screen.dart';
import 'package:rojgari_frontend_one/services/storage_service.dart';
import 'package:rojgari_frontend_one/services/api_service.dart';





/*
  import '../../services/storage_service.dart';
  import '../auth/login_screen.dart';
  import '../customer/customer_home_screen.dart';
  import '../technician/technician_home_screen.dart';
*/

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _letterController;
  Timer? _timer;

  // To change the time of holding splash screen.
  static const int splashDurationSeconds = 1;

  @override
  void initState() {
    super.initState();

    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _letterController.forward();

    _timer = Timer(
      const Duration(seconds: splashDurationSeconds),
      _goToNextScreen,
    );
  }

  Future<void> _goToNextScreen() async {
    if (!mounted) return;

    final ApiService apiService = ApiService();
    final bool isSessionValid = await apiService.checkAndRefreshSession();

    if (!mounted) return;

    if (!isSessionValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
      return;
    }

    final String? nextScreen = await StorageService.getNextScreen();

    Widget destination;
    if (nextScreen == 'customer_dashboard') {
      destination = const CustomerHomeScreen();
    } else if (nextScreen == 'worker_dashboard') {
      destination = const TechnicianHomeScreen();
    } else if (nextScreen == 'select_skills') {
      destination = const SkillSelectionScreen();
    } else {
      // Fallback: token valid but next_screen key missing or unrecognized
      await StorageService.clearTokens();
      destination = LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _letterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double height = constraints.maxHeight;
            final double width = constraints.maxWidth;

            final double cardTop = height * 0.55;

            return SizedBox(
              height: height,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    top: 130,
                    left: 35,
                    child: _DotDecoration(),
                  ),

                  const Positioned(
                    top: 210,
                    right: -35,
                    child: _CircleDecoration(),
                  ),

                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images/logo_r.png",
                          height: 78,
                        ),

                        Transform.translate(
                          offset: const Offset(0, -24),
                          child: Image.asset(
                            "assets/images/logo_text.png",
                            height: 82,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: height * 0.21,
                    left: 24,
                    right: 24,
                    child: const Text(
                      "Connecting skilled hands\nwith every home",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff171633),
                      ),
                    ),
                  ),

                  Positioned(
                    top: height * 0.34,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      "assets/images/bg.png",
                      height: height * 0.28,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: height * 0.29,
                    left: -10,
                    right: -10,
                    child: Image.asset(
                      "assets/images/illustration.png",
                      height: height * 0.36,
                      fit: BoxFit.contain,
                    ),
                  ),

                  Positioned.fill(
                    top: cardTop,
                    child: _WelcomeCard(
                      letterAnimation: _letterController,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =======================
// WHITE WELCOME CARD
// =======================

class _WelcomeCard extends StatelessWidget {
  final Animation<double> letterAnimation;

  const _WelcomeCard({
    required this.letterAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(42),
          topRight: Radius.circular(42),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -18,
            bottom: -18,
            child: _BottomLeafDecoration(),
          ),

          Column(
            children: [
              const _WelcomeTitle(),

              const SizedBox(height: 4),

              _AnimatedRojgariLogo(
                animation: letterAnimation,
              ),

              const SizedBox(height: 6),

              const Text(
                "Your trusted home service partner",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xff77738A),
                ),
              ),

              const SizedBox(height: 16),

              const Row(
                children: [
                  Expanded(
                    child: _FeatureBox(
                      icon: Icons.verified_user_outlined,
                      title: "Verified",
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureBox(
                      icon: Icons.calendar_month_outlined,
                      title: "Fast",
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureBox(
                      icon: Icons.security_outlined,
                      title: "Safe",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: 1,
                ),
                // To change purple line time.
                // Better later: use splashDurationSeconds here too.
                duration: const Duration(seconds: 8),
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xffE8DDFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff6E4AE3),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              const Text(
                "Preparing your experience...",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff77738A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================
// WELCOME TITLE
// =======================

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(width: 14),

        const Text(
          "Welcome to",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xff171633),
          ),
        ),

        const SizedBox(width: 14),

        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

// =======================
// ROJGARI LOGO IMAGE ANIMATION
// =======================

class _AnimatedRojgariLogo extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedRojgariLogo({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      ),
    );

    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Image.asset(
            "assets/images/logo_text.png",
            height: 78,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// =======================
// FEATURE BOX
// =======================

class _FeatureBox extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureBox({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffDCCFFF),
          width: 1.3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xff5C31D6),
            size: 30,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Color(0xff171633),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// DECORATIONS
// =======================

class _DotDecoration extends StatelessWidget {
  const _DotDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(
          12,
              (index) => Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xffD5C7FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleDecoration extends StatelessWidget {
  const _CircleDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xffDCCFFF),
          width: 1.5,
        ),
      ),
    );
  }
}

class _BottomLeafDecoration extends StatelessWidget {
  const _BottomLeafDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: Icon(
        Icons.local_florist,
        size: 95,
        color: const Color(0xff6E4AE3),
      ),
    );
  }
}

// =======================
// TEMPORARY NEXT SCREEN
// =======================

class _TemporaryNextScreen extends StatelessWidget {
  const _TemporaryNextScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F3FF),
      body: Center(
        child: Text(
          "Next screen will be Login / Home",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff171633),
          ),
        ),
      ),
    );
  }
}