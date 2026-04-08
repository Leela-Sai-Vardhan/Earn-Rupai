import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/notification_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if terms are accepted
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to continue'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 Attempting login with email: ${_emailController.text.trim()}');
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('✅ Login successful!');

      // Save FCM token now that user is authenticated
      // (initialize() ran before login, so userId was null at that point)
      await NotificationService().saveTokenIfUserLoggedIn();
      
      // Check if email is verified using robust service check
      if (!SupabaseService.isEmailVerified) {
        debugPrint('⚠️ Email not verified (Service check)');
        if (!mounted) return;
        
        // We do NOT sign out here anymore. 
        // We let the AppRouter redirect to VerifyEmailPromptScreen.
        // This allows the user to use the "I have Verified" button there.
        
        // But we DO show a snackbar to inform them why they are being redirected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email. Redirecting to verification page...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Explicit navigation to prompt (though AppRouter would do it too)
        context.go('/auth/verify-email-prompt');
        return;
      }

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      
      String errorMessage = 'Login failed';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email first';
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'By using EarnRupai, you agree to the following terms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. User Responsibilities\n'
                '• You must be 18+ years old to use this app\n'
                '• Provide accurate information during registration\n'
                '• Complete tasks honestly and according to instructions\n'
                '• Do not create multiple accounts\n'
                '\n'
                '2. Task Completion & Payments\n'
                '• Rewards are credited only after admin verification\n'
                '• Payment processing may take 3-7 business days\n'
                '• We reserve the right to reject fraudulent submissions\n'
                '• Minimum withdrawal threshold applies\n'
                '\n'
                '3. Prohibited Activities\n'
                '• Using bots, scripts, or automation tools\n'
                '• Sharing accounts or credentials\n'
                '• Submitting false or misleading task completions\n'
                '• Attempting to manipulate the reward system\n'
                '\n'
                '4. Liability & Disclaimers\n'
                '• We are not responsible for third-party task providers\n'
                '• External links are provided "as-is"\n'
                '• We do not guarantee task availability\n'
                '• Account suspension may occur for violations\n'
                '\n'
                '5. Data & Privacy\n'
                '• We collect and store user data securely\n'
                '• Your data will not be sold to third parties\n'
                '• We may use anonymized data for analytics\n'
                '\n'
                '6. Modifications\n'
                '• We reserve the right to modify these terms\n'
                '• Continued use implies acceptance of changes\n'
                '\n'
                '7. Legal Protection\n'
                '• Users are responsible for tax obligations on earnings\n'
                '• We are not liable for any losses or damages\n'
                '• Disputes will be resolved under Indian jurisdiction',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
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
                  'Welcome Back!',
                  style: AppTextStyles.h2(
                    color: isDark ? AppColors.lightText : AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue earning',
                  style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
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
                const SizedBox(height: 24),
                // Terms & Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() => _acceptedTerms = value ?? false);
                      },
                      activeColor: AppColors.primaryGreen,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTermsDialog(),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall(
                              color: isDark ? AppColors.lightText : AppColors.darkText,
                            ),
                            children: [
                              const TextSpan(text: 'I accept the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                      : const Text('Login'),
                ),
                const SizedBox(height: 24),
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/signup'),
                      child: const Text('Sign Up'),
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
