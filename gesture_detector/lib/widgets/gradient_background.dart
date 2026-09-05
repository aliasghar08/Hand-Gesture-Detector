import 'package:flutter/material.dart';
import 'package:hand_gesture_app/core/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
      child: child,
    );
  }
}
