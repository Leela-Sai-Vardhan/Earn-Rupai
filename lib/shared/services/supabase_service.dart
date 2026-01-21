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
    );
    _client = Supabase.instance.client;
  }

  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
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

  static Future<void> updateProfile({String? fullName, String? upiId}) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (upiId != null) updates['upi_id'] = upiId;

    if (updates.isEmpty) return;

    // Update auth metadata if name changes
    if (fullName != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }
      
    // Update profile table
    await userProfiles
        .update(updates)
        .eq('user_id', userId);
  }

  // Database helpers
  static SupabaseQueryBuilder get userProfiles => client.from('user_profiles');
  static SupabaseQueryBuilder get tasks => client.from('tasks');
  static SupabaseQueryBuilder get userTasks => client.from('user_tasks');
  static SupabaseQueryBuilder get walletTransactions => client.from('wallet_transactions');
}
