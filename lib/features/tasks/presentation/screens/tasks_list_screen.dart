import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/tasks_provider.dart';
import '../../data/models/task_model.dart';
import '../widgets/task_card.dart';
import '../../../../shared/services/task_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        ref.read(selectedCategoryProvider.notifier).state = category;
                      }
                    },
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
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
                          color: AppColors.greyText.withOpacity(0.5),
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
                            onTap: () {
                              // Navigate to task detail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(taskId: task.id),
                                ),
                              ).then((_) {
                                // Refresh status on return
                                ref.invalidate(userTaskStatusesProvider);
                              });
                            },
                          ),
                          loading: () => TaskCard(
                            task: task,
                            onTap: () {}, // Disable while loading statuses
                          ),
                          error: (_, __) => TaskCard(
                            task: task,
                            onTap: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(taskId: task.id),
                                ),
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
                      color: AppColors.error.withOpacity(0.5),
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
