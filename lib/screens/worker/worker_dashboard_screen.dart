import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';

// Placeholder dashboard shown to a "worker" role user right after
// successful signup + OTP verification. Build out real widgets/data here later.
class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Worker Dashboard",
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.grey),
            tooltip: "Log out",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This is your worker dashboard. Job requests, "
                    "earnings, and skill management will live here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}