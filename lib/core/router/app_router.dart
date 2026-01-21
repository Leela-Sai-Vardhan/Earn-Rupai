import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:earnrupai/features/auth/presentation/screens/splash_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/login_screen.dart';
import 'package:earnrupai/features/auth/presentation/screens/signup_screen.dart';
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

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
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
