import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';
import 'package:hand_gesture_app/widgets/hand_landmark_painter.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final String status;
  final List<Hand> hands;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.status,
    required this.hands,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null || status.startsWith('Error')) {
      return Center(
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final previewSize = controller!.value.previewSize!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Native mobile implementations often benefit from specific aspect ratio fixes
        // such as 1 / aspectRatio for portrait feeds or BoxFit.cover scaling.
        // For now, it mirrors Web behavior until custom edge-to-edge scaling is implemented.
        return Center(
          child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller!),
                CustomPaint(
                  painter: HandLandmarkPainter(
                    hands: hands,
                    previewSize: previewSize,
                    lensDirection: controller!.description.lensDirection,
                    sensorOrientation: controller!.description.sensorOrientation,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
