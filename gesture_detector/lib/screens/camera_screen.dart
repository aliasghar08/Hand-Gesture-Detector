import 'package:flutter/material.dart';
import 'package:hand_gesture_app/core/app_strings.dart';
import 'package:hand_gesture_app/controllers/camera_controller_manager.dart';
import 'package:hand_gesture_app/controllers/gesture_controller_manager.dart';
import 'package:hand_gesture_app/widgets/camera_preview_widget.dart';
import 'package:hand_gesture_app/widgets/gesture_overlay_widget.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final GestureControllerManager _gestureControllerManager = GestureControllerManager();
  final CameraControllerManager _cameraControllerManager = CameraControllerManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    // Allow the navigation transition to complete smoothly before doing heavy init
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    
    await _gestureControllerManager.initializeModel();
    if (!mounted) return;
    
    await _cameraControllerManager.initializeCamera(_gestureControllerManager.processCameraImage);
  }

  @override
  void dispose() {
    _gestureControllerManager.dispose();
    _cameraControllerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_cameraControllerManager, _gestureControllerManager]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.appName),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _cameraControllerManager.isFlashOn ? Icons.flash_on : Icons.flash_off,
                ),
                onPressed: () {
                  _cameraControllerManager.toggleFlash();
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              CameraPreviewWidget(
                controller: _cameraControllerManager.controller,
                isInitialized: _cameraControllerManager.isInitialized,
                status: _cameraControllerManager.status,
                hands: _gestureControllerManager.hands,
              ),
              GestureOverlayWidget(
                recognizedGesture: _gestureControllerManager.recognizedGesture,
                debugInfo: _gestureControllerManager.debugInfo,
              ),
            ],
          ),
        );
      },
    );
  }
}
