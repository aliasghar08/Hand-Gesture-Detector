import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_gesture_app/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hand_gesture_app/services/gesture_recognition_service.dart';
import 'package:hand_gesture_app/services/tts_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final GestureRecognitionService _gestureService = GestureRecognitionService();
  final TTSService _ttsService = TTSService();

  String _recognizedGesture = "✋ Show your hand";
  bool _isInitialized = false;
  String _status = "Initializing...";
  int _frameCount = 0;
  String _debugInfo = "Waiting for frames...";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _updateStatus("Requesting camera permission...");
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        _updateStatus("Camera permission denied");
        return;
      }

      _updateStatus("Initializing Custom AI Model...");
      await _gestureService.initialize();

      _updateStatus("Loading camera...");
      if (cameras == null || cameras!.isEmpty) {
        _updateStatus("No cameras found");
        return;
      }

      final camera = cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() => _isInitialized = true);
      _updateStatus("Ready! Show your hand");

      await _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      _updateStatus("Error: $e");
    }
  }

  void _updateStatus(String msg) {
    if (!mounted) return;
    setState(() => _status = msg);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isInitialized) return;

    _frameCount++;
    // Process every 5th frame for better performance
    if (_frameCount % 5 != 0) return;

    _isProcessing = true;

    try {
      final String gesture = _gestureService.recognizeGesture(image);

      if (!mounted) return;

      setState(() {
        _recognizedGesture = gesture;
        _debugInfo = "Frame $_frameCount | ML Inference";
      });

      // Speak the gesture
      if (gesture != "Error" && gesture != "Model not loaded" && gesture != "Failed to process image") {
        _ttsService.speakGesture(gesture);
      }
    } catch (e) {
      print("Error processing frame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _gestureService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hand Gesture")),
        body: Center(child: Text(_status)),
      );
    }

    final controller = _controller!;
    final previewSize = controller.value.previewSize!;
    final previewAspectRatio = previewSize.height / previewSize.width;
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom ML Gesture Recognition"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera Preview with proper aspect ratio
          Center(
            child: Transform.scale(
              scale: previewAspectRatio / deviceRatio,
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
          
          // Gesture Text Overlay
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _recognizedGesture,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _debugInfo,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}