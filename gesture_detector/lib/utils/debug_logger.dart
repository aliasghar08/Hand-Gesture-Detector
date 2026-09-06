import 'package:flutter/foundation.dart';

class DebugLogger {
  // Configurable flag to enable/disable debug logs
  static bool enableLogging = kDebugMode;

  static void log(String message) {
    if (enableLogging) {
      debugPrint("[DebugLogger] $message");
    }
  }

  static void logGestureInfo({
    required String gesture,
    required double confidence,
    required List<dynamic> landmarks,
  }) {
    if (!enableLogging) return;
    
    debugPrint("===== DEBUG GESTURE INFO =====");
    debugPrint("Detected Gesture: $gesture");
    debugPrint("Confidence: ${confidence.toStringAsFixed(3)}");
    debugPrint("Total Landmarks Found: ${landmarks.length}");
    
    if (landmarks.isNotEmpty) {
      final wrist = landmarks[0];
      debugPrint("Wrist Point (Raw): X: ${wrist.x.toStringAsFixed(3)}, Y: ${wrist.y.toStringAsFixed(3)}");
    }
    debugPrint("==============================");
  }
  
  static void logError(String context, dynamic error) {
    if (enableLogging) {
      debugPrint("===== ERROR =====");
      debugPrint("Context: $context");
      debugPrint("Details: $error");
      debugPrint("=================");
    }
  }
}
