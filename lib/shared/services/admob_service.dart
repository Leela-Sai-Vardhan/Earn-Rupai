import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class AdMobService {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    }
    return AppConstants.adMobBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
    return AppConstants.adMobInterstitialAdUnitId;
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void loadInterstitialAd() {
    if (!AppConstants.showAds) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitialAd(); // Reload for next time
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (!AppConstants.showAds) {
      onAdDismissed();
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
          onAdDismissed();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      debugPrint('Warning: Interstitial ad not ready, proceeding without ad');
      onAdDismissed();
      // Try to load one for next time
      loadInterstitialAd();
    }
  }

  // ==================== REWARDED AD ====================
  
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID for rewarded ads
    }
    return AppConstants.adMobRewardedAdUnitId;
  }

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdReady = false;

  static void loadRewardedAd() {
    if (!AppConstants.showAds) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('✅ Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (err) {
          debugPrint('❌ Failed to load rewarded ad: ${err.message}');
          final responseInfo = err.responseInfo;
          if (responseInfo != null) {
            debugPrint('Adapter Responses:');
            for (var response in responseInfo.adapterResponses) {
              debugPrint(' - Adapter: ${response.adapterClassName}');
              debugPrint(' - Latency: ${response.latencyMillis}ms');
              debugPrint(' - Error: ${response.error?.message ?? "Success/No Error"}');
            }
          }
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  static void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdFailedToLoad,
    required Function(bool earnedReward) onAdDismissed,
  }) {
    if (!AppConstants.showAds) {
      onUserEarnedReward();
      return;
    }

    if (_isRewardedAdReady && _rewardedAd != null) {
      bool rewardEarned = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded ad dismissed');
          ad.dispose();
          loadRewardedAd(); // Reload for next time
          
          // Navigate only after ad is dismissed
          if (rewardEarned) {
            onUserEarnedReward();
          }
          onAdDismissed(rewardEarned);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          loadRewardedAd();
          onAdFailedToLoad(); // Let user proceed anyway
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;
          // Don't navigate here - wait for ad to dismiss
        },
      );

      _rewardedAd = null;
      _isRewardedAdReady = false;
    } else {
      debugPrint('⚠️ Rewarded ad not ready, allowing user to proceed');
      onAdFailedToLoad(); // Let user proceed anyway
      loadRewardedAd(); // Try to load one for next time
    }
  }
}
