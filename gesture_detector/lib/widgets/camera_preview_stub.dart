import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

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
    return const Center(child: Text('Unsupported Platform'));
  }
}
