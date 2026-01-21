import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../../../shared/services/task_service.dart';

// Selected category provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Tasks list provider
final tasksProvider = FutureProvider.family<List<TaskModel>, String>((ref, category) async {
  return await TaskService.fetchTasks(category: category);
});

// Single task provider
final taskDetailProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  return await TaskService.fetchTaskById(taskId);
});

// Task status provider
final taskStatusProvider = FutureProvider.family<String?, String>((ref, taskId) async {
  return await TaskService.getTaskStatus(taskId);
});

// Provider for all user task statuses (for list view)
final userTaskStatusesProvider = FutureProvider<Map<String, String>>((ref) async {
  return await TaskService.fetchUserTaskStatuses();
});

// Provider for new tasks (last week, limited to 5)
final newTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final allTasks = await TaskService.fetchTasks();
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  
  // Filter tasks from last week and limit to 5
  return allTasks
      .where((task) => task.createdAt.isAfter(oneWeekAgo))
      .take(5)
      .toList();
});
