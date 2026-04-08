import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/supabase_service.dart';
import 'shared/services/deep_link_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/admob_service.dart';
import 'shared/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Re-enable Firebase after fixing Gradle build issues
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Deep Link Service for email verification
  await DeepLinkService.initialize();

  // TODO: Re-enable after Firebase is working
  // Initialize Notification Service
  await NotificationService().initialize();

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Set Unity Ads GDPR consent (set true if user consent is given)
  final unityMediation = GmaMediationUnity();
  await unityMediation.setGDPRConsent(true);

  // Set Unity Ads CCPA consent (set true if user consent is given)
  await unityMediation.setCCPAConsent(true);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'EarnRupai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
