import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';

class TechnicianWorkCompletedScreen extends StatefulWidget {
  const TechnicianWorkCompletedScreen({this.onBackToHome, super.key});

  final VoidCallback? onBackToHome;

  @override
  State<TechnicianWorkCompletedScreen> createState() =>
      _TechnicianWorkCompletedScreenState();
}

class _TechnicianWorkCompletedScreenState
    extends State<TechnicianWorkCompletedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBackToHome() {
    final callback = widget.onBackToHome;
    if (callback != null) {
      callback();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Back to Technician Dashboard navigation is ready.'),
        ),
      );

    // NAVIGATION INTEGRATION:
    // Replace the SnackBar with the established technician-dashboard route and
    // clear the completed active-job stack. For example, after confirming the
    // final dashboard constructor/route:
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const TechnicianHomeScreen()),
    //   (route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _AnimatedCompletionMark(controller: _controller),
                const SizedBox(height: 34),
                const Text(
                  'Your work is completed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thank you! The job has been completed. You can now '
                  'continue to your next request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    key: const ValueKey('technician-back-home-button'),
                    onPressed: _handleBackToHome,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCompletionMark extends StatelessWidget {
  const _AnimatedCompletionMark({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        FadeTransition(
          opacity: controller,
          child: Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        ScaleTransition(
          scale: Tween<double>(begin: .25, end: 1).animate(curved),
          child: Container(
            key: const ValueKey('technician-completion-check'),
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: .2),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.green,
              size: 54,
            ),
          ),
        ),
        const Positioned(
          left: -12,
          top: 18,
          child: _DecorationDot(color: AppColors.primary, size: 8),
        ),
        const Positioned(
          right: -7,
          top: 28,
          child: _DecorationDot(color: AppColors.green, size: 7),
        ),
        const Positioned(
          left: 4,
          bottom: 4,
          child: Icon(Icons.add, color: AppColors.primary, size: 19),
        ),
      ],
    );
  }
}

class _DecorationDot extends StatelessWidget {
  const _DecorationDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
