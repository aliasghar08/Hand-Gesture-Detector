import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hand_gesture_app/core/app_strings.dart';

class CameraControllerManager extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  String _status = AppStrings.initialStatus;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isFlashOn => _isFlashOn;
  String get status => _status;

  Future<void> initializeCamera(Function(CameraImage, int) onImageStream) async {
    try {
      _updateStatus(AppStrings.requestingPermission);
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        _updateStatus(AppStrings.permissionDenied);
        return;
      }

      _updateStatus(AppStrings.loadingCamera);
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _updateStatus(AppStrings.noCameras);
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

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
      await _controller!.startImageStream((image) {
        onImageStream(image, sensorOrientation);
      });
    } catch (e) {
      _updateStatus("Error: $e");
    }
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
