import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, this.categoryName});

  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            categoryName == null
                ? 'Booking screen coming soon'
                : '$categoryName booking coming soon',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
