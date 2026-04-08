import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tasks/presentation/screens/tasks_list_screen.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../widgets/notification_bell.dart';
import '../../../../shared/services/in_app_update_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../referral/widgets/referral_banner.dart';
import '../../../referral/screens/refer_earn_screen.dart';
import '../../../../shared/services/admob_service.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../games/presentation/screens/games_hub_screen.dart';
import '../providers/dashboard_messages_provider.dart';
import '../widgets/marquee_banner.dart';
import '../../../../shared/services/notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check for in-app updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppUpdateService.checkForUpdate(context);

      // Check notification permission after a short delay
      // so it doesn't conflict with the update dialog
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          NotificationService().checkAndPromptPermission(context);
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        // If not on dashboard tab, go back to dashboard
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          // Allow exit if on dashboard (manually pop)
          // Since canPop is false, we need to manually trigger pop if we want to exit
          // or we can set canPop dynamically.
          // Better approach for tabs:
          // If we want to intercept back button:
          // If _currentIndex != 0, switch to 0.
          // If _currentIndex == 0, let it pop (exit app).
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _DashboardHome(
              onNavigate: (index) {
                if (_currentIndex != index) {
                  setState(() => _currentIndex = index);
                  if (index == 1 || index == 2 || index == 3) {
                    AdMobService.loadRewardedAd();
                  }
                }
              },
            ),
            const TasksListScreen(),
            const GamesHubScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
              // Preload ad only when navigating to tabs that frequently show ads
              if (index == 1 || index == 2 || index == 3) {
                AdMobService.loadRewardedAd();
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.greyText,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              activeIcon: Icon(Icons.task),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends ConsumerWidget {
  final Function(int) onNavigate;

  const _DashboardHome({required this.onNavigate});

  static Future<Map<String, dynamic>?> _checkProfileCompletion() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return null;
      
      final profile = await SupabaseService.client
          .rpc('get_user_profile', params: {'p_user_id': user.id})
          .single();
      
      return profile;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalEarningsAsync = ref.watch(totalEarningsProvider);
    final pendingEarningsAsync = ref.watch(pendingEarningsProvider);
    final tasksCompletedAsync = ref.watch(tasksCompletedProvider);
    final dashboardMessagesAsync = ref.watch(dashboardMessagesProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalEarningsProvider);
          ref.invalidate(pendingEarningsProvider);
          ref.invalidate(tasksCompletedProvider);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: AppTextStyles.h3(
                          color: isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to earn today?',
                        style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification bell
                      const NotificationBell(),
                      const SizedBox(width: 12),
                      // Profile avatar
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primaryGreen,
                        child: InkWell(
                          onTap: () {
                            onNavigate(4); // Navigates to Profile (Index 4)
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Earnings Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Earnings',
                          style: AppTextStyles.bodyMedium(color: Colors.white70),
                        ),
                        // Spin & Win Card
                        GestureDetector(
                          onTap: () => onNavigate(2), // Navigate to Spin & Win tab
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withValues(alpha: 0.3),
                                  Colors.orange.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/spin&earn.png',
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Spin & Win',
                                      style: AppTextStyles.bodyLarge(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Try your luck!',
                                      style: AppTextStyles.caption(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    totalEarningsAsync.when(
                      data: (total) => Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.white, size: 32),
                          Text(
                            total.toStringAsFixed(2),
                            style: AppTextStyles.h1(color: Colors.white),
                          ),
                        ],
                      ),
                      loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 24)),
                      error: (_, __) => const Text('0.00', style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tasks Completed',
                                style: AppTextStyles.caption(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              tasksCompletedAsync.when(
                                data: (count) => Text(
                                  count.toString(),
                                  style: AppTextStyles.h4(color: Colors.white),
                                ),
                                loading: () => const Text('...', style: TextStyle(color: Colors.white)),
                                error: (_, __) => const Text('0', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending',
                                style: AppTextStyles.caption(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              pendingEarningsAsync.when(
                                data: (pending) => Row(
                                  children: [
                                    const Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                                    Text(
                                      pending.toStringAsFixed(2),
                                      style: AppTextStyles.h4(color: Colors.white),
                                    ),
                                  ],
                                ),
                                loading: () => const Text('...', style: TextStyle(color: Colors.white)),
                                error: (_, __) => const Text('0.00', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Marquee Message Banner
              dashboardMessagesAsync.when(
                data: (messages) => messages.isEmpty
                    ? const SizedBox.shrink()
                    : MarqueeBanner(messages: messages),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Referral Banner
              ReferralBanner(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReferEarnScreen(),
                    ),
                  );
                },
              ),
              
              // Profile Completion Reminder
              FutureBuilder<Map<String, dynamic>?>(
                future: _checkProfileCompletion(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    final phoneNumber = data['phone_number'] as String?;
                    final upiId = data['upi_id'] as String?;
                    
                    final isPhoneMissing = phoneNumber == null || phoneNumber.isEmpty;
                    final isUpiMissing = upiId == null || upiId.isEmpty;
                    
                    if (isPhoneMissing || isUpiMissing) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.warning.withValues(alpha: 0.2),
                                  AppColors.warning.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warning,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Complete Your Profile',
                                            style: AppTextStyles.h4(
                                              color: isDark ? AppColors.lightText : AppColors.darkText,
                                            ).copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isPhoneMissing && isUpiMissing
                                                ? 'Add your phone number and UPI ID to start earning rewards'
                                                : isPhoneMissing
                                                    ? 'Add your phone number to complete your profile'
                                                    : 'Add your UPI ID to receive payments',
                                            style: AppTextStyles.bodySmall(
                                              color: isDark ? AppColors.lightText.withValues(alpha: 0.7) : AppColors.darkText.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => onNavigate(4), // Navigate to profile
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Update Profile'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warning,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Trending Tasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Trending Tasks',
                        style: AppTextStyles.h4(
                          color: isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TrendingTasksList(onNavigate: onNavigate),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingTasksList extends ConsumerWidget {
  final Function(int) onNavigate;

  const _TrendingTasksList({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newTasksAsync = ref.watch(trendingTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return newTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 64,
                  color: AppColors.greyText.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No trending tasks right now',
                  style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 400, // Fixed height for vertical scroll
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    // Preload ad while user reads the dialog
                    AdMobService.loadRewardedAd();
                    
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('View Task Details?'),
                        content: const Text('Watch a quick ad to view task details.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    // Show blocking overlay
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.white,
                      builder: (context) => const SizedBox.expand(),
                    );

                    // Show rewarded ad
                    AdMobService.showRewardedAd(
                      onUserEarnedReward: () {
                        Navigator.pop(context); // Close blocking overlay
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(taskId: task.id),
                          ),
                        );
                      },
                      onAdFailedToLoad: () {
                        Navigator.pop(context); // Close blocking overlay
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ad not available. Proceeding to task details...'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(taskId: task.id),
                          ),
                        );
                      },
                      onAdDismissed: (bool earnedReward) {
                        if (!earnedReward) {
                          Navigator.pop(context); // Close blocking overlay
                        }
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Task icon with fire for trending
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Task details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: AppTextStyles.bodyMedium(
                                          color: isDark ? AppColors.lightText : AppColors.darkText,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      TaskModel.getCategoryDisplayName(task.category),
                                      style: AppTextStyles.caption(color: AppColors.greyText),
                                    ),
                                    if (task.amountEarned > 0) ...[
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${task.amountEarned.toStringAsFixed(0)} earned',
                                        style: AppTextStyles.caption(color: AppColors.primaryGreen)
                                            .copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reward amount
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                                Text(
                                  task.rewardAmount.toStringAsFixed(0),
                                  style: AppTextStyles.bodyMedium(
                                    color: AppColors.primaryGreen,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Failed to load new tasks',
          style: AppTextStyles.bodyMedium(color: AppColors.greyText),
        ),
      ),
    );
  }
}


