import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EmailVerificationScreen extends StatelessWidget {
  final bool success;
  final String? message;

  const EmailVerificationScreen({
    super.key,
    this.success = true,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 100,
                color: success ? AppColors.primaryGreen : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Email Verified!' : 'Verification Failed',
                style: AppTextStyles.h2(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? (success
                    ? 'Your email has been successfully verified. You can now log in to your account.'
                    : 'There was an error verifying your email. Please try again or contact support.'),
                style: AppTextStyles.bodyLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/auth/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
