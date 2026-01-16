import 'package:flutter/material.dart';

/// App color constants based on the GridsterGP color theme
///
/// Color Palette:
/// - Black: #000000 (Primary text, dark backgrounds)
/// - Violet: #7D39EB (Primary brand color)
/// - Lime: #C6FF33 (Secondary accent color)
/// - White: #FFFFFF (Light backgrounds, text on dark)
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color violet = Color(0xFF7D39EB);
  static const Color lime = Color(0xFFC6FF33);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Primary Colors
  static const Color primary = violet;
  static const Color secondary = lime;

  // Surface Colors
  static const Color surface = white;
  static const Color surfaceDim = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = black;
  static const Color textOnPrimary = white;
  static const Color textOnSecondary = black;

  // Utility Colors
  static Color primaryLight = violet.withOpacity(0.2);
  static Color secondaryLight = lime.withOpacity(0.2);

  // Status Colors (can be customized as needed)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
