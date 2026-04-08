import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_model.dart';
import '../models/referral_stats_model.dart';
import '../services/referral_service.dart';

final referralServiceProvider = Provider((ref) => ReferralService());

/// Provider for user's referral code
final userReferralCodeProvider = FutureProvider.family<String?, String>((ref, userId) async {
  final service = ref.watch(referralServiceProvider);
  return await service.getUserReferralCode(userId);
});

/// Provider for user's referrals list
final userReferralsProvider = FutureProvider.family<List<Referral>, String>((ref, userId) async {
  final service = ref.watch(referralServiceProvider);
  return await service.getUserReferrals(userId);
});

/// Provider for user's referral stats
final referralStatsProvider = FutureProvider.family<ReferralStats, String>((ref, userId) async {
  final service = ref.watch(referralServiceProvider);
  return await service.getReferralStats(userId);
});

/// Provider for pending referrals count
final pendingReferralsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(referralServiceProvider);
  return await service.getPendingReferralsCount(userId);
});

/// Provider for referral code validation
final referralCodeValidationProvider = StateProvider<AsyncValue<Map<String, dynamic>?>>((ref) {
  return const AsyncValue.data(null);
});

/// Function to validate referral code
Future<void> validateReferralCode(WidgetRef ref, String code) async {
  ref.read(referralCodeValidationProvider.notifier).state = const AsyncValue.loading();
  try {
    final service = ref.read(referralServiceProvider);
    final result = await service.validateReferralCode(code);
    ref.read(referralCodeValidationProvider.notifier).state = AsyncValue.data(result);
  } catch (e, stack) {
    ref.read(referralCodeValidationProvider.notifier).state = AsyncValue.error(e, stack);
  }
}

/// Function to reset validation
void resetReferralValidation(WidgetRef ref) {
  ref.read(referralCodeValidationProvider.notifier).state = const AsyncValue.data(null);
}
