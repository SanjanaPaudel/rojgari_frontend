import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Reached by tapping a cancelled entry in the customer's booking history.
/// There's nothing to fetch or show for a cancelled booking, so this is a
/// static message screen rather than a loader + detail screen pair like the
/// in-progress/completed cases.
class CancelledBookingDetailsScreen extends StatelessWidget {
  const CancelledBookingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  // Same red used by the "Cancelled" pill on the history
                  // card, so the color language carries through.
                  color: Color(0xFFFFECEC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 34,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This booking has been cancelled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'There are no details to display for a cancelled booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
