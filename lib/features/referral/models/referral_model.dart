class Referral {
  final String id;
  final String referrerId;
  final String referredUserId;
  final String referredUserName;
  final String referralCode;
  final String status; // pending, completed, rewarded
  final int tasksCompleted;
  final int tasksRewarded;
  final double rewardAmount;
  final bool rewardPaid;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? rewardedAt;

  Referral({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.referredUserName,
    required this.referralCode,
    required this.status,
    required this.tasksCompleted,
    required this.tasksRewarded,
    required this.rewardAmount,
    required this.rewardPaid,
    required this.createdAt,
    this.completedAt,
    this.rewardedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referredUserId: json['referred_user_id'] as String,
      referredUserName: json['referred_user_name'] as String? ?? 'Unknown',
      referralCode: json['referral_code'] as String,
      status: json['status'] as String,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      tasksRewarded: json['tasks_rewarded'] as int? ?? 0,
      rewardAmount: (json['reward_amount'] as num?)?.toDouble() ?? 50.0,
      rewardPaid: json['reward_paid'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      rewardedAt: json['rewarded_at'] != null
          ? DateTime.parse(json['rewarded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referred_user_id': referredUserId,
      'referred_user_name': referredUserName,
      'referral_code': referralCode,
      'status': status,
      'tasks_completed': tasksCompleted,
      'tasks_rewarded': tasksRewarded,
      'reward_amount': rewardAmount,
      'reward_paid': rewardPaid,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'rewarded_at': rewardedAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isRewarded => status == 'rewarded';
  
  int get tasksRemaining => 3 - tasksRewarded;
  double get progressPercentage => (tasksRewarded / 3 * 100).clamp(0, 100);
}
