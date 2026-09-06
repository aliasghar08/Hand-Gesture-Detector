import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:hand_gesture_app/services/dart_mlp_classifier.dart';

/// Handles only Stage 2: 21 MediaPipe landmarks -> gesture label.
/// Stage 1 (hand detection + landmark extraction) is done by the
/// hand_detection plugin in CameraScreen.
class GestureRecognitionService {
  DartMlpClassifier _classifier = DartMlpClassifier();
  List<String> _labels = [];
  List<double> _scalerMean = [];
  List<double> _scalerScale = [];

  // Smoothing fields
  List<double>? _emaLandmarks;
  final double _emaAlpha = 0.4; // Smoothing factor (lower = smoother)
  
  // Rolling window for classification
  final int _windowSize = 5;
  final List<String> _history = [];

  bool get isReady => _classifier.isReady && _labels.isNotEmpty;

  Future<void> initialize() async {
    // Load MLP gesture classifier weights
    final weightsJson = await rootBundle.loadString('assets/gesture_weights.json');
    await _classifier.loadWeights(weightsJson);

    final labelsJson = await rootBundle.loadString('assets/gesture_labels.json');
    _labels = List<String>.from(jsonDecode(labelsJson));

    final scalerJson = await rootBundle.loadString('assets/scaler_params.json');
    final scalerData = jsonDecode(scalerJson);
    _scalerMean  = List<double>.from(scalerData['mean']);
    _scalerScale = List<double>.from(scalerData['scale']);
  }

  void dispose() {
    // Nothing to dispose for DartMlpClassifier
  }

  /// Classify a gesture from 21 landmarks.
  /// [landmarks] must be a flat list of 42 doubles: [x0,y0, x1,y1, ..., x20,y20]
  /// Returns {gesture: String, confidence: double}.
  Map<String, dynamic> classify(List<double> landmarks) {
    if (!isReady || landmarks.length != 42) {
      return {'gesture': '', 'confidence': 0.0};
    }

    // Apply EMA smoothing to landmarks
    if (_emaLandmarks == null) {
      _emaLandmarks = List.from(landmarks);
    } else {
      for (int i = 0; i < 42; i++) {
        _emaLandmarks![i] = _emaAlpha * landmarks[i] + (1.0 - _emaAlpha) * _emaLandmarks![i];
      }
    }
    final smoothedLandmarks = _emaLandmarks!;

    try {
      // Step 1: Convert to wrist-relative coordinates
      final double wristX = smoothedLandmarks[0];
      final double wristY = smoothedLandmarks[1];

      
      List<double> relativeCoords = [];
      
      for (int i = 0; i < smoothedLandmarks.length; i += 2) {
        relativeCoords.add(smoothedLandmarks[i] - wristX);
        relativeCoords.add(smoothedLandmarks[i + 1] - wristY);
      }
      
      // Step 2: Rotation invariance
      // Middle Finger MCP is at index 9 (x=18, y=19)
      final double mx = relativeCoords[18];
      final double my = relativeCoords[19];
      
      // Calculate angle of wrist-to-middle_mcp
      final double angle = math.atan2(my, mx);
      final double delta = -math.pi / 2 - angle;
      
      final double cosD = math.cos(delta);
      final double sinD = math.sin(delta);
      
      List<double> rotatedCoords = [];
      double maxAbsValue = 0.0;
      
      for (int i = 0; i < relativeCoords.length; i += 2) {
        double x = relativeCoords[i];
        double y = relativeCoords[i + 1];
        double xRot = x * cosD - y * sinD;
        double yRot = x * sinD + y * cosD;
        
        rotatedCoords.add(xRot);
        rotatedCoords.add(yRot);
        
        if (xRot.abs() > maxAbsValue) maxAbsValue = xRot.abs();
        if (yRot.abs() > maxAbsValue) maxAbsValue = yRot.abs();
      }
      
      // Step 3: Normalize by max absolute value (avoid division by zero)
      List<double> normalizedCoords = [];
      if (maxAbsValue > 0) {
        for (int i = 0; i < rotatedCoords.length; i++) {
          normalizedCoords.add(rotatedCoords[i] / maxAbsValue);
        }
      } else {
        normalizedCoords = List.from(rotatedCoords);
      }
      
      // Step 3.5: Append the angle features (cos and sin)
      normalizedCoords.add(cosD);
      normalizedCoords.add(sinD);

      // Step 4: Apply the StandardScaler from training
      final normalized = List<double>.generate(
        normalizedCoords.length,
        (i) => (normalizedCoords[i] - _scalerMean[i]) / _scalerScale[i],
      );

      final probs = _classifier.predict(normalized);
      
      int bestIdx = 0;
      double bestProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > bestProb) {
          bestProb = probs[i];
          bestIdx = i;
        }
      }

      String rawGesture = bestProb > 0.40 ? _labels[bestIdx] : '';

      // Update history buffer for temporal smoothing
      _history.add(rawGesture);
      if (_history.length > _windowSize) {
        _history.removeAt(0);
      }

      // Find the most frequent gesture (Mode) in the history window
      String finalGesture = '';
      if (_history.isNotEmpty) {
        final counts = <String, int>{};
        for (var g in _history) {
          counts[g] = (counts[g] ?? 0) + 1;
        }
        var mode = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
        
        // Require majority agreement in the window
        if (mode.value >= (_windowSize / 2.0).ceil()) {
          finalGesture = mode.key;
        }
      }

      return {
        'gesture': finalGesture,
        'confidence': bestProb,
      };
    } catch (e) {
      return {'gesture': '', 'confidence': 0.0};
    }
  }
}
