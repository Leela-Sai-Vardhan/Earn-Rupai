import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/supabase_service.dart';

/// Fetches active dashboard messages from Supabase for the marquee banner.
final dashboardMessagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('dashboard_messages')
        .select('message')
        .eq('is_active', true)
        .order('display_order');

    return (response as List<dynamic>)
        .map((row) => row['message'] as String)
        .toList();
  } catch (e) {
    // Return a default message if fetch fails
    return ['Welcome to Earn Rupai – spin, play, and earn every day!'];
  }
});
