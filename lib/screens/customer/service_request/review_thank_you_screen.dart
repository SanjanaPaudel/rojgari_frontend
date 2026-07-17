import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';

class ReviewThankYouScreen extends StatefulWidget {
  const ReviewThankYouScreen({this.onBackToHome, super.key});

  final VoidCallback? onBackToHome;

  @override
  State<ReviewThankYouScreen> createState() => _ReviewThankYouScreenState();
}

class _ReviewThankYouScreenState extends State<ReviewThankYouScreen>
    with TickerProviderStateMixin {
  late final AnimationController _successController;
  late final AnimationController _confettiController;
  bool _animationsStarted = false;
  bool _homeNavigationTriggered = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationsStarted) return;
    _animationsStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _successController.value = 1;
      _confettiController.value = 1;
    } else {
      _successController.forward();
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _backToHome() {
    if (_homeNavigationTriggered) return;
    _homeNavigationTriggered = true;

    // NAVIGATION INTEGRATION:
    // Return to the existing customer dashboard and clear the completed
    // booking, rating, and success pages from the stack. Prefer the supplied
    // established dashboard callback. The fallback pops to the first existing
    // route so it does not create a duplicate CustomerHomeScreen.
    final callback = widget.onBackToHome;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _backToHome();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFBF9FF),
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) => CustomPaint(
                        key: const ValueKey('review-confetti'),
                        painter: ReviewConfettiPainter(
                          progress: _confettiController.value,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      _AnimatedSuccessMark(controller: _successController),
                      const SizedBox(height: 34),
                      const Text(
                        'Thank You!',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your review has been submitted\nsuccessfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(flex: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          key: const ValueKey('back-to-home-button'),
                          onPressed: _backToHome,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSuccessMark extends StatelessWidget {
  const _AnimatedSuccessMark({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final ringProgress = Curves.easeOut.transform(controller.value);
        return SizedBox(
          key: const ValueKey('animated-success-check'),
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 142 * ringProgress,
                height: 142 * ringProgress,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(
                    alpha: .04 * (1 - controller.value) + .035,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 118 * ringProgress,
                height: 118 * ringProgress,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .11),
                  shape: BoxShape.circle,
                ),
              ),
              Transform.scale(
                scale: curved.value,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: .2),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: controller,
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.green,
                      size: 52,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewConfettiPainter extends CustomPainter {
  ReviewConfettiPainter({required this.progress});

  final double progress;

  static const _colors = <Color>[
    AppColors.primary,
    AppColors.green,
    AppColors.orange,
    AppColors.secondary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * .3);
    for (var index = 0; index < 28; index++) {
      final delay = (index % 7) * .035;
      final particleProgress = ((progress - delay) / (1 - delay)).clamp(
        0.0,
        1.0,
      );
      if (particleProgress <= 0 || particleProgress >= 1) continue;
      final angle = (index * 2.399) - math.pi;
      final horizontalVelocity = math.cos(angle) * (75 + index % 5 * 13);
      final verticalVelocity = math.sin(angle) * (65 + index % 4 * 11) - 45;
      final x = origin.dx + horizontalVelocity * particleProgress;
      final y =
          origin.dy +
          verticalVelocity * particleProgress +
          150 * particleProgress * particleProgress;
      final paint = Paint()
        ..color = _colors[index % _colors.length].withValues(
          alpha: (1 - particleProgress).clamp(0.0, 1.0),
        );
      final particleSize = 3.0 + index % 3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + progress * math.pi);
      if (index.isEven) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize * 1.8,
            height: particleSize,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particleSize / 1.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ReviewConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
