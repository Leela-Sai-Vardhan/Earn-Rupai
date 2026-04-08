import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/material.dart';

class InAppUpdateService {
  // Check for updates and perform the appropriate action
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Perform immediate update (blocking)
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Perform flexible update (background)
          await InAppUpdate.startFlexibleUpdate();
          // After download completes, prompt user to complete install
          // Ideally listen to a stream, but for simplicity we complete it if successful
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // In debug mode, this will fail because the app is not signed/on Play Store
      debugPrint('InAppUpdate Error: $e');
      // Quietly fail in production, don't block user
    }
  }
}
