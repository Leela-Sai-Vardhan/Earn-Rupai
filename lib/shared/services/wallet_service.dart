import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/wallet/data/models/wallet_transaction.dart';

class WalletService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's total earnings from profile
  static Future<double> getTotalEarnings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await _supabase
          .from('user_profiles')
          .select('total_earnings')
          .eq('user_id', userId)
          .single();

      return (response['total_earnings'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error fetching total earnings: $e');
      return 0.0;
    }
  }

  // Get user's task completion count from profile
  static Future<int> getTasksCompletedCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('user_profiles')
          .select('tasks_completed')
          .eq('user_id', userId)
          .single();

      return (response['tasks_completed'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error fetching tasks completed count: $e');
      return 0;
    }
  }

  // Get pending earnings (transactions with status 'pending')
  static Future<double> getPendingEarnings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await _supabase
          .from('wallet_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .eq('transaction_type', 'credit');

      if ((response as List).isEmpty) return 0.0;

      double total = 0.0;
      for (var transaction in response) {
        total += (transaction['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      debugPrint('Error fetching pending earnings: $e');
      return 0.0;
    }
  }

  // Get available balance (completed transactions)
  static Future<double> getAvailableBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await _supabase
          .from('wallet_transactions')
          .select('amount, transaction_type')
          .eq('user_id', userId)
          .eq('status', 'completed');

      if ((response as List).isEmpty) return 0.0;

      double balance = 0.0;
      for (var transaction in response) {
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['transaction_type'] as String;
        
        if (type == 'credit') {
          balance += amount;
        } else if (type == 'debit' || type == 'withdrawal') {
          balance -= amount;
        }
      }
      return balance;
    } catch (e) {
      debugPrint('Error fetching available balance: $e');
      return 0.0;
    }
  }

  // Get transaction history
  static Future<List<WalletTransaction>> getTransactions({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  // Add sample transaction for testing
  static Future<void> addSampleTransaction() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': 5.00,
        'transaction_type': 'credit',
        'status': 'completed',
        'notes': 'Sample task completion reward',
      });
    } catch (e) {
      debugPrint('Error adding sample transaction: $e');
      rethrow;
    }
  }
}
