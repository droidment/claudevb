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

/// Midnight Mint theme colors - Ocean corporate dark palette
class MidnightMintColors {
  MidnightMintColors._();

  // Backgrounds - Based on Core Navy (#00203F)
  static const Color background = Color(0xFF00203F);
  static const Color cardBackground = Color(0xFF002C4F);
  static const Color cardBackgroundLight = Color(0xFF003A5F);
  static const Color searchBackground = Color(0xFF004570);
  static const Color divider = Color(0xFF004570);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE6E9EC);  // Soft Gray
  static const Color textMuted = Color(0xFF8BA3B5);

  // Accent - Neon Mint (#36ECDE)
  static const Color accent = Color(0xFF36ECDE);

  // Status
  static const Color success = Color(0xFF36ECDE);
  static const Color warning = Color(0xFFFFD54F);
  static const Color error = Color(0xFFFF6B6B);

  // Sport colors
  static const Color volleyballPrimary = Color(0xFF36ECDE);
  static const Color pickleballPrimary = Color(0xFF4DD0E1);
}

/// Neon Night theme colors - GridsterGP dark palette
class NeonNightColors {
  NeonNightColors._();

  // Backgrounds - Based on Black (#000000)
  static const Color background = Color(0xFF0A0A0A);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color cardBackgroundLight = Color(0xFF25253A);
  static const Color searchBackground = Color(0xFF2D2D44);
  static const Color divider = Color(0xFF3D3D5C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D0);
  static const Color textMuted = Color(0xFF7A7A99);

  // Accent - Violet (#7D39EB)
  static const Color accent = Color(0xFF7D39EB);
  static const Color accentSecondary = Color(0xFFC6FF33);  // Lime

  // Status
  static const Color success = Color(0xFFC6FF33);  // Lime for success
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF5757);

  // Sport colors
  static const Color volleyballPrimary = Color(0xFFC6FF33);  // Lime
  static const Color pickleballPrimary = Color(0xFF7D39EB);  // Violet
}

/// Dusk Garden theme colors - Floral Garden dark palette
class DuskGardenColors {
  DuskGardenColors._();

  // Backgrounds - Based on Benimidori Purple and Galena
  static const Color background = Color(0xFF1E1D2A);
  static const Color cardBackground = Color(0xFF2A2838);
  static const Color cardBackgroundLight = Color(0xFF363445);
  static const Color searchBackground = Color(0xFF403E52);
  static const Color divider = Color(0xFF4A485C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFEDCCE0);  // La Vibes
  static const Color textMuted = Color(0xFF9E9CAB);

  // Accent - Chateau Rose (#DB9ED3)
  static const Color accent = Color(0xFFDB9ED3);

  // Status
  static const Color success = Color(0xFF62786D);  // Galena green
  static const Color warning = Color(0xFFE1CEC0);  // Dust Storm
  static const Color error = Color(0xFFE57373);

  // Sport colors
  static const Color volleyballPrimary = Color(0xFFDB9ED3);  // Chateau Rose
  static const Color pickleballPrimary = Color(0xFF78769C);  // Benimidori Purple
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

/// Midnight Mint theme implementation - Ocean corporate dark
class MidnightMintColorPalette implements AppColorPalette {
  const MidnightMintColorPalette();

  @override
  Color get background => MidnightMintColors.background;
  @override
  Color get cardBackground => MidnightMintColors.cardBackground;
  @override
  Color get cardBackgroundLight => MidnightMintColors.cardBackgroundLight;
  @override
  Color get searchBackground => MidnightMintColors.searchBackground;
  @override
  Color get divider => MidnightMintColors.divider;

  @override
  Color get textPrimary => MidnightMintColors.textPrimary;
  @override
  Color get textSecondary => MidnightMintColors.textSecondary;
  @override
  Color get textMuted => MidnightMintColors.textMuted;

  @override
  Color get accent => MidnightMintColors.accent;

  @override
  Color get success => MidnightMintColors.success;
  @override
  Color get warning => MidnightMintColors.warning;
  @override
  Color get error => MidnightMintColors.error;

  @override
  Color get volleyballPrimary => MidnightMintColors.volleyballPrimary;
  @override
  Color get pickleballPrimary => MidnightMintColors.pickleballPrimary;

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

/// Neon Night theme implementation - GridsterGP dark
class NeonNightColorPalette implements AppColorPalette {
  const NeonNightColorPalette();

  @override
  Color get background => NeonNightColors.background;
  @override
  Color get cardBackground => NeonNightColors.cardBackground;
  @override
  Color get cardBackgroundLight => NeonNightColors.cardBackgroundLight;
  @override
  Color get searchBackground => NeonNightColors.searchBackground;
  @override
  Color get divider => NeonNightColors.divider;

  @override
  Color get textPrimary => NeonNightColors.textPrimary;
  @override
  Color get textSecondary => NeonNightColors.textSecondary;
  @override
  Color get textMuted => NeonNightColors.textMuted;

  @override
  Color get accent => NeonNightColors.accent;

  @override
  Color get success => NeonNightColors.success;
  @override
  Color get warning => NeonNightColors.warning;
  @override
  Color get error => NeonNightColors.error;

  @override
  Color get volleyballPrimary => NeonNightColors.volleyballPrimary;
  @override
  Color get pickleballPrimary => NeonNightColors.pickleballPrimary;

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

/// Dusk Garden theme implementation - Floral Garden dark
class DuskGardenColorPalette implements AppColorPalette {
  const DuskGardenColorPalette();

  @override
  Color get background => DuskGardenColors.background;
  @override
  Color get cardBackground => DuskGardenColors.cardBackground;
  @override
  Color get cardBackgroundLight => DuskGardenColors.cardBackgroundLight;
  @override
  Color get searchBackground => DuskGardenColors.searchBackground;
  @override
  Color get divider => DuskGardenColors.divider;

  @override
  Color get textPrimary => DuskGardenColors.textPrimary;
  @override
  Color get textSecondary => DuskGardenColors.textSecondary;
  @override
  Color get textMuted => DuskGardenColors.textMuted;

  @override
  Color get accent => DuskGardenColors.accent;

  @override
  Color get success => DuskGardenColors.success;
  @override
  Color get warning => DuskGardenColors.warning;
  @override
  Color get error => DuskGardenColors.error;

  @override
  Color get volleyballPrimary => DuskGardenColors.volleyballPrimary;
  @override
  Color get pickleballPrimary => DuskGardenColors.pickleballPrimary;

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
