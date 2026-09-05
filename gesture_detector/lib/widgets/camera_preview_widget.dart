import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
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
    if (!isInitialized || controller == null) {
      return Center(
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final previewSize = controller!.value.previewSize!;
    final previewAspectRatio = previewSize.height / previewSize.width;
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Center(
      child: Transform.scale(
        scale: previewAspectRatio / deviceRatio,
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
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
      ),
    );
  }
}

