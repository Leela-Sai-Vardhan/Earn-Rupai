import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: true,
      ),
    );
    _client = Supabase.instance.client;
  }

  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static bool get isEmailVerified {
    final user = currentUser;
    if (user == null) return false;
    debugPrint('DEBUG: Checking Verification. Email: ${user.email}');
    debugPrint('DEBUG: emailConfirmedAt: ${user.emailConfirmedAt}');
    debugPrint('DEBUG: appMetadata: ${user.appMetadata}');
    
    // Check both possible indicators
    return user.emailConfirmedAt != null || 
           user.appMetadata['email_verified'] == true;
  }
  static String? get currentUserId => currentUser?.id;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  /// Verify the 6-digit OTP sent to the user's email during signup.
  /// On success, Supabase returns a session — the user is logged in immediately.
  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final response = await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    return response;
  }

  static Future<void> refreshSession() async {
    try {
      await client.auth.refreshSession();
      debugPrint('DEBUG: Session refreshed successfully');
    } catch (e) {
      debugPrint('DEBUG: Error refreshing session: $e');
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(OAuthProvider.google);
  }

  static Future<bool> signInWithFacebook() async {
    return await client.auth.signInWithOAuth(OAuthProvider.facebook);
  }

  static Future<void> updateProfile({String? fullName, String? upiId, String? phoneNumber}) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (upiId != null) updates['upi_id'] = upiId;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;

    if (updates.isEmpty) return;

    // Update auth metadata if name changes
    if (fullName != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }
      
    // Use RPC to update profile details securely to bypass RLS
    await client.rpc('update_user_profile_details', params: {
      'user_uuid': userId,
      'new_full_name': fullName, // Can be null
      'new_upi_id': upiId, // Can be null
    });
  }

  // Database helpers
  static SupabaseQueryBuilder get userProfiles => client.from('user_profiles');
  static SupabaseQueryBuilder get tasks => client.from('tasks');
  static SupabaseQueryBuilder get userTasks => client.from('user_tasks');
  static SupabaseQueryBuilder get walletTransactions => client.from('wallet_transactions');
}
