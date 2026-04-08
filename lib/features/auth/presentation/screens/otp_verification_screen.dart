import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/services/supabase_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 8-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await SupabaseService.verifyEmailOtp(
        email: widget.email,
        token: code,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Email verified! Welcome to Earn Rupai!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // User is now logged in — go straight to dashboard
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ OTP verification error: $e');

      String msg = 'Invalid or expired code. Please try again.';
      if (e.toString().contains('expired')) {
        msg = 'Code expired. Please request a new one.';
      } else if (e.toString().contains('invalid')) {
        msg = 'Wrong code. Please check and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      // Clear the boxes on error
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 New code sent! Check your email.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Widget _buildOtpBox(int index, double boxWidth) {
    return SizedBox(
      width: boxWidth,
      height: boxWidth * 1.3,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: boxWidth * 0.48,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 7) {
            _focusNodes[index + 1].requestFocus();
          }
          // Auto-verify when all 8 digits are entered
          if (_otpCode.length == 8) {
            _verifyOtp();
          }
        },
        onEditingComplete: () {
          if (index < 7) _focusNodes[index + 1].requestFocus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/signup'),
        ),
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Check Your Email',
                style: AppTextStyles.h2(
                  color: isDark ? AppColors.lightText : AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent an 8-digit verification code to',
                style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // OTP boxes — dynamic width split into two groups of 4
              LayoutBuilder(
                builder: (context, constraints) {
                  // 4 boxes + 3 inner gaps + 1 center gap per group
                  // total = 8 boxes * w + 6 small gaps + 1 big gap
                  const smallGap = 6.0;
                  const bigGap = 16.0;
                  final boxWidth =
                      (constraints.maxWidth - 6 * smallGap - bigGap) / 8;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First group: digits 1-4
                      for (int i = 0; i < 4; i++) ...[
                        _buildOtpBox(i, boxWidth),
                        if (i < 3) SizedBox(width: smallGap),
                      ],
                      const SizedBox(width: bigGap),
                      // Second group: digits 5-8
                      for (int i = 4; i < 8; i++) ...[
                        _buildOtpBox(i, boxWidth),
                        if (i < 7) SizedBox(width: smallGap),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify & Login'),
                ),
              ),
              const SizedBox(height: 20),
              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style:
                        AppTextStyles.bodyMedium(color: AppColors.greyText),
                  ),
                  _resendCountdown > 0
                      ? Text(
                          'Resend in ${_resendCountdown}s',
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.greyText),
                        )
                      : TextButton(
                          onPressed: _isResending ? null : _resendCode,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Resend'),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Also check your spam folder',
                style: AppTextStyles.bodySmall(color: AppColors.greyText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
