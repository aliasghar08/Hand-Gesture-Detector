import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hand_gesture_app/core/app_strings.dart';
import 'package:hand_gesture_app/helpers/web_camera_helper.dart';

class CameraControllerManager extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  String _status = AppStrings.initialStatus;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isFlashOn => _isFlashOn;
  String get status => _status;
  DeviceOrientation get deviceOrientation => _controller?.value.deviceOrientation ?? DeviceOrientation.portraitUp;

  Future<void> initializeCamera(Function(dynamic, int, DeviceOrientation) onImageStream) async {
    try {
      if (!kIsWeb) {
        _updateStatus(AppStrings.requestingPermission);
        final status = await Permission.camera.request();

        if (!status.isGranted) {
          _updateStatus(AppStrings.permissionDenied);
          return;
        }
      }

      _updateStatus(AppStrings.loadingCamera);
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _updateStatus(AppStrings.noCameras);
        return;
      }
      
      for (var c in cameras) {
        debugPrint("Found camera: ${c.name}, lens: ${c.lensDirection}");
      }

      CameraDescription? selectedCamera;
      
      try {
        selectedCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      } catch (e) {
        // Front not found
      }
      
      if (selectedCamera == null && cameras.isNotEmpty) {
        // Fallback: try to find a camera that isn't an IR/Depth camera
        try {
          selectedCamera = cameras.firstWhere(
            (c) => !c.name.toLowerCase().contains("ir ") && 
                   !c.name.toLowerCase().contains("depth") &&
                   !c.name.toLowerCase().contains("infrared")
          );
        } catch (e) {
          selectedCamera = cameras.last;
        }
      }
      
      final camera = selectedCamera ?? cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _updateStatus(AppStrings.ready);
      notifyListeners();

      final sensorOrientation = _controller!.description.sensorOrientation;
      
      if (kIsWeb) {
        importHelperAndStart(onImageStream, sensorOrientation, deviceOrientation);
      } else {
        await _controller!.startImageStream((image) {
          onImageStream(image, sensorOrientation, deviceOrientation);
        });
      }
    } catch (e) {
      _updateStatus("Error: $e");
    }
  }

  void importHelperAndStart(Function onImageStream, int sensorOrientation, DeviceOrientation deviceOrientation) {
    WebCameraHelper.startWebCameraStream((image) {
      onImageStream(image, sensorOrientation, deviceOrientation);
    });
  }

  void _updateStatus(String msg) {
    _status = msg;
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      _updateStatus("Error toggling flash: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
