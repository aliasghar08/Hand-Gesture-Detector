import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:hand_gesture_app/core/app_strings.dart';
import 'package:hand_gesture_app/services/gesture_recognition_service.dart';
import 'package:hand_gesture_app/services/tts_service.dart';
import 'package:hand_gesture_app/utils/debug_logger.dart';

abstract class BaseGestureControllerManager extends ChangeNotifier {
  final GestureRecognitionService gestureService = GestureRecognitionService();
  final TTSService ttsService = TTSService();
  HandDetector? handDetector;
  final FrameThrottle throttle = FrameThrottle();
  bool isProcessing = false;

  String _recognizedGesture = AppStrings.defaultGestureText;
  String _debugInfo = "Waiting for frames...";
  List<Hand> _hands = [];
  double _confidence = 0.0;

  String get recognizedGesture => _recognizedGesture;
  String get debugInfo => _debugInfo;
  List<Hand> get hands => _hands;
  double get confidence => _confidence;

  Future<void> initializeModel() async {
    await gestureService.initialize();
    
    // Initialize the hand detector plugin
    handDetector = await HandDetector.create(maxDetections: 1);
  }

  /// Platform-specific implementation for processing camera images
  Future<void> processCameraImage(dynamic imageOrVideo, int sensorOrientation, DeviceOrientation deviceOrientation);

  void onLandmarksReceivedFromDimensions(List<Hand> handsReceived, int width, int height, int sensorOrientation) {
    if (handsReceived.isNotEmpty) {
      final hand = handsReceived.first;
      
      final landmarks = hand.landmarks.expand((lm) {
        // Pass the raw pixel coordinates directly by multiplying normalized coords by width/height.
        // The ML model was trained on true pixel coordinates (translated to wrist and max-abs scaled),
        // so we don't need to normalize to [0, 1] or squish the aspect ratio!
        return [lm.x * width, lm.y * height];
      }).toList();
      
      final result = gestureService.classify(landmarks);
      _recognizedGesture = result['gesture'] as String;
      _confidence = result['confidence'] as double;
      
      _debugInfo = "${(_confidence * 100).toStringAsFixed(1)}% | Gesture: $_recognizedGesture";
      
      // Extensive debug prints for user request via reusable logger
      DebugLogger.logGestureInfo(
        gesture: _recognizedGesture, 
        confidence: _confidence, 
        landmarks: hand.landmarks
      );

      if (_recognizedGesture.isNotEmpty && _recognizedGesture != '01_palm') {
        ttsService.speakGesture(_recognizedGesture);
      }
    } else {
      _recognizedGesture = '';
      _confidence = 0.0;
      _debugInfo = "Detecting...";
    }
    
    _hands = handsReceived;
    notifyListeners();
  }

  @override
  void dispose() {
    // The dart side of hand_detection doesn't expose a dispose on the detector itself 
    // because it relies on Dart garbage collection for Isolate cleanup
    gestureService.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
