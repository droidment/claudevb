import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Available theme types
enum AppThemeType {
  gridsterGP,
  classicBlue,
  oceanMint,
  floralGarden,
  // More themes will be added here
}

/// Extension to get theme metadata
extension AppThemeTypeExtension on AppThemeType {
  String get name {
    switch (this) {
      case AppThemeType.gridsterGP:
        return 'GridsterGP';
      case AppThemeType.classicBlue:
        return 'Classic Blue';
      case AppThemeType.oceanMint:
        return 'Ocean Mint';
      case AppThemeType.floralGarden:
        return 'Floral Garden';
    }
  }

  String get description {
    switch (this) {
      case AppThemeType.gridsterGP:
        return 'Violet & Lime branding';
      case AppThemeType.classicBlue:
        return 'Original blue theme';
      case AppThemeType.oceanMint:
        return 'Corporate mint & navy';
      case AppThemeType.floralGarden:
        return 'Soft pastel garden';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemeType.gridsterGP:
        return AppColors.violet;
      case AppThemeType.classicBlue:
        return Colors.blue;
      case AppThemeType.oceanMint:
        return const Color(0xFF002C3F); // Core Navy
      case AppThemeType.floralGarden:
        return const Color(0xFF78769C); // Benimidori Purple
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AppThemeType.gridsterGP:
        return AppColors.lime;
      case AppThemeType.classicBlue:
        return Colors.orange;
      case AppThemeType.oceanMint:
        return const Color(0xFF36ECDE); // Neon Mint
      case AppThemeType.floralGarden:
        return const Color(0xFFDB9ED3); // Chateau Rose
    }
  }
}

/// Central theme definitions
class AppThemes {
  AppThemes._();

  /// Get theme data for a specific theme type
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.gridsterGP:
        return _gridsterGPTheme();
      case AppThemeType.classicBlue:
        return _classicBlueTheme();
      case AppThemeType.oceanMint:
        return _oceanMintTheme();
      case AppThemeType.floralGarden:
        return _floralGardenTheme();
    }
  }

  /// GridsterGP theme (Violet & Lime)
  static ThemeData _gridsterGPTheme() {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.violet,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.violet,
        secondary: AppColors.lime,
        onSecondary: AppColors.black,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.black,
        tertiary: AppColors.violet,
        onTertiary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.black,
        surfaceContainerHighest: AppColors.surfaceDim,
        outline: Colors.grey.shade300,
      ),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.violet,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: BorderSide(color: AppColors.violet),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.violet, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: AppColors.violet),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondaryLight,
        selectedColor: AppColors.lime,
        labelStyle: TextStyle(color: AppColors.black),
        secondaryLabelStyle: TextStyle(color: AppColors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: AppColors.violet,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      useMaterial3: true,
    );
  }

  /// Classic Blue theme (Original)
  static ThemeData _classicBlueTheme() {
    final primaryBlue = Colors.blue.shade700;
    final secondaryOrange = Colors.orange.shade600;

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: Colors.blue.shade50,
        onPrimaryContainer: primaryBlue,
        secondary: secondaryOrange,
        onSecondary: Colors.white,
        secondaryContainer: Colors.orange.shade50,
        onSecondaryContainer: secondaryOrange,
        tertiary: primaryBlue,
        onTertiary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: Colors.grey.shade100,
        outline: Colors.grey.shade300,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: primaryBlue),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.orange.shade50,
        selectedColor: secondaryOrange,
        labelStyle: const TextStyle(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      useMaterial3: true,
    );
  }

  /// Ocean Mint theme (Neon Mint & Core Navy)
  static ThemeData _oceanMintTheme() {
    const neonMint = Color(0xFF36ECDE);
    const coreNavy = Color(0xFF002C3F);
    const softGray = Color(0xFFE6E9EC);
    const graphiteBlack = Color(0xFF2F2F2F);

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: coreNavy,
        onPrimary: Colors.white,
        primaryContainer: coreNavy.withOpacity(0.1),
        onPrimaryContainer: coreNavy,
        secondary: neonMint,
        onSecondary: graphiteBlack,
        secondaryContainer: neonMint.withOpacity(0.15),
        onSecondaryContainer: graphiteBlack,
        tertiary: neonMint,
        onTertiary: graphiteBlack,
        error: Colors.red.shade700,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: graphiteBlack,
        surfaceContainerHighest: softGray,
        outline: softGray,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: coreNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonMint,
        foregroundColor: graphiteBlack,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coreNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: coreNavy,
          side: const BorderSide(color: coreNavy),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: coreNavy,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonMint, width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: coreNavy),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: neonMint.withOpacity(0.15),
        selectedColor: neonMint,
        labelStyle: const TextStyle(color: graphiteBlack),
        secondaryLabelStyle: const TextStyle(color: graphiteBlack),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: coreNavy,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      useMaterial3: true,
    );
  }

  /// Floral Garden theme (Soft Pastels)
  static ThemeData _floralGardenTheme() {
    const galena = Color(0xFF62786D); // Sage green
    const dustStorm = Color(0xFFE1CEC0); // Warm beige
    const chateauRose = Color(0xFFDB9ED3); // Soft pink
    const laVibes = Color(0xFFEDCCE0); // Light lavender
    const benimidoriPurple = Color(0xFF78769C); // Muted purple

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: benimidoriPurple,
        onPrimary: Colors.white,
        primaryContainer: laVibes,
        onPrimaryContainer: benimidoriPurple,
        secondary: chateauRose,
        onSecondary: Colors.white,
        secondaryContainer: chateauRose.withOpacity(0.2),
        onSecondaryContainer: benimidoriPurple,
        tertiary: galena,
        onTertiary: Colors.white,
        error: Colors.red.shade400,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF4A4A4A),
        surfaceContainerHighest: dustStorm,
        outline: galena.withOpacity(0.3),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFAF8),
      appBarTheme: const AppBarTheme(
        backgroundColor: benimidoriPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: chateauRose,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: benimidoriPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: benimidoriPurple,
          side: const BorderSide(color: benimidoriPurple),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: benimidoriPurple,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: chateauRose, width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: benimidoriPurple),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: laVibes.withOpacity(0.3),
        selectedColor: chateauRose,
        labelStyle: const TextStyle(color: Color(0xFF4A4A4A)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: benimidoriPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      useMaterial3: true,
    );
  }
}
