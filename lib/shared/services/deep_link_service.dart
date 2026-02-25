import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

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
      // Small delay to ensure router is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleDeepLink(initialUri);
    }
  }

  /// Process the deep link URI
  static void _handleDeepLink(Uri uri) {
    debugPrint('🔍 Processing deep link: $uri');
    debugPrint('🔍 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    debugPrint('🔍 Query parameters: ${uri.queryParameters}');

    // ── Custom scheme: earnrupai://auth/callback?success=true ──
    if (uri.scheme == 'earnrupai' && uri.host == 'auth' && uri.path.contains('/callback')) {
      final success = uri.queryParameters['success'] != 'false';
      final message = uri.queryParameters['message'];
      debugPrint('📧 Custom scheme auth callback — success: $success');
      _navigateToVerificationScreen(success: success, message: message);
      return;
    }

    // ── HTTPS App Link: sai-vardhan-portfolio.vercel.app/earn-rupai/auth/verify ──
    if (uri.host == 'sai-vardhan-portfolio.vercel.app' &&
        uri.path.contains('/earn-rupai/auth/verify')) {
      final tokenHash = uri.queryParameters['token_hash'];
      final type = uri.queryParameters['type'];
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      debugPrint('🌐 HTTPS App Link detected — type: $type, hasToken: ${tokenHash != null}');

      if ((tokenHash != null && type == 'email') ||
          (accessToken != null && refreshToken != null)) {
        // Supabase SDK auto-handles the session; navigate to success screen
        _navigateToVerificationScreen(success: true);
      } else {
        _navigateToVerificationScreen(success: false);
      }
    }
  }

  /// Navigate to the email verification result screen
  static void _navigateToVerificationScreen({
    required bool success,
    String? message,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Navigator context not ready, retrying in 500ms...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToVerificationScreen(success: success, message: message);
      });
      return;
    }

    debugPrint('✅ Navigating to /auth/verification — success: $success');

    final params = <String, String>{'success': success.toString()};
    if (message != null) params['message'] = message;

    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    GoRouter.of(context).go('/auth/verification?$query');
  }
}
