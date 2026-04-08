import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  final String? status;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = Color(TaskModel.getCategoryColor(task.category));

    // Determine button style based on status
    String buttonText = 'View Details';
    Color buttonColor = AppColors.primaryGreen;
    Color textColor = Colors.white;

    if (status == 'in_progress') {
      buttonText = 'Mark as Completed';
      buttonColor = AppColors.primaryOrange;
    } else if (status == 'pending_review') {
      buttonText = 'Under Review';
      buttonColor = AppColors.warning;
    } else if (status == 'completed' || status == 'rewarded') {
      buttonText = 'Completed';
      buttonColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: category badge + reward amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          TaskModel.getCategoryDisplayName(task.category),
                          style: AppTextStyles.caption(color: categoryColor),
                        ),
                      ),
                      // Trending badge
                      if (task.isTrending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                'Trending',
                                style: AppTextStyles.caption(color: Colors.orange[700]!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                        Text(
                          task.rewardAmount.toStringAsFixed(2),
                          style: AppTextStyles.bodySmall(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: AppTextStyles.h4(
                  color: isDark ? AppColors.lightText : AppColors.darkText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Dynamic Button with earnings
              Row(
                children: [
                  // Total earnings (always show if > 0)
                  if (task.amountEarned > 0) ...[
                    Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primaryGreen.withValues(alpha: 0.8)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '₹${task.amountEarned.toStringAsFixed(0)} earned by all users.',
                        style: AppTextStyles.caption(
                          color: AppColors.primaryGreen,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Spacer(),
                  ],
                  // Button
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      backgroundColor: buttonColor,
                      foregroundColor: textColor,
                    ),
                    child: Text(buttonText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
