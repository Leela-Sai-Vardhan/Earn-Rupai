import 'referral_model.dart';

class ReferralStats {
  final int pendingReferrals;
  final int completedReferrals;
  final int totalReferrals;
  final double totalEarnings;
  final List<Referral> recentReferrals;

  ReferralStats({
    required this.pendingReferrals,
    required this.completedReferrals,
    required this.totalReferrals,
    required this.totalEarnings,
    required this.recentReferrals,
  });

  factory ReferralStats.empty() {
    return ReferralStats(
      pendingReferrals: 0,
      completedReferrals: 0,
      totalReferrals: 0,
      totalEarnings: 0.0,
      recentReferrals: [],
    );
  }

  factory ReferralStats.fromReferrals(List<Referral> referrals, double earnings) {
    final pending = referrals.where((r) => r.isPending).length;
    final completed = referrals.where((r) => r.isCompleted || r.isRewarded).length;
    
    return ReferralStats(
      pendingReferrals: pending,
      completedReferrals: completed,
      totalReferrals: referrals.length,
      totalEarnings: earnings,
      recentReferrals: referrals.take(10).toList(),
    );
  }

  // Helper getters
  int get rewardedReferrals => recentReferrals.where((r) => r.isRewarded).length;
  bool get hasReferrals => totalReferrals > 0;
  bool get hasPendingReferrals => pendingReferrals > 0;
}
