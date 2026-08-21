import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  String _lastSpokenGesture = "";
  DateTime? _lastSpokenTime;

  TTSService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speakGesture(String gesture) async {
    if (gesture == "Unrecognized" || gesture.isEmpty) return;

    final now = DateTime.now();
    // Speak if it's a new gesture, or if it's the same gesture but 3 seconds have passed
    if (gesture != _lastSpokenGesture || 
        (_lastSpokenTime != null && now.difference(_lastSpokenTime!).inSeconds > 3)) {
      
      _lastSpokenGesture = gesture;
      _lastSpokenTime = now;
      
      // Speak the gesture name
      await _flutterTts.speak(gesture);
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}
