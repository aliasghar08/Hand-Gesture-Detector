import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';
import 'package:hand_gesture_app/controllers/gesture_controller_base.dart';
import 'package:hand_gesture_app/utils/debug_logger.dart';

class GestureControllerManager extends BaseGestureControllerManager {
  @override
  Future<void> processCameraImage(dynamic imageOrVideo, int sensorOrientation, DeviceOrientation deviceOrientation) async {
    if (handDetector == null || isProcessing) return;
    
    // Use FrameThrottle to avoid queueing too many frames
    throttle.run(() async {
      isProcessing = true;
      try {
        final rotation = rotationForFrame(
          width: imageOrVideo.width,
          height: imageOrVideo.height,
          sensorOrientation: sensorOrientation,
          isFrontCamera: false, 
          deviceOrientation: deviceOrientation,
        );
        
        List<Hand> detectedHands = await handDetector!.detectFromCameraImage(
          imageOrVideo,
          rotation: rotation,
        );
        
        onLandmarksReceivedFromDimensions(detectedHands, imageOrVideo.width, imageOrVideo.height, sensorOrientation);
      } catch (e) {
        DebugLogger.logError('HandDetector processing (Native)', e);
      } finally {
        isProcessing = false;
      }
    });
  }
}
