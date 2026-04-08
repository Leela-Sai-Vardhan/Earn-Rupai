import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles requesting in-app reviews / ratings from the user.
/// - First spin coin earned → trigger immediately
/// - Visit Again or Mark as Completed → trigger every time
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  static const String _firstSpinReviewedKey = 'first_spin_review_done';

  /// Call this after the user successfully earns coins from their FIRST spin.
  /// Only shows the review dialog once for the first spin ever.
  static Future<void> requestReviewAfterFirstSpin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_firstSpinReviewedKey) ?? false;
      if (alreadyShown) return;

      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) return;

      await _inAppReview.requestReview();
      await prefs.setBool(_firstSpinReviewedKey, true);
    } catch (e) {
      debugPrint('[ReviewService] requestReviewAfterFirstSpin error: $e');
    }
  }

  /// Call this every time the user taps "Visit Again" or "Mark as Completed".
  /// Google/Apple throttle how often the dialog actually appears, so it is
  /// safe to call this unconditionally — they will suppress it when needed.
  static Future<void> requestReviewAfterTaskAction() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) return;

      await _inAppReview.requestReview();
    } catch (e) {
      debugPrint('[ReviewService] requestReviewAfterTaskAction error: $e');
    }
  }
}
