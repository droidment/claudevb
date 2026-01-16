import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';

  AppThemeType _currentTheme = AppThemeType.dark;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadTheme();
  }

  AppThemeType get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;

  ThemeData get themeData => AppTheme.getTheme(_currentTheme);
  AppColorPalette get colors => _currentTheme.palette;
  bool get isDark => _currentTheme == AppThemeType.dark;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _currentTheme = AppThemeType.values[themeIndex.clamp(0, AppThemeType.values.length - 1)];
    } catch (e) {
      _currentTheme = AppThemeType.dark;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      // Ignore storage errors
    }
  }

  void toggleTheme() {
    final nextIndex = (_currentTheme.index + 1) % AppThemeType.values.length;
    setTheme(AppThemeType.values[nextIndex]);
  }
}

/// Extension to easily access theme colors from BuildContext
extension ThemeContextExtension on BuildContext {
  ThemeProvider get themeProvider =>
      _ThemeProviderInheritedWidget.of(this);

  AppColorPalette get colors => themeProvider.colors;

  bool get isDarkTheme => themeProvider.isDark;
}

/// InheritedWidget to provide ThemeProvider down the widget tree
class _ThemeProviderInheritedWidget extends InheritedNotifier<ThemeProvider> {
  const _ThemeProviderInheritedWidget({
    required ThemeProvider themeProvider,
    required super.child,
  }) : super(notifier: themeProvider);

  static ThemeProvider of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_ThemeProviderInheritedWidget>();
    assert(widget != null, 'No ThemeProviderWidget found in context');
    return widget!.notifier!;
  }
}

/// Widget to wrap the app and provide theme
class ThemeProviderWidget extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Widget child;

  const ThemeProviderWidget({
    super.key,
    required this.themeProvider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _ThemeProviderInheritedWidget(
      themeProvider: themeProvider,
      child: child,
    );
  }
}
