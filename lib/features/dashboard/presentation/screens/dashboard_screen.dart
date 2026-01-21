import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tasks/presentation/screens/tasks_list_screen.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../widgets/notification_bell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on dashboard tab, go back to dashboard
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false; // Don't exit app
        }
        // If on dashboard, allow exit
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _DashboardHome(
              onNavigate: (index) {
                setState(() => _currentIndex = index);
              },
            ),
            const TasksListScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalEarningsAsync = ref.watch(totalEarningsProvider);
    final pendingEarningsAsync = ref.watch(pendingEarningsProvider);
    final tasksCompletedAsync = ref.watch(tasksCompletedProvider);

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
                            onNavigate(3);
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
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: AppTextStyles.bodyMedium(color: Colors.white70),
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
              const SizedBox(height: 24),
              // New Tasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Tasks',
                    style: AppTextStyles.h4(
                      color: isDark ? AppColors.lightText : AppColors.darkText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _NewTasksList(onNavigate: onNavigate),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTasksList extends ConsumerWidget {
  final Function(int) onNavigate;

  const _NewTasksList({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newTasksAsync = ref.watch(newTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return newTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 64,
                  color: AppColors.greyText.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No new tasks this week',
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
                  onTap: () {
                    // Navigate to task details using GoRouter push (maintains stack)
                    context.push('/tasks/${task.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Task icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.task_alt,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Task details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: AppTextStyles.bodyMedium(
                                  color: isDark ? AppColors.lightText : AppColors.darkText,
                                ).copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                TaskModel.getCategoryDisplayName(task.category),
                                style: AppTextStyles.caption(color: AppColors.greyText),
                              ),
                            ],
                          ),
                        ),
                        // Reward amount
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
