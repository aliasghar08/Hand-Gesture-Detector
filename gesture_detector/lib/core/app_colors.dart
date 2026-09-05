import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Colors.blue;
  static const Color primaryPurple = Colors.purple;
  static const Color overlayBackground = Colors.black54;
  static const Color textWhite = Colors.white;
  static const Color textLightGray = Colors.white70;

  static const Gradient homeGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
