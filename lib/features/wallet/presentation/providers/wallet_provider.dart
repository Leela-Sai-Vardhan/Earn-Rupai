import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_transaction.dart';
import '../../../../shared/services/wallet_service.dart';

// Total earnings provider
final totalEarningsProvider = FutureProvider<double>((ref) async {
  return await WalletService.getTotalEarnings();
});

// Tasks completed provider
final tasksCompletedProvider = FutureProvider<int>((ref) async {
  return await WalletService.getTasksCompletedCount();
});

// Pending earnings provider
final pendingEarningsProvider = FutureProvider<double>((ref) async {
  return await WalletService.getPendingEarnings();
});

// Available balance provider
final availableBalanceProvider = FutureProvider<double>((ref) async {
  return await WalletService.getAvailableBalance();
});

// Transactions provider
final transactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  return await WalletService.getTransactions();
});
