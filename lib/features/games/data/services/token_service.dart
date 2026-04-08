import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class TokenService {
  static final _supabase = Supabase.instance.client;

  static const String _gamesPlayedTodayKey = 'games_played_today';
  static const String _lastPlayDateKey = 'last_play_date';
  static const String _lastPlayTimeKey = 'last_play_time';
  static const String _dailyTokensEarnedKey = 'daily_tokens_earned';

  // Limits
  static const int maxPlaysPerDay = 10;
  static const int cooldownSeconds = 30;
  static const int maxDailyTokens = 200;

  /// Get current token balance from Supabase
  static Future<double> getTokenBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final result = await _supabase.rpc(
        'get_game_token_balance',
        params: {'p_user_id': userId},
      );
      return (result as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting token balance: $e');
      return 0;
    }
  }

  /// Add tokens to Supabase balance (with daily limit from local prefs)
  static Future<double> addTokens(int amount) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final prefs = await SharedPreferences.getInstance();
      final dailyEarned = _getDailyTokensEarned(prefs);

      // Cap to daily limit
      final allowedAmount = (dailyEarned + amount) > maxDailyTokens
          ? maxDailyTokens - dailyEarned
          : amount;

      if (allowedAmount <= 0) return await getTokenBalance();

      // Update local daily tracker
      await prefs.setInt(_dailyTokensEarnedKey, dailyEarned + allowedAmount);

      // Sync to Supabase
      final response = await _supabase.rpc('add_game_tokens', params: {
        'p_user_id': userId,
        'p_amount': allowedAmount,
      });

      final result = response as Map<String, dynamic>;
      return (result['new_balance'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('❌ Error adding tokens: $e');
      return 0;
    }
  }

  /// Get number of games played today
  static Future<int> getGamesPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    return prefs.getInt(_gamesPlayedTodayKey) ?? 0;
  }

  /// Record a game play
  static Future<void> recordGamePlay() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    final played = prefs.getInt(_gamesPlayedTodayKey) ?? 0;
    await prefs.setInt(_gamesPlayedTodayKey, played + 1);
    await prefs.setInt(_lastPlayTimeKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_lastPlayDateKey, _todayString());
  }

  /// Check if user can play a game (daily limit + cooldown)
  static Future<Map<String, dynamic>> canPlayGame() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);

    final gamesPlayed = prefs.getInt(_gamesPlayedTodayKey) ?? 0;
    if (gamesPlayed >= maxPlaysPerDay) {
      return {
        'canPlay': false,
        'reason': 'Daily play limit reached ($maxPlaysPerDay games/day)',
      };
    }

    final lastPlayTime = prefs.getInt(_lastPlayTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - lastPlayTime) ~/ 1000;
    if (lastPlayTime > 0 && elapsed < cooldownSeconds) {
      final remaining = cooldownSeconds - elapsed;
      return {
        'canPlay': false,
        'reason': 'Cooldown: wait ${remaining}s before next game',
      };
    }

    final dailyTokens = _getDailyTokensEarned(prefs);
    if (dailyTokens >= maxDailyTokens) {
      return {
        'canPlay': false,
        'reason': 'Daily token limit reached ($maxDailyTokens tokens/day)',
      };
    }

    return {'canPlay': true, 'reason': ''};
  }

  /// Get remaining plays today
  static Future<int> getRemainingPlays() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    final played = prefs.getInt(_gamesPlayedTodayKey) ?? 0;
    return maxPlaysPerDay - played;
  }

  // --- Private helpers ---

  static int _getDailyTokensEarned(SharedPreferences prefs) {
    _resetIfNewDay(prefs);
    return prefs.getInt(_dailyTokensEarnedKey) ?? 0;
  }

  static void _resetIfNewDay(SharedPreferences prefs) {
    final lastDate = prefs.getString(_lastPlayDateKey) ?? '';
    if (lastDate != _todayString()) {
      prefs.setInt(_gamesPlayedTodayKey, 0);
      prefs.setInt(_dailyTokensEarnedKey, 0);
      prefs.setString(_lastPlayDateKey, _todayString());
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
