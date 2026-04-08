import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/router/app_router.dart';
import '../widgets/notification_permission_dialog.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background notification
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await requestPermission();

      // Setup FCM
      await _setupFCM();

      // Setup notification handlers
      _setupNotificationHandlers();

      // Re-save token when app comes back to foreground
      // This gradually fixes users with missing/stale tokens
      AppLifecycleListener(
        onResume: () {
          debugPrint('📱 App resumed — re-saving FCM token');
          saveTokenIfUserLoggedIn();
        },
      );

      // Also try saving 3 seconds after startup (Supabase session may restore slowly)
      Future.delayed(const Duration(seconds: 3), () {
        debugPrint('⏱️ Startup delayed token save');
        saveTokenIfUserLoggedIn();
      });

      _initialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'earnrupai_channel',
        'EarnRupai Notifications',
        description: 'Notifications for task rewards, new tasks, and updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      // Request FCM permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      debugPrint('Notification permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Save token to Supabase (may be skipped if user not yet logged in)
    if (_fcmToken != null) {
      await saveFCMToken(_fcmToken!);
    }

    // Listen for token refresh — saves new token whenever Firebase rotates it
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      saveFCMToken(newToken);
      debugPrint('🔄 FCM token refreshed and saved');
    });

    // Listen for auth state changes — saves token when user signs in
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && _fcmToken != null) {
        saveFCMToken(_fcmToken!);
        debugPrint('🔐 Auth sign-in detected — FCM token saved');
      }
    });
  }

  /// Call this after a successful login to ensure the FCM token is saved.
  /// Use when initialize() may have run before the user was authenticated.
  Future<void> saveTokenIfUserLoggedIn() async {
    if (_fcmToken != null) {
      await saveFCMToken(_fcmToken!);
    }
  }

  /// Setup notification handlers
  void _setupNotificationHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Message opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened from background: ${message.notification?.title}');
      _handleNotificationTap(message.data);
    });

    // Check for initial message (app opened from terminated state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from notification: ${message.notification?.title}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'earnrupai_channel',
      'EarnRupai Notifications',
      channelDescription: 'Notifications for task rewards, new tasks, and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Handle notification tap with data
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Handling notification tap with data: $data');
    // TODO: Navigate based on notification type
    final type = data['type'];
    switch (type) {
      case 'task_reward':
        // Navigate to wallet screen
        if (navigatorKey.currentContext != null) {
          navigatorKey.currentContext!.push('/wallet');
        }
        break;
      case 'new_task':
        // Navigate to task detail screen
        final taskId = data['task_id'];
        if (taskId != null && navigatorKey.currentContext != null) {
          navigatorKey.currentContext!.push('/tasks/$taskId');
        }
        break;
      case 'app_update':
        // Show update dialog or navigate to specific screen
        // For now, we can just navigate to dashboard or show a snackbar (if needed)
        // Or if there's an update screen, navigate there.
        // Assuming we want to ensure they are on dashboard to see update prompts:
         if (navigatorKey.currentContext != null) {
          navigatorKey.currentContext!.go('/dashboard');
        }
        break;
    }
  }

  /// Save FCM token to Supabase
  Future<void> saveFCMToken(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('No user logged in, skipping FCM token save');
        return;
      }

      await supabase.from('user_profiles').update({
        'fcm_token': token,
      }).eq('user_id', userId);

      debugPrint('✅ FCM token saved to Supabase');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Check notification permission and show prompt dialog if denied.
  /// Uses a 3-day cooldown so the user is not pestered every launch.
  Future<void> checkAndPromptPermission(BuildContext context) async {
    try {
      final enabled = await areNotificationsEnabled();
      if (enabled) return; // Permission already granted, nothing to do

      // Check last-shown date from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastShownMs = prefs.getInt('notif_prompt_last_shown') ?? 0;
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      final daysSince = DateTime.now().difference(lastShown).inDays;

      // Only show if never shown or 3+ days have passed
      if (daysSince < 3 && lastShownMs != 0) return;

      if (!context.mounted) return;

      // Save the current time so we don't show again for 3 days
      await prefs.setInt(
        'notif_prompt_last_shown',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Re-check mounted after all awaits before using context
      if (!context.mounted) return;

      // Show the permission bottom sheet
      await NotificationPermissionDialog.show(context, () {
        debugPrint('Notification permission dialog dismissed');
      });
    } catch (e) {
      debugPrint('Error in checkAndPromptPermission: $e');
    }
  }
}
