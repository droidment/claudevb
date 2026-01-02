import 'package:flutter/material.dart';

/// App-wide dark theme colors used across all screens
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color cardBackgroundLight = Color(0xFF1C2128);
  static const Color searchBackground = Color(0xFF21262D);
  static const Color divider = Color(0xFF21262D);

  // Accent colors
  static const Color accent = Color(0xFF58A6FF);
  static const Color accentLight = Color(0xFF79B8FF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // Status colors
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Sport-specific colors
  static const Color volleyballAccent = Color(0xFFFF8C00); // Orange
  static const Color pickleballAccent = Color(0xFF00897B); // Teal
}
