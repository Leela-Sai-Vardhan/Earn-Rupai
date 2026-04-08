import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/services/in_app_update_service.dart';
import '../../../referral/services/referral_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Key to force rebuild of FutureBuilder
  int _refreshKey = 0;

  Future<void> _refreshProfile() async {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = SupabaseService.currentUser;
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
            // Profile Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                (user?.userMetadata?['full_name'] as String?)?.substring(0, 1).toUpperCase() ?? 
                (user?.email?.substring(0, 1).toUpperCase() ?? '?'),
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // User Name
            Text(
              user?.userMetadata?['full_name'] as String? ?? 'User',
              style: AppTextStyles.h3(
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            // User Email
            Text(
              user?.email ?? 'No email',
              style: AppTextStyles.bodyMedium(color: AppColors.greyText),
            ),
            const SizedBox(height: 32),
            // Profile Options
            _ProfileOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                _showEditProfileDialog(context, user?.userMetadata?['full_name'] as String?);
              },
            ),
            // Check if user has a referrer, if not show option to add one
            FutureBuilder<bool>(
              key: ValueKey(_refreshKey),
              future: ReferralService().wasUserReferred(user?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return _ProfileOption(
                    icon: Icons.card_giftcard,
                    title: 'Add Referral Code',
                    onTap: () {
                      if (user != null) _showAddReferralDialog(context, user.id);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _ProfileOption(
              icon: Icons.payment,
              title: 'UPI Details',
              onTap: () {
                _showUpiDialog(context);
              },
            ),
            _ProfileOption(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('No new notifications')),
                 );
              },
            ),
            _ProfileOption(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              trailing: Switch(
                value: isDark,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
              ),
            ),
            _ProfileOption(
              icon: Icons.system_update,
              title: 'Check for Updates',
              onTap: () {
                InAppUpdateService.checkForUpdate(context);
              },
            ),
            _ProfileOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                _launchEmail(context, 'ddvardhan2@gmail.com');
              },
            ),
            _ProfileOption(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'EarnRupai',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 EarnRupai. All rights reserved.',
                  applicationIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.currency_rupee, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) {
                    context.go('/auth/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showAddReferralDialog(BuildContext context, String currentUserId) {
    if (!context.mounted) return;
    
    final codeController = TextEditingController();
    bool isValidating = false;
    String? validatorMsg;
    bool isValid = false;
    Map<String, dynamic>? validationData;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Referral Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the phone number of the person who referred you.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Referrer Phone Number',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.card_giftcard),
                  errorText: validatorMsg,
                  counterText: '', // Show default counter (x/10)
                  suffixIcon: isValidating 
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            final code = codeController.text.trim();
                            if (code.isEmpty) return;
                            
                            setState(() {
                              isValidating = true;
                              validatorMsg = null;
                              isValid = false;
                            });
                            
                            try {
                              // First, check if user is trying to add their own phone number
                              try {
                                final currentUserProfile = await SupabaseService.client
                                    .from('user_profiles')
                                    .select('phone_number')
                                    .eq('user_id', currentUserId)
                                    .maybeSingle();
                                
                                if (currentUserProfile != null) {
                                  final currentUserPhone = currentUserProfile['phone_number'] as String?;
                                  if (currentUserPhone != null && currentUserPhone == code) {
                                    setState(() {
                                      validatorMsg = 'You cannot use your own phone number as a referral code';
                                      isValid = false;
                                      isValidating = false;
                                    });
                                    return;
                                  }
                                }
                              } catch (e) {
                                debugPrint('⚠️ Error checking current user phone: $e');
                                // Continue with normal validation even if this check fails
                              }
                              
                              // Try RPC first
                              try {
                                final service = ReferralService();
                                final result = await service.validateReferralCode(code);
                                debugPrint('🔍 RPC Validation result: $result');
                                
                                if (result != null && result['valid'] == true) {
                                  if (result['referrer_id'] == currentUserId) {
                                     setState(() {
                                       validatorMsg = 'You cannot refer yourself';
                                       isValid = false;
                                     });
                                  } else {
                                    setState(() {
                                      isValid = true;
                                      validatorMsg = 'Valid code from ${result['referrer_name']}';
                                      validationData = result;
                                    });
                                  }
                                  return;
                                }
                              } catch (rpcError) {
                                debugPrint('⚠️ RPC validation failed: $rpcError');
                                debugPrint('🔄 Falling back to direct query...');
                              }
                              
                              // Fallback: Direct database query
                              final profile = await SupabaseService.client
                                  .from('user_profiles')
                                  .select('user_id, full_name, phone_number, upi_id')
                                  .eq('phone_number', code)
                                  .maybeSingle();
                              
                              debugPrint('📊 Direct query result: $profile');
                              
                              if (profile != null) {
                                final referrerId = profile['user_id'] as String;
                                final referrerName = profile['full_name'] as String?;
                                final hasUpi = profile['upi_id'] != null && (profile['upi_id'] as String).isNotEmpty;
                                
                                if (referrerId == currentUserId) {
                                  setState(() {
                                    validatorMsg = 'You cannot refer yourself';
                                    isValid = false;
                                  });
                                } else if (!hasUpi) {
                                  setState(() {
                                    validatorMsg = 'Referrer profile incomplete (missing UPI)';
                                    isValid = false;
                                  });
                                } else {
                                  setState(() {
                                    isValid = true;
                                    validatorMsg = 'Valid code from ${referrerName ?? "User"}';
                                    validationData = {
                                      'valid': true,
                                      'referrer_id': referrerId,
                                      'referrer_name': referrerName,
                                      'profile_complete': true,
                                    };
                                  });
                                }
                              } else {
                                setState(() {
                                  validatorMsg = 'No user found with this phone number';
                                  isValid = false;
                                });
                              }
                            } catch (e) {
                              debugPrint('❌ Validation error: $e');
                              setState(() {
                                validatorMsg = 'Error: ${e.toString().split(':').last.trim()}';
                                isValid = false;
                              });
                            } finally {
                              setState(() => isValidating = false);
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isValid && validationData != null ? () async {
                try {
                   debugPrint('🔍 Current user ID: $currentUserId');
                   
                   // Check if current user has a profile
                   final profileCheck = await SupabaseService.client
                       .from('user_profiles')
                       .select('user_id')
                       .eq('user_id', currentUserId)
                       .maybeSingle();
                   
                   debugPrint('📋 Profile check result: $profileCheck');
                   
                   if (profileCheck == null) {
                     if (dialogContext.mounted) {
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                         const SnackBar(content: Text('Error: Your profile is not set up yet. Please complete your profile first.')),
                       );
                     }
                     return;
                   }
                   
                   // Use RPC to create referral (bypasses RLS)
                   final result = await SupabaseService.client.rpc(
                     'create_referral_link',
                     params: {
                       'p_referrer_id': validationData!['referrer_id'],
                       'p_referred_user_id': currentUserId,
                       'p_referral_code': codeController.text.trim(),
                     },
                   );
                   
                   debugPrint('✅ Referral creation result: $result');
                      
                   if (dialogContext.mounted) {
                     Navigator.pop(dialogContext);
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Referral code applied successfully!')),
                     );
                     // Refresh profile to hide "Add Referral Code" option
                     _refreshProfile();
                   }
                } catch (e) {
                   debugPrint('❌ Error applying referral: $e');
                   if (dialogContext.mounted) {
                     ScaffoldMessenger.of(dialogContext).showSnackBar(
                       SnackBar(content: Text('Failed to apply: $e')),
                     );
                   }
                }
              } : null,
              child: const Text('Apply Code'),
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail(BuildContext context, String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Help & Support - EarnRupai',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Fallback
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Could not launch email client. Write to $email')),
           );
        }
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error launching email: $e')),
         );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, String? currentName) async {
    if (!context.mounted) return;

    // Fetch current phone number and locked status
    String? currentPhone;
    bool isPhoneLocked = false;
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.client
            .rpc('get_user_profile', params: {'p_user_id': user.id})
            .single();
        currentPhone = profile['phone_number'] as String?;
        isPhoneLocked = profile['phone_number_locked'] as bool? ?? false;
      }
    } catch (e) {
      debugPrint('Error fetching phone number: $e');
    }

    if (!context.mounted) return;

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: '10-digit number',
                enabled: !isPhoneLocked, // Disable if locked
                suffixIcon: isPhoneLocked 
                    ? const Icon(Icons.lock, color: Colors.orange)
                    : null,
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              readOnly: isPhoneLocked,
            ),
            if (isPhoneLocked) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phone number is locked. Contact support at ddvardhan2@gmail.com to change.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              
              // Validate phone number
              if (newPhone.isNotEmpty && newPhone.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number must be 10 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // If phone number is being set for the first time or changed
              if (newPhone.isNotEmpty && newPhone != currentPhone && !isPhoneLocked) {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Confirm Phone Number'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Important: Please verify your phone number carefully.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text('Phone Number: $newPhone'),
                        const SizedBox(height: 12),
                        const Text(
                          '⚠️ Once submitted, this phone number cannot be changed without contacting support.',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This phone number will be used as your referral code.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Let me check again'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Confirm & Lock'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed != true) {
                  return; // User cancelled
                }
                
                // Check if phone number is already taken
                try {
                  final response = await SupabaseService.client
                      .rpc('check_phone_number_available', params: {'phone': newPhone});
                  
                  if (response == false) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This phone number is already registered by another user'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                    return;
                  }
                } catch (e) {
                  debugPrint('Error checking phone availability: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error validating phone number: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
                
                // Use the special function to update and lock phone number
                try {
                  final user = SupabaseService.currentUser;
                  if (user != null) {
                    final result = await SupabaseService.client
                        .rpc('update_phone_number_with_lock', params: {
                      'user_uuid': user.id,
                      'new_phone': newPhone,
                    });
                    
                    if (result is List && result.isNotEmpty) {
                      final response = result.first as Map<String, dynamic>;
                      if (response['success'] != true) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['message'] ?? 'Failed to update phone number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('Error updating phone number: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }
              
              // Update name if changed
              if (newName.isNotEmpty && newName != currentName) {
                await SupabaseService.updateProfile(fullName: newName);
              }
               
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully! Phone number is now locked.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUpiDialog(BuildContext context) async {
    // Fetch current UPI ID
    String? currentUpiId;
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.client
            .rpc('get_user_profile', params: {'p_user_id': user.id})
            .single();
        currentUpiId = profile['upi_id'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching UPI ID: $e');
    }

    if (!context.mounted) return;

    final upiController = TextEditingController(text: currentUpiId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your UPI ID to receive payments.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID (e.g. user@upi)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUpiId = upiController.text.trim();
              if (newUpiId.isNotEmpty) {
                 await SupabaseService.updateProfile(upiId: newUpiId);
                 
                 if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('UPI details saved!')),
                   );
                 }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileOption({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
