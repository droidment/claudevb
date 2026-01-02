import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppThemeType {
  dark,
  spring,
}

extension AppThemeTypeExtension on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.dark:
        return 'Dark';
      case AppThemeType.spring:
        return 'Spring';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeType.dark:
        return Icons.dark_mode;
      case AppThemeType.spring:
        return Icons.local_florist;
    }
  }

  AppColorPalette get palette {
    switch (this) {
      case AppThemeType.dark:
        return const DarkColorPalette();
      case AppThemeType.spring:
        return const SpringColorPalette();
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme() {
    const colors = DarkColorPalette();
    return _buildTheme(colors);
  }

  static ThemeData springTheme() {
    const colors = SpringColorPalette();
    return _buildTheme(colors);
  }

  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.dark:
        return darkTheme();
      case AppThemeType.spring:
        return springTheme();
    }
  }

  static ThemeData _buildTheme(AppColorPalette colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: colors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: colors.isDark ? Brightness.dark : Brightness.light,
        primary: colors.accent,
        onPrimary: colors.isDark ? Colors.white : Colors.white,
        secondary: colors.accent,
        onSecondary: colors.isDark ? Colors.white : Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: colors.cardBackground,
        onSurface: colors.textPrimary,
      ),
      cardColor: colors.cardBackground,
      dividerColor: colors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.searchBackground,
        hintStyle: TextStyle(color: colors.textMuted),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textSecondary),
        bodySmall: TextStyle(color: colors.textMuted),
        labelLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: colors.textSecondary),
        labelSmall: TextStyle(color: colors.textMuted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBackground,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.cardBackgroundLight,
        labelStyle: TextStyle(color: colors.textPrimary),
        selectedColor: colors.accentLight,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.cardBackgroundLight,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentLight;
          }
          return colors.cardBackgroundLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.textMuted;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.searchBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
