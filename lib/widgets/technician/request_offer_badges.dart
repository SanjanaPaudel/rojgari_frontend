import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Live "time left to respond" pill — ticks down every second and shifts
/// from primary -> orange -> red as the offer gets close to expiring. Calls
/// [onExpired] once, the moment it reaches zero (including immediately, in
/// initState, if [initialSeconds] is already <= 0 when built).
class ExpiryCountdownBadge extends StatefulWidget {
  const ExpiryCountdownBadge({
    super.key,
    required this.initialSeconds,
    this.onExpired,
  });

  final int initialSeconds;
  final VoidCallback? onExpired;

  @override
  State<ExpiryCountdownBadge> createState() => _ExpiryCountdownBadgeState();
}

class _ExpiryCountdownBadgeState extends State<ExpiryCountdownBadge> {
  late int _remainingSeconds = widget.initialSeconds;
  Timer? _timer;
  bool _hasNotifiedExpired = false;

  static const int _urgentThreshold = 20;
  static const int _warningThreshold = 60;

  @override
  void initState() {
    super.initState();
    if (_remainingSeconds <= 0) {
      _notifyExpiredOnce();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) _notifyExpiredOnce();
    });
  }

  void _notifyExpiredOnce() {
    if (_hasNotifiedExpired) return;
    _hasNotifiedExpired = true;
    widget.onExpired?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _color {
    if (_remainingSeconds <= _urgentThreshold) return AppColors.red;
    if (_remainingSeconds <= _warningThreshold) return AppColors.orange;
    return AppColors.primary;
  }

  String get _label {
    if (_remainingSeconds <= 0) return 'Expired';
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            _label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The offer's visit charge — what the worker earns just for showing up,
/// separate from any final job price.
class VisitChargeBadge extends StatelessWidget {
  const VisitChargeBadge({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 13,
            color: AppColors.green,
          ),
          const SizedBox(width: 4),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
