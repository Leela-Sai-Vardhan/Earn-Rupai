import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/tasks/data/models/task_model.dart';

class TaskService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all active tasks
  static Future<List<TaskModel>> fetchTasks({String? category}) async {
    try {
      dynamic query = _supabase
          .from('tasks')
          .select()
          .eq('is_active', true);

      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }

  // Fetch single task by ID
  static Future<TaskModel?> fetchTaskById(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching task: $e');
      return null;
    }
  }

  // Start a task (create user_task record)
  static Future<void> startTask(String taskId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get task details for reward amount
      final taskResponse = await _supabase
          .from('tasks')
          .select('reward_amount, title')
          .eq('id', taskId)
          .single();

      final rewardAmount = taskResponse['reward_amount'];
      final taskTitle = taskResponse['title'];

      // Get user name from user_profiles
      final userProfileResponse = await _supabase
          .from('user_profiles')
          .select('full_name')
          .eq('user_id', userId)
          .single();
      
      final userName = userProfileResponse['full_name'] ?? 'Unknown User';

      // Create user_task record
      await _supabase.from('user_tasks').insert({
        'user_id': userId,
        'task_id': taskId,
        'task_title': taskTitle, // Add task title for easier identification
        'user_name': userName, // Add user name for easier identification
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      });

      // Create pending wallet transaction
      await _supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'task_id': taskId,
        'amount': rewardAmount,
        'transaction_type': 'credit',
        'status': 'pending',
        'notes': 'Pending reward for: $taskTitle',
      });
    } catch (e) {
      debugPrint('Error starting task: $e');
      rethrow;
    }
  }

  // Complete a task
  static Future<void> completeTask(String taskId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Update user_task status to pending_review
      await _supabase
          .from('user_tasks')
          .update({
            'status': 'pending_review',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('task_id', taskId);

      // Transaction is already created in startTask, no need to create again
    } catch (e) {
      debugPrint('Error completing task: $e');
      rethrow;
    }
  }

  // Check if user has already started/completed a task
  static Future<String?> getTaskStatus(String taskId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_tasks')
          .select('status')
          .eq('user_id', userId)
          .eq('task_id', taskId)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      debugPrint('Error checking task status: $e');
      return null;
    }
  }

  // Fetch all user tasks map (taskId -> status)
  static Future<Map<String, String>> fetchUserTaskStatuses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('user_tasks')
          .select('task_id, status')
          .eq('user_id', userId);

      return {
        for (var item in response) item['task_id'] as String: item['status'] as String
      };
    } catch (e) {
      debugPrint('Error fetching user task statuses: $e');
      return {};
    }
  }

  // Get all categories
  static List<String> getCategories() {
    return [
      'all',
      'survey',
      'video',
      'app_install',
      'social_media',
      'quiz',
      'other',
    ];
  }
}
