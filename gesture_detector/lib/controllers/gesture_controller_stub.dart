import 'package:hand_gesture_app/controllers/gesture_controller_base.dart';

/// Fallback implementation for unsupported platforms
class GestureControllerManager extends BaseGestureControllerManager {
  @override
  Future<void> processCameraImage(dynamic imageOrVideo, int sensorOrientation, dynamic deviceOrientation) async {
    throw UnsupportedError('This platform is not supported');
  }
}
