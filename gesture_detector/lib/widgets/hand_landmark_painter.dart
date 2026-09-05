import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

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
  bool shouldRepaint(covariant HandLandmarkPainter old) => old.hands != hands;
}
