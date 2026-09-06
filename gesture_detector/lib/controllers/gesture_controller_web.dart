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
        // On web, the object is an HTMLVideoElement. We use dynamic dispatch to call detectFromVideo
        // because detectFromVideo is only defined on the web version of HandDetector.
        dynamic detector = handDetector;
        List<Hand> detectedHands = await detector.detectFromVideo(imageOrVideo);
        
        // No image dimensions for video easily without DOM, but we can fake it or get it from the video element
        final width = (imageOrVideo.videoWidth as num?)?.toInt() ?? 640;
        final height = (imageOrVideo.videoHeight as num?)?.toInt() ?? 480;
        
        onLandmarksReceivedFromDimensions(detectedHands, width, height, sensorOrientation);
      } catch (e) {
        DebugLogger.logError('HandDetector processing (Web)', e);
      } finally {
        isProcessing = false;
      }
    });
  }
}
