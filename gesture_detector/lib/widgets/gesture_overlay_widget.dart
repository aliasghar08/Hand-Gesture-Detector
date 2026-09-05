import 'package:flutter/material.dart';
import 'package:hand_gesture_app/core/app_colors.dart';

class GestureOverlayWidget extends StatelessWidget {
  final String recognizedGesture;
  final String debugInfo;

  const GestureOverlayWidget({
    super.key,
    required this.recognizedGesture,
    required this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.overlayBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              recognizedGesture,
              style: const TextStyle(
                fontSize: 32,
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              debugInfo,
              style: const TextStyle(
                color: AppColors.textLightGray,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

