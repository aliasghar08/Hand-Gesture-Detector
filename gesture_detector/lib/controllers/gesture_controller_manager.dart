import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:hand_gesture_app/core/app_strings.dart';
import 'package:hand_gesture_app/services/gesture_recognition_service.dart';
import 'package:hand_gesture_app/services/tts_service.dart';

class GestureControllerManager extends ChangeNotifier {
  final GestureRecognitionService _gestureService = GestureRecognitionService();
  final TTSService _ttsService = TTSService();
  HandLandmarkerPlugin? _landmarkerPlugin;
  bool _isProcessing = false;

  String _recognizedGesture = AppStrings.defaultGestureText;
  String _debugInfo = "Waiting for frames...";
  List<Hand> _hands = [];
  double _confidence = 0.0;

  String get recognizedGesture => _recognizedGesture;
  String get debugInfo => _debugInfo;
  List<Hand> get hands => _hands;
  double get confidence => _confidence;

  Future<void> initializeModel() async {
    await _gestureService.initialize();
    
    // Initialize the hand landmarker plugin
    _landmarkerPlugin = HandLandmarkerPlugin.create();
  }

  void _onLandmarksReceived(List<Hand> hands, CameraImage image, int sensorOrientation) {
    _hands = hands;

    if (hands.isNotEmpty) {
      // Python training images were 640x240.
      final double trainWidth = 640.0;
      final double trainHeight = 240.0;

      // Determine the actual screen dimensions based on camera orientation.
      // On Android, sensor is landscape, so image.width > image.height.
      // If rotated 90 or 270 degrees, it becomes portrait.
      double screenWidth = image.width.toDouble();
      double screenHeight = image.height.toDouble();
      if (sensorOrientation == 90 || sensorOrientation == 270) {
        screenWidth = image.height.toDouble();
        screenHeight = image.width.toDouble();
      }

      final landmarks = hands.first.landmarks.expand((lm) {
        // The hand_landmarker plugin already rotates the image internally.
        // This means lm.x and lm.y perfectly match the screen orientation!
        // No mapping (like 1.0 - lm.y) is needed, that was causing a double-rotation!
        
        // Correct aspect ratio distortion.
        double fakeX = lm.x * (screenWidth / trainWidth);
        double fakeY = lm.y * (screenHeight / trainHeight);
        
        return [fakeX, fakeY];
      }).toList();
      
      final result = _gestureService.classify(landmarks);
      _recognizedGesture = result['gesture'] as String;
      _confidence = result['confidence'] as double;
      
      _debugInfo = "${(_confidence * 100).toStringAsFixed(1)}% confidence";

      if (_recognizedGesture.isNotEmpty) {
        _ttsService.speakGesture(_recognizedGesture);
      }
    } else {
      _recognizedGesture = '';
      _confidence = 0.0;
      _debugInfo = "Detecting...";
    }
    
    notifyListeners();
  }

  Future<void> processCameraImage(CameraImage image, int sensorOrientation) async {
    if (_landmarkerPlugin == null || _isProcessing) return;
    
    _isProcessing = true;
    try {
      final hands = _landmarkerPlugin!.detect(image, sensorOrientation);
      _onLandmarksReceived(hands, image, sensorOrientation);
    } catch (e) {
      debugPrint("HandLandmarker error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _landmarkerPlugin?.dispose();
    _gestureService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
