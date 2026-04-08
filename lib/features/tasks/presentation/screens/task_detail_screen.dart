import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/services/admob_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/tasks_provider.dart';
import '../../data/models/task_model.dart';
import '../../../../shared/services/task_service.dart';
import '../../../../shared/services/review_service.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isStarting = false;

  Future<void> _startTask(TaskModel task) async {
    setState(() => _isStarting = true);

    try {
      // Create user_task record
      await TaskService.startTask(widget.taskId);

      // Launch external URL
      final uri = Uri.parse(task.externalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Task started! Complete it and come back to mark as done.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Refresh all relevant providers for immediate UI update
        ref.invalidate(taskStatusProvider(widget.taskId));
        ref.invalidate(tasksProvider);
        ref.invalidate(pendingEarningsProvider);
        ref.invalidate(transactionsProvider);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  // Visit Again - only opens URL without creating database record
  Future<void> _visitAgain(TaskModel task) async {
    try {
      // Launch external URL
      final uri = Uri.parse(task.externalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Task link reopened! Complete it and come back to mark as done.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );

        // Trigger in-app review every time user visits again
        ReviewService.requestReviewAfterTaskAction();
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showCompletionDisclaimer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Important Warning!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before marking this task as completed:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ ONLY mark as completed if you have:\n\n'
                '✓ Fully completed the task as per instructions\n'
                '✓ Received confirmation/payment from the external platform (if applicable)\n'
                '✓ Followed all task requirements correctly\n\n'
                '❌ DO NOT mark as completed if:\n\n'
                '• You haven\'t finished the task\n'
                '• You haven\'t received payment from external source\n'
                '• You\'re unsure about task completion\n\n',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '⚠️ WARNING: Marking tasks as completed without proper verification may result in:\n\n'
                  '• Loss of potential earnings\n'
                  '• Account suspension\n'
                  '• Inability to claim rewards\n\n'
                  'We cannot help if money wasn\'t credited due to improper task completion.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('I Understand, Mark Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Trigger in-app review when user marks as completed
      ReviewService.requestReviewAfterTaskAction();

      // Show interstitial ad before completing the task
      // Note: No blocking overlay — that violates AdMob's Navigation policy
      AdMobService.showInterstitialAd(
        onAdDismissed: () {
          _completeTask();
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Load ad when screen opens so it's ready
    AdMobService.loadInterstitialAd();
  }

  Future<void> _completeTask() async {
    try {
      await TaskService.completeTask(widget.taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Task submitted for review! Reward will be credited soon.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Refresh all relevant providers for immediate UI update
      ref.invalidate(taskStatusProvider(widget.taskId));
      ref.invalidate(tasksProvider);
      ref.invalidate(totalEarningsProvider);
      ref.invalidate(pendingEarningsProvider);
      ref.invalidate(tasksCompletedProvider);
      ref.invalidate(availableBalanceProvider);
      ref.invalidate(transactionsProvider);

      // Go back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final taskStatusAsync = ref.watch(taskStatusProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header with reward
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.greenGradient,
                  ),
                  child: Row(
                    children: [
                      // Category badge (left side)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          TaskModel.getCategoryDisplayName(task.category),
                          style: AppTextStyles.bodySmall(color: Colors.white)
                              .copyWith(fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      // Reward amount (right side)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.currency_rupee,
                                color: Colors.white, size: 18),
                            Text(
                              task.rewardAmount.toStringAsFixed(2),
                              style: AppTextStyles.h3(color: Colors.white)
                                  .copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Task details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: AppTextStyles.h3(
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: AppTextStyles.h4(
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style:
                            AppTextStyles.bodyMedium(color: AppColors.greyText),
                      ),
                      const SizedBox(height: 24),

                      // Instructions
                      Text(
                        'Instructions',
                        style: AppTextStyles.h4(
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          task.instructions,
                          style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.lightText
                                : AppColors.darkText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tutorial Video (if available)
                      if (task.videoUrl != null &&
                          task.videoUrl!.isNotEmpty) ...[
                        _buildVideoSection(task.videoUrl!, isDark),
                        const SizedBox(height: 24),
                      ],

                      // Tutorial Images (if available)
                      if (task.imageUrls != null &&
                          task.imageUrls!.isNotEmpty) ...[
                        _buildImageSection(task.imageUrls!, isDark),
                        const SizedBox(height: 24),
                      ],

                      // Important Note (if available)
                      if (task.importantNote != null &&
                          task.importantNote!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.warning,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Important Note',
                                    style: AppTextStyles.h4(
                                      color: AppColors.warning,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                task.importantNote!,
                                style: AppTextStyles.bodyMedium(
                                  color: isDark
                                      ? AppColors.lightText
                                      : AppColors.darkText,
                                ).copyWith(
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Company Info (if available)
                      if (task.companyInfo != null &&
                          task.companyInfo!.isNotEmpty) ...[
                        Text(
                          'About Company',
                          style: AppTextStyles.h4(
                            color: isDark
                                ? AppColors.lightText
                                : AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.business,
                                color: AppColors.primaryPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.companyInfo!,
                                  style: AppTextStyles.bodyMedium(
                                    color: isDark
                                        ? AppColors.lightText
                                        : AppColors.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const SizedBox(height: 8),

                      // Action buttons based on status
                      taskStatusAsync.when(
                        data: (status) {
                          if (status == null) {
                            // Not started - show start button
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isStarting ? null : () => _startTask(task),
                                icon: _isStarting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.play_arrow),
                                label: Text(
                                    _isStarting ? 'Starting...' : 'Start Task'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            );
                          } else if (status == 'in_progress') {
                            // In progress - show Visit Again and Mark as Completed buttons
                            return Column(
                              children: [
                                // Visit Again Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _visitAgain(task),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Visit Again'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: BorderSide(
                                          color: AppColors.primaryGreen,
                                          width: 2),
                                      foregroundColor: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Mark as Completed Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showCompletionDisclaimer,
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Mark as Completed'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (status == 'pending_review') {
                            // Pending review
                            return Column(
                              children: [
                                // Visit Again Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _visitAgain(task),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Visit Again'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: const BorderSide(
                                          color: AppColors.primaryGreen,
                                          width: 2),
                                      foregroundColor: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_empty,
                                          color: AppColors.warning),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Task under review. Reward will be credited soon!',
                                          style: AppTextStyles.bodyMedium(
                                              color: AppColors.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Completed/rewarded
                            return Column(
                              children: [
                                // Visit Again Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _visitAgain(task),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Visit Again'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: const BorderSide(
                                          color: AppColors.primaryGreen,
                                          width: 2),
                                      foregroundColor: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: AppColors.success),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Task completed! Reward credited.',
                                          style: AppTextStyles.bodyMedium(
                                              color: AppColors.success),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  String _extractVideoId(String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.contains('youtube.com') || cleanUrl.contains('youtu.be')) {
      // Handle YouTube Shorts specifically
      if (cleanUrl.contains('/shorts/')) {
        return cleanUrl.split('/shorts/').last.split('?').first;
      }
      return YoutubePlayer.convertUrlToId(cleanUrl) ?? '';
    }
    return cleanUrl;
  }

  Widget _buildVideoSection(String videoUrl, bool isDark) {
    final videoId = _extractVideoId(videoUrl);
    if (videoId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle_outline,
                color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'Tutorial Video',
              style: AppTextStyles.h4(
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
              child: YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  enableCaption: true,
                  hideControls: false,
                ),
              ),
              showVideoProgressIndicator: true,
              bottomActions: [
                const SizedBox(width: 14.0),
                CurrentPosition(),
                const SizedBox(width: 8.0),
                ProgressBar(isExpanded: true),
                const PlaybackSpeedButton(),
                FullScreenButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(List<String> imageUrls, bool isDark) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'Tutorial Images',
              style: AppTextStyles.h4(
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CarouselSlider.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrls[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.greyText.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.greyText.withValues(alpha: 0.1),
                      child: const Icon(Icons.broken_image,
                          color: AppColors.greyText),
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            height: 200,
            autoPlay: imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
          ),
        ),
      ],
    );
  }
}
