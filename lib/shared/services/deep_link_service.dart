import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/router/app_router.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static bool _initialized = false;

  /// Initialize deep link listener
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Handle deep links when app is already running (foreground/background)
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Deep link received: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Deep link error: $err');
    });

    // Handle deep link that cold-started the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('🔗 Initial deep link: $initialUri');
      await Future.delayed(const Duration(milliseconds: 800));
      _handleDeepLink(initialUri);
    }
  }

  /// Process the deep link URI
  static void _handleDeepLink(Uri uri) {
    debugPrint('🔍 Processing: ${uri.toString()}');

    // ── earnrupai://auth/callback  (implicit flow — Supabase adds tokens as fragment) ──
    // Fragment:  #access_token=xxx&refresh_token=xxx&type=signup
    // OR query:  ?access_token=xxx&... (some Supabase versions)
    if (uri.scheme == 'earnrupai' && uri.host == 'auth') {
      // Parse fragment (e.g. #access_token=xxx&token_type=bearer&...)
      final fragment = uri.fragment; // e.g. "access_token=xxx&refresh_token=yyy&type=signup"
      final fragmentParams = Uri.splitQueryString(fragment);

      final accessToken = fragmentParams['access_token'] ?? uri.queryParameters['access_token'];
      final refreshToken = fragmentParams['refresh_token'] ?? uri.queryParameters['refresh_token'];
      final type = fragmentParams['type'] ?? uri.queryParameters['type'];

      debugPrint('📧 earnrupai:// callback — type=$type, hasAccessToken=${accessToken != null}');

      if (accessToken != null && refreshToken != null) {
        // Set the Supabase session from the tokens in the deep link
        _setSessionAndNavigate(accessToken: accessToken, refreshToken: refreshToken);
      } else {
        // Fallback: just navigate to verification screen with success=false
        _navigateToVerificationScreen(success: false, message: 'Could not retrieve session from link.');
      }
      return;
    }

    // ── HTTPS App Link fallback (only fires on release build w/ valid assetlinks.json) ──
    if (uri.host == 'sai-vardhan-portfolio.vercel.app' &&
        uri.path.contains('/earn-rupai/auth')) {
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      // Fragment params (Supabase sometimes puts tokens in fragment for HTTPS links)
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      final fragAccessToken = fragmentParams['access_token'];
      final fragRefreshToken = fragmentParams['refresh_token'];

      final at = accessToken ?? fragAccessToken;
      final rt = refreshToken ?? fragRefreshToken;

      if (at != null && rt != null) {
        _setSessionAndNavigate(accessToken: at, refreshToken: rt);
      } else {
        _navigateToVerificationScreen(success: true);
      }
    }
  }

  /// Set Supabase session from tokens and navigate to result screen
  static Future<void> _setSessionAndNavigate({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      debugPrint('🔐 Setting session from deep link tokens...');
      await Supabase.instance.client.auth.setSession(accessToken);
      debugPrint('✅ Session set successfully');
      _navigateToVerificationScreen(success: true);
    } catch (e) {
      debugPrint('❌ Failed to set session: $e');
      _navigateToVerificationScreen(
        success: false,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Navigate to the email verification result screen
  static void _navigateToVerificationScreen({
    required bool success,
    String? message,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Navigator context not ready, retrying...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToVerificationScreen(success: success, message: message);
      });
      return;
    }

    debugPrint('✅ Navigating to /auth/verification — success: $success');

    final params = <String, String>{'success': success.toString()};
    if (message != null) params['message'] = message;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    GoRouter.of(context).go('/auth/verification?$query');
  }
}
