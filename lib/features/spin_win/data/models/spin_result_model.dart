class SpinResultModel {
  final double coinsWon;
  final bool isFirstDay;
  final int spinNumber;

  SpinResultModel({
    required this.coinsWon,
    required this.isFirstDay,
    required this.spinNumber,
  });

  factory SpinResultModel.fromJson(Map<String, dynamic> json) {
    return SpinResultModel(
      coinsWon: (json['coins_won'] as num).toDouble(),
      isFirstDay: json['is_first_day'] as bool,
      spinNumber: json['spin_number'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins_won': coinsWon,
      'is_first_day': isFirstDay,
      'spin_number': spinNumber,
    };
  }
}

class CoinBalanceModel {
  final double coinsBalance;
  final double totalCoinsEarned;
  final int spinsRemaining;
  final DateTime? lastSpinAt;
  final DateTime? dailySpinsResetAt;
  final bool isFirstDaySpin;
  final int firstDaySpinCount;

  CoinBalanceModel({
    required this.coinsBalance,
    required this.totalCoinsEarned,
    required this.spinsRemaining,
    this.lastSpinAt,
    this.dailySpinsResetAt,
    required this.isFirstDaySpin,
    required this.firstDaySpinCount,
  });

  factory CoinBalanceModel.fromJson(Map<String, dynamic> json) {
    return CoinBalanceModel(
      coinsBalance: (json['coins_balance'] as num?)?.toDouble() ?? 0.0,
      totalCoinsEarned: (json['total_coins_earned'] as num?)?.toDouble() ?? 0.0,
      spinsRemaining: (json['spins_remaining'] as int?) ?? 5,
      lastSpinAt: json['last_spin_at'] != null 
          ? DateTime.parse(json['last_spin_at'] as String)
          : null,
      dailySpinsResetAt: json['daily_spins_reset_at'] != null
          ? DateTime.parse(json['daily_spins_reset_at'] as String)
          : null,
      isFirstDaySpin: (json['is_first_day_spin'] as bool?) ?? true,
      firstDaySpinCount: (json['first_day_spin_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins_balance': coinsBalance,
      'total_coins_earned': totalCoinsEarned,
      'spins_remaining': spinsRemaining,
      'last_spin_at': lastSpinAt?.toIso8601String(),
      'daily_spins_reset_at': dailySpinsResetAt?.toIso8601String(),
      'is_first_day_spin': isFirstDaySpin,
      'first_day_spin_count': firstDaySpinCount,
    };
  }
}
