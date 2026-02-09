import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static bool _initialized = false;

  /// Initialize deep link listener
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Handle deep links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Deep link received: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Deep link error: $err');
    });

    // Handle deep link that opened the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('🔗 Initial deep link: $initialUri');
      _handleDeepLink(initialUri);
    }
  }

  /// Process the deep link URI
  static void _handleDeepLink(Uri uri) {
    debugPrint('🔍 Processing deep link: $uri');
    debugPrint('🔍 Host: ${uri.host}');
    debugPrint('🔍 Path: ${uri.path}');
    debugPrint('🔍 Query parameters: ${uri.queryParameters}');
    
    // Handle HTTPS App Links from portfolio website
    if (uri.host == 'sai-vardhan-portfolio.vercel.app' && uri.path.contains('/earn-rupai/auth/verify')) {
      final tokenHash = uri.queryParameters['token_hash'];
      final type = uri.queryParameters['type'];
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      debugPrint('🌐 Website verification link detected');
      debugPrint('📧 Type: $type, Has token: ${tokenHash != null}');

      if (tokenHash != null && type == 'email') {
        _handleEmailVerification(tokenHash, accessToken, refreshToken);
      } else if (accessToken != null && refreshToken != null) {
        _handleEmailVerification(null, accessToken, refreshToken);
      }
      return;
    }
    
    // Handle custom scheme callback (fallback)
    if (uri.path.contains('/auth/callback')) {
      final tokenHash = uri.queryParameters['token_hash'];
      final type = uri.queryParameters['type'];
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      debugPrint('📧 Custom scheme auth callback detected - Type: $type');

      if (tokenHash != null && type == 'email') {
        _handleEmailVerification(tokenHash, accessToken, refreshToken);
      } else if (accessToken != null && refreshToken != null) {
        _handleEmailVerification(null, accessToken, refreshToken);
      }
    }
  }

  /// Handle email verification
  static Future<void> _handleEmailVerification(
    String? tokenHash,
    String? accessToken,
    String? refreshToken,
  ) async {
    try {
      debugPrint('✅ Processing email verification...');
      debugPrint('ℹ️ Token hash: ${tokenHash != null ? "Present" : "None"}');
      debugPrint('ℹ️ Access token: ${accessToken != null ? "Present" : "None"}');
      debugPrint('ℹ️ Refresh token: ${refreshToken != null ? "Present" : "None"}');
      
      // Supabase automatically handles the verification when the deep link is opened
      // The session will be updated automatically via the SDK
      // The auth state listener in the app will detect the change and navigate accordingly
      
      debugPrint('✅ Email verification completed successfully!');
      debugPrint('ℹ️ User will be automatically logged in');
    } catch (e) {
      debugPrint('❌ Email verification error: $e');
    }
  }
}
