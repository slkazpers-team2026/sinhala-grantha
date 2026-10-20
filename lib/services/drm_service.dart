import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DrmService {
  static const MethodChannel _channel = MethodChannel('com.bookworld.drm/secure');

  /// Calls native Android WindowManager.addFlags(FLAG_SECURE)
  /// to permanently block screenshots and screen recordings on Android devices.
  static Future<void> secureScreen() async {
    try {
      await _channel.invokeMethod('secureScreen');
      debugPrint('DrmService: FLAG_SECURE successfully enabled via Native Channel.');
    } catch (e) {
      debugPrint('DrmService: Error enabling FLAG_SECURE: $e');
    }
  }

  /// Clears FLAG_SECURE if required
  static Future<void> clearSecure() async {
    try {
      await _channel.invokeMethod('clearSecure');
      debugPrint('DrmService: FLAG_SECURE cleared via Native Channel.');
    } catch (e) {
      debugPrint('DrmService: Error clearing FLAG_SECURE: $e');
    }
  }
}
