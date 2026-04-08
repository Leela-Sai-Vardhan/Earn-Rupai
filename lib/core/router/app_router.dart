import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:earnrupai/features/auth/presentation/screens/splash_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/login_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/signup_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/verify_email_prompt_screen.dart';
import 'package:earnrupai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:earnrupai/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:earnrupai/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:earnrupai/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:earnrupai/features/profile/presentation/screens/profile_screen.dart';
import 'package:earnrupai/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:earnrupai/shared/services/supabase_service.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/') {
        return '/auth/login';
      }

      if (isAuthenticated) {
        // If logged in but email not verified, force verify screen
        // (but allow the OTP screen itself to remain visible)
        final isEmailVerified = SupabaseService.isEmailVerified;
        final isOtpRoute = state.matchedLocation == '/auth/otp-verify';
        if (!isEmailVerified && !isOtpRoute &&
            state.matchedLocation != '/auth/verify-email-prompt') {
          return '/auth/verify-email-prompt';
        }
        
        // If logged in, verified, and on auth route, go to dashboard
        if (isEmailVerified && isAuthRoute && !isOtpRoute) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/verification',
        builder: (context, state) {
          final success = state.uri.queryParameters['success'] == 'true';
          final message = state.uri.queryParameters['message'];
          return EmailVerificationScreen(
            success: success,
            message: message,
          );
        },
      ),
      GoRoute(
        path: '/auth/otp-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          final email = extra?['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth/verify-email-prompt',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          final email = extra?['email'] ?? SupabaseService.currentUser?.email ?? '';
          return VerifyEmailPromptScreen(email: email);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksListScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
