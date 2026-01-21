class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://mcrdjwdkcoulyiafiiaz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jcmRqd2RrY291bHlpYWZpaWF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTc4MjIsImV4cCI6MjA4NDEzMzgyMn0.ojzoFtG8_Bx1RP3Y18_LHytpQBDXl9CY1GBjbexDoRU';

  // AdMob Configuration 
  static const bool showAds = true; // Set to true to enable ads
  static const String adMobAppId = 'ca-app-pub-1658916437389658~7899928820'; // App ID
  static const String adMobBannerAdUnitId = 'ca-app-pub-1658916437389658/7935587848'; //  Banner
  static const String adMobInterstitialAdUnitId = 'ca-app-pub-1658916437389658/6590716581'; // Interstitial

  // App Configuration
  static const String appName = 'EarnRupai';
  static const String appVersion = '1.0.0';

  // Task Categories
  static const List<String> taskCategories = [
    'All',
    'Survey',
    'Video',
    'App Install',
    'Social Media',
    'Quiz',
    'Other',
  ];

  // Task Status
  static const String taskStatusNotStarted = 'not_started';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusPendingReview = 'pending_review';
  static const String taskStatusCompleted = 'completed';
  static const String taskStatusRewarded = 'rewarded';

  // Transaction Types
  static const String transactionTypeCredit = 'credit';
  static const String transactionTypeDebit = 'debit';
  static const String transactionTypePending = 'pending';
  static const String transactionTypeWithdrawal = 'withdrawal';

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
}
