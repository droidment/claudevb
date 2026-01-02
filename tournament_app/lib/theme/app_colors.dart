import 'package:flutter/material.dart';

/// Dark theme colors - GitHub-inspired dark palette
class DarkColors {
  DarkColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color cardBackgroundLight = Color(0xFF1C2128);
  static const Color searchBackground = Color(0xFF21262D);
  static const Color divider = Color(0xFF21262D);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // Accent
  static const Color accent = Color(0xFF58A6FF);

  // Status
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);

  // Sport colors
  static const Color volleyballPrimary = Color(0xFFFF9800);
  static const Color pickleballPrimary = Color(0xFF009688);
}

/// Spring theme colors - Fresh, nature-inspired light palette
class SpringColors {
  SpringColors._();

  // Backgrounds
  static const Color background = Color(0xFFF0F7F4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundLight = Color(0xFFF8FBF9);
  static const Color searchBackground = Color(0xFFE8F5E9);
  static const Color divider = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF558B2F);
  static const Color textMuted = Color(0xFF81C784);

  // Accent
  static const Color accent = Color(0xFF4CAF50);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  // Sport colors
  static const Color volleyballPrimary = Color(0xFFFF9800);
  static const Color pickleballPrimary = Color(0xFF009688);
}

/// Abstract color palette that can be implemented by different themes
abstract class AppColorPalette {
  // Backgrounds
  Color get background;
  Color get cardBackground;
  Color get cardBackgroundLight;
  Color get searchBackground;
  Color get divider;

  // Text
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;

  // Accent
  Color get accent;

  // Status
  Color get success;
  Color get warning;
  Color get error;

  // Sport colors
  Color get volleyballPrimary;
  Color get pickleballPrimary;

  // Computed colors
  Color get accentLight => accent.withOpacity(0.2);
  Color get accentSubtle => accent.withOpacity(0.15);
  Color get successLight => success.withOpacity(0.2);
  Color get warningLight => warning.withOpacity(0.2);
  Color get errorLight => error.withOpacity(0.2);

  // Is this a dark theme?
  bool get isDark;
}

/// Dark theme implementation
class DarkColorPalette implements AppColorPalette {
  const DarkColorPalette();

  @override
  Color get background => DarkColors.background;
  @override
  Color get cardBackground => DarkColors.cardBackground;
  @override
  Color get cardBackgroundLight => DarkColors.cardBackgroundLight;
  @override
  Color get searchBackground => DarkColors.searchBackground;
  @override
  Color get divider => DarkColors.divider;

  @override
  Color get textPrimary => DarkColors.textPrimary;
  @override
  Color get textSecondary => DarkColors.textSecondary;
  @override
  Color get textMuted => DarkColors.textMuted;

  @override
  Color get accent => DarkColors.accent;

  @override
  Color get success => DarkColors.success;
  @override
  Color get warning => DarkColors.warning;
  @override
  Color get error => DarkColors.error;

  @override
  Color get volleyballPrimary => DarkColors.volleyballPrimary;
  @override
  Color get pickleballPrimary => DarkColors.pickleballPrimary;

  @override
  Color get accentLight => accent.withOpacity(0.2);
  @override
  Color get accentSubtle => accent.withOpacity(0.15);
  @override
  Color get successLight => success.withOpacity(0.2);
  @override
  Color get warningLight => warning.withOpacity(0.2);
  @override
  Color get errorLight => error.withOpacity(0.2);

  @override
  bool get isDark => true;
}

/// Spring theme implementation
class SpringColorPalette implements AppColorPalette {
  const SpringColorPalette();

  @override
  Color get background => SpringColors.background;
  @override
  Color get cardBackground => SpringColors.cardBackground;
  @override
  Color get cardBackgroundLight => SpringColors.cardBackgroundLight;
  @override
  Color get searchBackground => SpringColors.searchBackground;
  @override
  Color get divider => SpringColors.divider;

  @override
  Color get textPrimary => SpringColors.textPrimary;
  @override
  Color get textSecondary => SpringColors.textSecondary;
  @override
  Color get textMuted => SpringColors.textMuted;

  @override
  Color get accent => SpringColors.accent;

  @override
  Color get success => SpringColors.success;
  @override
  Color get warning => SpringColors.warning;
  @override
  Color get error => SpringColors.error;

  @override
  Color get volleyballPrimary => SpringColors.volleyballPrimary;
  @override
  Color get pickleballPrimary => SpringColors.pickleballPrimary;

  @override
  Color get accentLight => accent.withOpacity(0.2);
  @override
  Color get accentSubtle => accent.withOpacity(0.15);
  @override
  Color get successLight => success.withOpacity(0.2);
  @override
  Color get warningLight => warning.withOpacity(0.2);
  @override
  Color get errorLight => error.withOpacity(0.2);

  @override
  bool get isDark => false;
}
