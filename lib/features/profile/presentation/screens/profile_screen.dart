import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = SupabaseService.currentUser;
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
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

  void _showEditProfileDialog(BuildContext context, String? currentName) {
    if (!context.mounted) return;

    final nameController = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              
              if (newName.isNotEmpty) {
                 await SupabaseService.updateProfile(fullName: newName);
                 
                 if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Profile updated successfully!')),
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

  void _showUpiDialog(BuildContext context) async {
    // Fetch current UPI ID
    String? currentUpiId;
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.userProfiles
            .select('upi_id')
            .eq('user_id', user.id)
            .single();
        currentUpiId = profile['upi_id'] as String?;
      }
    } catch (e) {
      print('Error fetching UPI ID: $e');
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
