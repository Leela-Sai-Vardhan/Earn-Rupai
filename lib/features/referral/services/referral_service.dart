import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/referral_model.dart';
import '../models/referral_stats_model.dart';

class ReferralService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user is eligible for referral program (has phone and UPI)
  Future<bool> checkReferralEligibility(String userId) async {
    try {
      final response = await _supabase
          .rpc('check_referral_eligibility', params: {'user_uuid': userId});
      return response as bool;
    } catch (e) {
      throw Exception('Failed to check eligibility: $e');
    }
  }

  /// Get user's phone number (which is their referral code)
  Future<String?> getUserReferralCode(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('phone_number')
          .eq('user_id', userId)
          .single();
      
      return response['phone_number'] as String?;
    } catch (e) {
      throw Exception('Failed to get referral code: $e');
    }
  }

  /// Validate a referral code (phone number)
  Future<Map<String, dynamic>?> validateReferralCode(String phoneNumber) async {
    try {
      debugPrint('🔍 Calling validate_referral_code RPC with: $phoneNumber');
      final response = await _supabase
          .rpc('validate_referral_code', params: {'code': phoneNumber});
      
      debugPrint('📦 Raw RPC response type: ${response.runtimeType}');
      debugPrint('📦 Raw RPC response: $response');
      
      if (response is List && response.isNotEmpty) {
        debugPrint('✅ Response is a non-empty List');
        final result = response.first as Map<String, dynamic>;
        debugPrint('📋 First item: $result');
        if (result['valid'] == true) {
          return {
            'valid': true,
            'referrer_id': result['referrer_id'],
            'referrer_name': result['referrer_name'],
            'profile_complete': result['profile_complete'],
          };
        } else {
          debugPrint('⚠️ valid field is not true: ${result['valid']}');
        }
      } else if (response is Map) {
        debugPrint('📋 Response is a Map (not List): $response');
        // Maybe RPC returns single object instead of array?
        if (response['valid'] == true) {
          return {
            'valid': true,
            'referrer_id': response['referrer_id'],
            'referrer_name': response['referrer_name'],
            'profile_complete': response['profile_complete'],
          };
        }
      } else {
        debugPrint('❌ Response is empty or wrong type');
      }
      return null;
    } catch (e) {
      debugPrint('❌ RPC Error: $e');
      throw Exception('Failed to validate referral code: $e');
    }
  }

  /// Create a referral relationship when user signs up with code
  Future<void> createReferral({
    required String referrerId,
    required String referredUserId,
    required String referralCode,
  }) async {
    try {
      await _supabase.from('referrals').insert({
        'referrer_id': referrerId,
        'referred_user_id': referredUserId,
        'referral_code': referralCode,
        'status': 'pending',
        'tasks_completed': 0,
        'tasks_rewarded': 0,
      });

      /* 
      // This update is risky from client-side due to RLS and previous implementation was syntactically incorrect (passing Future to Map).
      // We rely on Database Triggers to update counts, or query the count dynamically.
      // Prioritizing the referral creation over the stats update to prevent crashes.
      */
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }

  /// Get all referrals for a user
  Future<List<Referral>> getUserReferrals(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_referrals',
        params: {'p_user_id': userId},
      );

      if (response == null) return [];
      
      final List<dynamic> referralsList = response is List ? response : [];
      
      return referralsList.map((json) {
        return Referral.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get referrals: $e');
    }
  }

  /// Get referral statistics for a user
  Future<ReferralStats> getReferralStats(String userId) async {
    try {
      // Get user's referral earnings
      final userResponse = await _supabase
          .from('user_profiles')
          .select('referral_earnings')
          .eq('user_id', userId)
          .single();
      
      final earnings = (userResponse['referral_earnings'] as num?)?.toDouble() ?? 0.0;

      // Get all referrals
      final referrals = await getUserReferrals(userId);

      return ReferralStats.fromReferrals(referrals, earnings);
    } catch (e) {
      throw Exception('Failed to get referral stats: $e');
    }
  }

  /// Update referral progress (called when referred user completes task)
  Future<void> updateReferralProgress(String referredUserId) async {
    try {
      await _supabase.rpc('update_referral_progress', params: {
        'referred_user': referredUserId,
      });
    } catch (e) {
      throw Exception('Failed to update referral progress: $e');
    }
  }

  /// Get pending referrals count
  Future<int> getPendingReferralsCount(String userId) async {
    try {
      final response = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', userId)
          .eq('status', 'pending');
      
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get pending referrals count: $e');
    }
  }

  /// Check if user was referred by someone
  Future<bool> wasUserReferred(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('referred_by')
          .eq('user_id', userId)
          .single();
      
      return response['referred_by'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Get profile completion status
  Future<Map<String, bool>> getProfileCompletionStatus(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('phone_number, upi_id')
          .eq('user_id', userId)
          .single();
      
      final phoneNumber = response['phone_number'] as String?;
      final upiId = response['upi_id'] as String?;
      
      return {
        'has_phone': phoneNumber != null && phoneNumber.isNotEmpty,
        'has_upi': upiId != null && upiId.isNotEmpty,
        'is_eligible': (phoneNumber != null && phoneNumber.isNotEmpty) &&
                      (upiId != null && upiId.isNotEmpty),
      };
    } catch (e) {
      return {
        'has_phone': false,
        'has_upi': false,
        'is_eligible': false,
      };
    }
  }
}

