import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coin_transaction_model.dart';
import '../models/spin_result_model.dart';

class CoinService {
  static final _supabase = Supabase.instance.client;

  // Coin values and probabilities
  static const List<double> coinValues = [0.2, 0.5, 2, 3, 10, 25, 100];
  static const List<double> probabilities = [51, 48.5, 0.3, 0.1, 0.05, 0.05, 0];

  // First day guaranteed spins: 4×0.5 + 1×0.2
  static const List<double> firstDaySpins = [0.5, 0.5, 0.5, 0.5, 0.2];

  // Milestone spin rewards (spin number → coins), spin number is 1-indexed
  static const Map<int, double> milestoneSpins = {
    5: 3.0,   // 5th spin  → ₹3
    7: 10.0,  // 7th spin  → ₹10
    15: 3.0,  // 15th spin → ₹3
  };

  /// Get coin balance and spin info for current user
  static Future<CoinBalanceModel> getCoinBalance() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.rpc('get_coin_balance', params: {
      'p_user_id': userId,
    });

    return CoinBalanceModel.fromJson(response as Map<String, dynamic>);
  }

  /// Check if user can perform a spin
  static Future<Map<String, dynamic>> canPerformSpin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.rpc('perform_spin', params: {
      'p_user_id': userId,
    });

    return response as Map<String, dynamic>;
  }

  /// Perform a spin and get the result (client-side calculation)
  static SpinResultModel performSpin(bool isFirstDay, int spinCount) {
    double coinsWon;
    final spinNumber = spinCount + 1; // 1-indexed

    if (milestoneSpins.containsKey(spinNumber)) {
      // Milestone spin: guaranteed reward regardless of day
      coinsWon = milestoneSpins[spinNumber]!;
    } else if (isFirstDay && spinCount < 5) {
      // First day: use guaranteed values
      coinsWon = firstDaySpins[spinCount];
    } else {
      // Regular spin: use probability-based selection
      coinsWon = _getRandomCoinValue();
    }

    return SpinResultModel(
      coinsWon: coinsWon,
      isFirstDay: isFirstDay,
      spinNumber: spinNumber,
    );
  }

  /// Get random coin value based on probabilities
  static double _getRandomCoinValue() {
    final random = Random();
    final randomValue = random.nextDouble() * 100;

    double cumulativeProbability = 0;
    for (int i = 0; i < probabilities.length; i++) {
      cumulativeProbability += probabilities[i];
      if (randomValue <= cumulativeProbability) {
        return coinValues[i];
      }
    }

    return 0.2; // Fallback
  }

  /// Claim spin coins after watching ad
  static Future<Map<String, dynamic>> claimSpinCoins(
    double coinsWon, {
    bool adWatched = true,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.rpc('claim_spin_coins', params: {
      'p_user_id': userId,
      'p_coins_won': coinsWon,
      'p_ad_watched': adWatched,
    });

    return response as Map<String, dynamic>;
  }

  /// Request coin withdrawal
  static Future<Map<String, dynamic>> requestWithdrawal(double amount) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.rpc('request_coin_withdrawal', params: {
      'p_user_id': userId,
      'p_amount': amount,
    });

    return response as Map<String, dynamic>;
  }

  /// Get coin transaction history
  static Future<List<CoinTransactionModel>> getCoinTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('coin_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CoinTransactionModel.fromJson(json))
        .toList();
  }

  /// Convert coins to rupees (1:1 ratio, 1 coin = ₹1)
  static double coinsToRupees(double coins) {
    return coins;
  }

  /// Convert rupees to coins (1:1 ratio, ₹1 = 1 coin)
  static double rupeesToCoins(double rupees) {
    return rupees;
  }

  /// Deduct coins for game entry fee (uses Supabase RPC for atomic operation)
  static Future<bool> deductCoinsForGame(double amount, String gameTitle) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.rpc('deduct_game_entry_fee', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_game_title': gameTitle,
    });

    final result = response as Map<String, dynamic>;
    return result['success'] == true;
  }
}
