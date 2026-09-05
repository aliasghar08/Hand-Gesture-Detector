import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Handles only Stage 2: 21 MediaPipe landmarks → gesture label.
/// Stage 1 (hand detection + landmark extraction) is done by the
/// hand_landmarker plugin in CameraScreen.
class GestureRecognitionService {
  Interpreter? _classifierInterp;
  List<String> _labels = [];
  List<double> _scalerMean = [];
  List<double> _scalerScale = [];

  // Smoothing fields
  List<double>? _emaLandmarks;
  final double _emaAlpha = 0.4; // Smoothing factor (lower = smoother)
  
  // Rolling window for classification
  final int _windowSize = 5;
  final List<String> _history = [];

  bool get isReady => _classifierInterp != null && _labels.isNotEmpty;

  Future<void> initialize() async {
    // Load MLP gesture classifier (tiny model, fast on main thread)
    // On iOS, we bypass the native asset loader which frequently crashes on memory mapping,
    // and instead write the bytes to a temp file and load it physically.
    if (Platform.isIOS) {
      final byteData = await rootBundle.load('assets/gesture_classifier.tflite');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gesture_classifier.tflite');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      _classifierInterp = await Interpreter.fromFile(file);
    } else {
      _classifierInterp = await Interpreter.fromAsset('assets/gesture_classifier.tflite');
    }

    final labelsJson = await rootBundle.loadString('assets/gesture_labels.json');
    _labels = List<String>.from(jsonDecode(labelsJson));

    final scalerJson = await rootBundle.loadString('assets/scaler_params.json');
    final scalerData = jsonDecode(scalerJson);
    _scalerMean  = List<double>.from(scalerData['mean']);
    _scalerScale = List<double>.from(scalerData['scale']);

    print('Gesture classifier ready. Labels: $_labels');
  }

  void dispose() {
    _classifierInterp?.close();
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
      
      for (int i = 0; i < landmarks.length; i += 2) {
        relativeCoords.add(landmarks[i] - wristX);
        relativeCoords.add(landmarks[i + 1] - wristY);
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

      // Step 4: Apply the StandardScaler from training
      final normalized = List<double>.generate(
        normalizedCoords.length,
        (i) => (normalizedCoords[i] - _scalerMean[i]) / _scalerScale[i],
      );

      var input  = normalized.reshape([1, 42]);
      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _classifierInterp!.run(input, output);

      final probs = (output[0] as List).cast<double>();
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
      print('Classifier error: $e');
      return {'gesture': '', 'confidence': 0.0};
    }
  }
}
