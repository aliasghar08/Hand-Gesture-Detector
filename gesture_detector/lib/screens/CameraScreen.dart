import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_gesture_app/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hand_gesture_app/services/gesture_recognition_service.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  HandLandmarkerPlugin? _landmarkerPlugin;
  final GestureRecognitionService _gestureService = GestureRecognitionService();

  bool _isInitialized = false;
  bool _isFlashOn = false;
  String _status = 'Initializing...';

  // Latest results from landmark stream
  List<Hand> _hands = [];
  String _gesture = '';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _updateStatus('Requesting camera permission...');
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _updateStatus('Camera permission denied');
        return;
      }

      _updateStatus('Loading gesture classifier...');
      await _gestureService.initialize();

      _updateStatus('Initializing hand detector...');
      _landmarkerPlugin = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.6,
        delegate: HandLandmarkerDelegate.cpu,
      );

      // Listen to the landmark stream and run our MLP classifier on each frame
      _landmarkerPlugin!.landmarkStream.listen((List<Hand> hands) {
        if (!mounted) return;
        setState(() => _hands = hands);

        if (hands.isNotEmpty) {
          final isBack = _controller?.description.lensDirection == CameraLensDirection.back;
          // Flatten 21 landmarks into [x0,y0, x1,y1, ..., x20,y20]
          final landmarks = hands.first.landmarks.expand((lm) {
            double mappedX = isBack ? 1.0 - lm.y : lm.y; // For front camera, we might need lm.y depending on mirroring
            double mappedY = isBack ? lm.x : 1.0 - lm.x;
            return [mappedX, mappedY];
          }).toList();
          final result = _gestureService.classify(landmarks);
          if (mounted) {
            setState(() {
              _gesture = result['gesture'] as String;
              _confidence = result['confidence'] as double;
            });
          }
        } else {
          if (mounted) setState(() { _gesture = ''; _confidence = 0.0; });
        }
      });

      _updateStatus('Starting camera...');
      if (cameras == null || cameras!.isEmpty) {
        _updateStatus('No cameras found');
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
      _updateStatus('Ready! Show your hand');

      // Feed camera frames to the MediaPipe hand landmarker plugin
      await _controller!.startImageStream((image) {
        _landmarkerPlugin?.processFrame(
          image,
          _controller!.description.sensorOrientation,
        );
      });
    } catch (e) {
      _updateStatus('Error: $e');
    }
  }

  void _updateStatus(String msg) {
    if (!mounted) return;
    setState(() => _status = msg);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _landmarkerPlugin?.dispose();
    _gestureService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hand Gesture Detector')),
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
        title: const Text('Hand Gesture Detector'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera + landmark overlay
          Center(
            child: Transform.scale(
              scale: previewAspectRatio / deviceRatio,
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    CustomPaint(
                      painter: HandLandmarkPainter(
                        hands: _hands,
                        previewSize: previewSize,
                        lensDirection: controller.description.lensDirection,
                        sensorOrientation: controller.description.sensorOrientation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Gesture label overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _gesture.isNotEmpty
                      ? Colors.greenAccent.withValues(alpha: 0.8)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_gesture.isNotEmpty) ...[
                    Text(
                      _gesture,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    Text(
                      '${(_confidence * 100).toStringAsFixed(1)}% confidence',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ] else
                    Text(
                      _hands.isEmpty ? 'Show your hand to the camera' : 'Detecting...',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
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

/// Draws hand landmarks and skeleton bones on top of the camera preview.
/// Uses the hand_landmarker package's Hand/Landmark models directly.
class HandLandmarkPainter extends CustomPainter {
  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  HandLandmarkPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final pointPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final bonePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final hand in hands) {
      final lms = hand.landmarks;
      if (lms.length != 21) continue;

      // Map normalized [0,1] coordinates to canvas pixels based on sensor rotation
      List<Offset> pts = lms.map((lm) {
        bool isBack = lensDirection == CameraLensDirection.back;
        double mappedX = isBack ? 1.0 - lm.y : lm.y;
        double mappedY = isBack ? lm.x : 1.0 - lm.x;

        double x = mappedX * size.width;
        double y = mappedY * size.height;
        return Offset(x, y);
      }).toList();

      // Draw joints
      for (final pt in pts) {
        canvas.drawCircle(pt, 6, pointPaint);
      }

      // Draw skeleton bones (MediaPipe topology)
      const connections = [
        [0, 1], [1, 2], [2, 3], [3, 4],       // Thumb
        [0, 5], [5, 6], [6, 7], [7, 8],       // Index
        [5, 9], [9, 10], [10, 11], [11, 12],  // Middle
        [9, 13], [13, 14], [14, 15], [15, 16], // Ring
        [13, 17], [17, 18], [18, 19], [19, 20], // Pinky
        [0, 17],                               // Palm
      ];

      for (final conn in connections) {
        canvas.drawLine(pts[conn[0]], pts[conn[1]], bonePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter old) =>
      old.hands != hands;
}