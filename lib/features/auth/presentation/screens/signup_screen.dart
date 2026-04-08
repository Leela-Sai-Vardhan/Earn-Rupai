import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../referral/services/referral_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _referrerName;
  bool? _referralCodeValid;
  bool _isValidatingCode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _referralCodeValid = null;
        _referrerName = null;
      });
      return;
    }

    setState(() => _isValidatingCode = true);

    try {
      final referralService = ReferralService();
      final result = await referralService.validateReferralCode(code);
      
      if (result != null && result['valid'] == true) {
        if (result['profile_complete'] == true) {
          setState(() {
            _referralCodeValid = true;
            _referrerName = result['referrer_name'];
          });
        } else {
          setState(() {
            _referralCodeValid = false;
            _referrerName = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This referral code is not eligible (incomplete profile)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() {
          _referralCodeValid = false;
          _referrerName = null;
        });
      }
    } catch (e) {
      setState(() {
        _referralCodeValid = false;
        _referrerName = null;
      });
    } finally {
      setState(() => _isValidatingCode = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('📝 Attempting signup with email: ${_emailController.text.trim()}');
      
      // Sign up the user - profile will be created automatically by database trigger
      final response = await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      if (!mounted) return;

      if (response.user != null) {
        debugPrint('✅ User created with ID: ${response.user!.id}');
        debugPrint('✅ Profile created automatically by database trigger');
        
        // If referral code was provided, attempt to validate and use it
        final referralCode = _referralCodeController.text.trim();
        if (referralCode.isNotEmpty) {
          // Wait for profile to be created by trigger (Critical for FK constraints)
          bool profileExists = false;
          int attempts = 0;
          while (!profileExists && attempts < 5) {
            try {
              final profile = await SupabaseService.client
                  .from('user_profiles')
                  .select()
                  .eq('user_id', response.user!.id)
                  .maybeSingle();
              
              if (profile != null) {
                profileExists = true;
                debugPrint('✅ Profile found on attempt ${attempts + 1}');
              } else {
                debugPrint('⏳ Waiting for profile creation... ($attempts)');
                await Future.delayed(const Duration(seconds: 1));
                attempts++;
              }
            } catch (e) {
              debugPrint('⚠️ Error checking profile: $e');
              attempts++;
              await Future.delayed(const Duration(seconds: 1));
            }
          }

          if (profileExists) {
            try {
              final referralService = ReferralService();
              // Validate code if not already validated
              Map<String, dynamic>? validationResult;
              
              if (_referralCodeValid == true && _referrerName != null) {
                 // Use cached result if valid
                 // We need to re-fetch the ID though if we didn't store it, 
                 // but since we don't store the full object, safer to re-validate.
                 validationResult = await referralService.validateReferralCode(referralCode);
              } else {
                 validationResult = await referralService.validateReferralCode(referralCode);
              }
              
              if (validationResult != null && validationResult['valid'] == true) {
                // Use RPC to create referral (bypasses RLS)
                try {
                  await SupabaseService.client.rpc(
                    'create_referral_link',
                    params: {
                      'p_referrer_id': validationResult['referrer_id'],
                      'p_referred_user_id': response.user!.id,
                      'p_referral_code': referralCode,
                    },
                  );
                  debugPrint('✅ Referral relationship created successfully');
                } catch (e) {
                  debugPrint('⚠️ Failed to create referral via RPC: $e');
                  // Don't fail signup if referral fails
                }
              } else {
                debugPrint('⚠️ Referral code invalid or ignored during signup');
              }
            } catch (e) {
              debugPrint('⚠️ Failed to create referral: $e');
            }
          } else {
            debugPrint('❌ Profile creation timed out. Skipping referral linking.');
          }
        }
      }

      debugPrint('✅ Signup successful!');
      if (!mounted) return;

      // Navigate to OTP verification screen
      context.go('/auth/otp-verify', extra: {'email': _emailController.text.trim()});
    } catch (e, stackTrace) {
      debugPrint('❌ Signup error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      
      // Show user-friendly error message
      String errorMessage = 'Signup failed';
      if (e.toString().contains('already registered')) {
        errorMessage = 'This email is already registered. Please login instead.';
      } else if (e.toString().contains('rate_limit')) {
        errorMessage = 'Too many attempts. Please wait a minute and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/images/logo_new.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Create Account',
                  style: AppTextStyles.h2(
                    color: isDark ? AppColors.lightText : AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to start earning',
                  style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Name Field
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Referral Code Field (Optional)
                TextFormField(
                  controller: _referralCodeController,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    // Reset validation when user types
                    if (_referralCodeValid != null) {
                      setState(() {
                        _referralCodeValid = null;
                        _referrerName = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    hintText: 'Enter referrer\'s phone number',
                    prefixIcon: const Icon(Icons.card_giftcard_outlined),
                    suffixIcon: _isValidatingCode
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _referralCodeController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  _referralCodeValid == true
                                      ? Icons.check_circle
                                      : Icons.search,
                                  color: _referralCodeValid == true
                                      ? Colors.green
                                      : null,
                                ),
                                onPressed: _validateReferralCode,
                                tooltip: 'Validate code',
                              )
                            : null,
                  ),
                ),
                if (_referrerName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Valid code from $_referrerName',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Signup Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: 24),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
