import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

/// Draws hand landmarks and skeleton bones on top of the camera preview.
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

      // hand_detection returns absolute pixel coordinates in image space.
      // We must normalize them using imageWidth/imageHeight to [0, 1] relative to the image
      // and then project them onto the canvas size.
      final double imgW = hand.imageWidth > 0 ? hand.imageWidth.toDouble() : previewSize.width;
      final double imgH = hand.imageHeight > 0 ? hand.imageHeight.toDouble() : previewSize.height;

      List<Offset> pts = lms.map((lm) {
        double normX = lm.x / imgW;
        double normY = lm.y / imgH;

        bool isFront = lensDirection == CameraLensDirection.front;
        // On front cameras, the camera preview is often mirrored by the framework
        double finalX = isFront ? 1.0 - normX : normX;
        double finalY = normY;

        double x = finalX * size.width;
        double y = finalY * size.height;
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
  bool shouldRepaint(covariant HandLandmarkPainter old) => old.hands != hands;
}
