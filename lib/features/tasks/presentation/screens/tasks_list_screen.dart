import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/tasks_provider.dart';
import '../../data/models/task_model.dart';
import '../widgets/task_card.dart';
import '../../../../shared/services/task_service.dart';
import '../../../../shared/services/admob_service.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import 'task_detail_screen.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  @override
  Widget build(BuildContext context) {

    final selectedCategory = ref.watch(selectedCategoryProvider);
    final tasksAsync = ref.watch(tasksProvider(selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tasksProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filters
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: TaskService.getCategories().length,
              itemBuilder: (context, index) {
                final category = TaskService.getCategories()[index];
                final isSelected = selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category == 'all' ? 'All' : TaskModel.getCategoryDisplayName(category),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedCategoryProvider.notifier).setCategory(category);
                      }
                    },
                    selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: AppTextStyles.bodySmall(
                      color: isSelected ? AppColors.primaryGreen : AppColors.greyText,
                    ),
                  ),
                );
              },
            ),
          ),
          // Tasks list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: AppColors.greyText.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks available',
                          style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                        ),
                      ],
                    ),
                  );
                }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(tasksProvider);
                      ref.invalidate(userTaskStatusesProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final statusAsync = ref.watch(userTaskStatusesProvider);
                        
                        return statusAsync.when(
                          data: (statuses) => TaskCard(
                            task: task,
                            status: statuses[task.id],
                            onTap: () async {
                              // Preload ad while user reads the dialog
                              AdMobService.loadRewardedAd();
                              
                              // Step 1: Show confirmation dialog
                              final shouldProceed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Watch Ad to Continue'),
                                  content: const Text('Please watch a short ad to view task details'),
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

                              if (shouldProceed != true) return;

                              // Step 2: Show blocking overlay
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                barrierColor: Colors.white,
                                builder: (context) => const SizedBox.expand(),
                              );

                              // Step 3: Show rewarded ad
                              AdMobService.showRewardedAd(
                                onUserEarnedReward: () {
                                  // User watched the ad completely
                                  Navigator.pop(context); // Close blocking overlay
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailScreen(taskId: task.id),
                                    ),
                                  ).then((_) {
                                    ref.invalidate(userTaskStatusesProvider);
                                  });
                                },
                                onAdFailedToLoad: () {
                                  // Ad not available - let user proceed anyway
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
                                  ).then((_) {
                                    ref.invalidate(userTaskStatusesProvider);
                                  });
                                },
                                onAdDismissed: (bool earnedReward) {
                                  if (!earnedReward) {
                                    // User skipped ad
                                    Navigator.pop(context); // Close blocking overlay
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please watch the complete ad to view task details'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          loading: () => TaskCard(
                            task: task,
                            onTap: () {}, // Disable while loading statuses
                          ),
                          error: (_, __) => TaskCard(
                            task: task,
                            onTap: () async {
                              // Preload ad while user reads the dialog
                              AdMobService.loadRewardedAd();
                              
                              // Step 1: Show confirmation dialog
                              final shouldProceed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Watch Ad to Continue'),
                                  content: const Text('Please watch a short ad to view task details'),
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

                              if (shouldProceed != true) return;

                              // Step 2: Show blocking overlay
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                barrierColor: Colors.white,
                                builder: (context) => const SizedBox.expand(),
                              );

                              // Step 3: Show rewarded ad
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please watch the complete ad to view task details'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: AppTextStyles.bodyMedium(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(tasksProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Banner Ad at bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
