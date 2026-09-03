import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hand_gesture_app/services/gesture_recognition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test Gesture Classifier', () async {
    final service = GestureRecognitionService();
    await service.initialize();
    
    // We provide 21 RAW [0,1] coordinates mimicking a palm (not preprocessed)
    // We will just reverse-engineer an approximate palm pose based on the dataset row
    List<double> rawLandmarks = [
      0.5, 0.5, // wrist
      0.5 - 0.038, 0.5 - 0.097, // thumb_cmc
      0.5 - 0.074, 0.5 - 0.326, // thumb_mcp
      0.5 - 0.109, 0.5 - 0.573, // thumb_ip
      0.5 - 0.128, 0.5 - 0.733, // thumb_tip
      0.5 - 0.153, 0.5 - 0.490, // index_mcp
      0.5 - 0.187, 0.5 - 0.814, // index_pip
      0.5 - 0.181, 0.5 - 0.850, // index_dip
      0.5 - 0.172, 0.5 - 0.823, // index_tip
      0.5 - 0.141, 0.5 - 0.547, // middle_mcp
      0.5 - 0.170, 0.5 - 0.875, // middle_pip
      0.5 - 0.170, 0.5 - 0.937, // middle_dip
      0.5 - 0.167, 0.5 - 0.942, // middle_tip
      0.5 - 0.120, 0.5 - 0.576, // ring_mcp
      0.5 - 0.146, 0.5 - 0.877, // ring_pip
      0.5 - 0.149, 0.5 - 0.962, // ring_dip
      0.5 - 0.153, 0.5 - 1.000, // ring_tip
      0.5 - 0.093, 0.5 - 0.577, // pinky_mcp
      0.5 - 0.111, 0.5 - 0.816, // pinky_pip
      0.5 - 0.119, 0.5 - 0.910, // pinky_dip
      0.5 - 0.122, 0.5 - 0.972, // pinky_tip
    ];

    print('Evaluating raw landmarks length: ${rawLandmarks.length}');
    
    final result = service.classify(rawLandmarks);
    print('Prediction: ${result['gesture']} (Confidence: ${result['confidence']})');
    
    expect(result['gesture'], '01_palm');
  });
}
