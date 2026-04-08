import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const NotificationPermissionDialog({
    super.key,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, VoidCallback onDismiss) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => NotificationPermissionDialog(onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Warning icon with glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: Color(0xFFFF6B35),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Don\'t Miss Your Cashback! 💸',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          const Text(
            'Notifications are currently OFF. You\'ll miss:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),

          // Feature list
          _buildFeatureRow(Icons.casino_rounded, 'Daily spin reminders at 7 AM & 9 PM'),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.task_alt_rounded, 'New cashback task alerts'),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.account_balance_wallet_rounded, 'Task reward & payout updates'),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.campaign_rounded, 'Exclusive limited-time offers'),

          const SizedBox(height: 28),

          // Enable button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enable Notifications Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Remind later button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Remind Me Later',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
