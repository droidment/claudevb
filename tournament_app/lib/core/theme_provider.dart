import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

/// Manages the app's theme state and persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  AppThemeType _currentTheme = AppThemeType.gridsterGP;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadTheme();
  }

  /// Current selected theme type
  AppThemeType get currentTheme => _currentTheme;

  /// Whether the provider has loaded the saved theme
  bool get isInitialized => _isInitialized;

  /// Get the MaterialTheme data for the current theme
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);

  /// Load the saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);

      if (themeName != null) {
        _currentTheme = AppThemeType.values.firstWhere(
          (theme) => theme.toString() == themeName,
          orElse: () => AppThemeType.gridsterGP,
        );
      }
    } catch (e) {
      // If loading fails, use default theme
      _currentTheme = AppThemeType.gridsterGP;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change the current theme and save to preferences
  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.toString());
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Reset to default theme
  Future<void> resetTheme() async {
    await setTheme(AppThemeType.gridsterGP);
  }
}
