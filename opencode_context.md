# EarnRupai - Project Context

## Overview
EarnRupai is a Flutter mobile application (v1.1.5+16) that allows users to earn money by completing tasks, playing games, and referring others. The app integrates Supabase for backend services, Firebase for notifications, and AdMob for advertising.

## Technology Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.0+ |
| State Management | Riverpod (flutter_riverpod: ^2.6.1) |
| Navigation | GoRouter (go_router: ^14.6.0) |
| Backend | Supabase (supabase_flutter: ^2.8.0) |
| Authentication | Supabase Auth + Firebase (optional) |
| Ads | Google Mobile Ads (google_mobile_ads: ^7.0.0), Unity Mediation (gma_mediation_unity: ^1.6.5) |
| Database | Supabase PostgreSQL |
| Push Notifications | Firebase Cloud Messaging (firebase_messaging: ^16.1.1), flutter_local_notifications: ^19.5.0 |
| UI Components | Material Design with custom theming |

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # App-wide constants (API keys, config)
│   ├── router/
│   │   └── app_router.dart        # GoRouter configuration with auth guards
│   ├── theme/
│   │   ├── app_colors.dart        # Color palette
│   │   ├── app_theme.dart         # Light/dark themes
│   │   └── app_text_styles.dart   # Typography
│   └── utils/
│       └── validators.dart        # Input validation utilities
├── features/
│   ├── auth/
│   │   └── presentation/screens/
│   │       ├── login_screen.dart
│   │       ├── signup_screen.dart
│   │       ├── splash_screen.dart
│   │       ├── otp_verification_screen.dart
│   │       ├── email_verification_screen.dart
│   │       └── verify_email_prompt_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/dashboard_screen.dart
│   │       ├── providers/dashboard_messages_provider.dart
│   │       └── widgets/
│   ├── tasks/
│   │   ├── data/models/task_model.dart
│   │   ├── data/services/task_service.dart
│   │   └── presentation/
│   │       ├── screens/tasks_list_screen.dart, task_detail_screen.dart
│   │       ├── providers/tasks_provider.dart
│   │       └── widgets/task_card.dart
│   ├── games/
│   │   ├── data/models/game_model.dart
│   │   ├── data/services/game_service.dart, token_service.dart
│   │   └── presentation/screens/games_hub_screen.dart, game_play_screen.dart
│   ├── spin_win/
│   │   ├── data/models/spin_result_model.dart, coin_transaction_model.dart
│   │   ├── data/services/coin_service.dart
│   │   └── presentation/screens/spin_win_screen.dart, widgets/spin_wheel_*.dart
│   ├── wallet/
│   │   ├── data/models/wallet_transaction.dart
│   │   ├── presentation/screens/wallet_screen.dart
│   │   └── providers/wallet_provider.dart
│   ├── profile/
│   │   └── presentation/screens/profile_screen.dart
│   ├── referral/
│   │   ├── models/referral_model.dart, referral_stats_model.dart
│   │   ├── services/referral_service.dart
│   │   ├── providers/referral_provider.dart
│   │   └── screens/refer_earn_screen.dart
│   └── notifications/
│       └── presentation/screens/notifications_screen.dart
└── shared/
    ├── providers/
    │   ├── auth_provider.dart     # Auth state providers
    │   └── theme_provider.dart    # Theme mode provider
    ├── services/
    │   ├── supabase_service.dart  # Supabase client & auth helpers
    │   ├── notification_service.dart
    │   ├── admob_service.dart     # AdMob integration
    │   ├── deep_link_service.dart # Email verification deep links
    │   ├── task_service.dart
    │   ├── wallet_service.dart
    │   ├── review_service.dart
    │   └── in_app_update_service.dart
    ├── widgets/
    │   ├── banner_ad_widget.dart
    │   └── notification_permission_dialog.dart
    └── utils/
        └── timezone_utils.dart
```

## Key Features

1. **Authentication** - Email/password signup/login, OTP verification, email verification, OAuth (Google, Facebook)
2. **Tasks** - Browse, filter, and complete tasks (surveys, videos, app installs, social media, quizzes)
3. **Games Hub** - Play web-based games using token system
4. **Spin & Win** - Daily spin wheel for earning coins
5. **Wallet** - Track earnings, pending rewards, and withdrawals
6. **Referral System** - Earn rewards by referring new users
7. **Profile** - Manage profile details, UPI ID for withdrawals
8. **Notifications** - Push notifications for updates

## Database Tables (Supabase)

- `user_profiles` - Extended user information
- `tasks` - Available tasks
- `user_tasks` - User's task assignments/progress
- `wallet_transactions` - Transaction history
- `referrals` - Referral relationships
- `dashboard_messages` - Dashboard marquee messages

## Navigation Flow

- `/` - Splash screen (auto-redirects)
- `/auth/login` - Login
- `/auth/signup` - Signup
- `/auth/otp-verify` - OTP verification
- `/auth/verification` - Email verification result
- `/dashboard` - Main dashboard with bottom navigation
- `/tasks` - Task list
- `/tasks/:id` - Task details
- `/wallet` - Wallet screen
- `/profile` - Profile screen
- `/notifications` - Notifications

## State Management

- Riverpod providers for reactive state
- Auth state via `authStateProvider` and `currentUserProvider`
- Wallet data via `walletProvider`
- Tasks via `tasksProvider`
- Theme via `themeModeProvider`

## Important Notes

- Supabase URL: `https://mcrdjwdkcoulyiafiiaz.supabase.co`
- AdMob configured with test and production IDs
- **AdMob Mediation**: Unity Ads integrated for bidding (banner & rewarded ads)
- Deep linking enabled for email verification
- In-app updates via `in_app_update` package
- WebView integration for games (`webview_flutter`)