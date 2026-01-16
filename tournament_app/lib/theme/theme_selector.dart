import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';
import 'theme_provider.dart';

/// A button that shows the current theme icon and opens theme selector
class ThemeSelectorButton extends StatelessWidget {
  const ThemeSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.themeProvider;

    return IconButton(
      icon: Icon(themeProvider.currentTheme.icon),
      onPressed: () => showThemeSelector(context),
      tooltip: 'Change theme',
    );
  }
}

/// Shows a bottom sheet with theme options
void showThemeSelector(BuildContext context) {
  final colors = context.colors;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.cardBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => ThemeSelectorSheet(
        scrollController: scrollController,
      ),
    ),
  );
}

/// The bottom sheet content for theme selection
class ThemeSelectorSheet extends StatelessWidget {
  final ScrollController? scrollController;

  const ThemeSelectorSheet({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.themeProvider;
    final colors = themeProvider.colors;

    return Container(
      color: colors.cardBackground,
      child: SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: colors.accent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...AppThemeType.values.map((theme) => _ThemeOption(
                  theme: theme,
                  isSelected: themeProvider.currentTheme == theme,
                  onTap: () {
                    themeProvider.setTheme(theme);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeType theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final previewColors = theme.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentLight : colors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colors.accent : colors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Theme preview
              _ThemePreview(previewColors: previewColors),
              const SizedBox(width: 16),
              // Theme info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getThemeDescription(theme),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              Icon(
                theme.icon,
                color: isSelected ? colors.accent : colors.textMuted,
                size: 28,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: colors.accent,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.dark:
        return 'Dark mode with blue accents';
      case AppThemeType.spring:
        return 'Light green nature-inspired';
      case AppThemeType.midnightMint:
        return 'Deep navy with neon mint';
      case AppThemeType.neonNight:
        return 'Dark purple with lime accents';
      case AppThemeType.duskGarden:
        return 'Soft pastels on dark canvas';
    }
  }
}

class _ThemePreview extends StatelessWidget {
  final AppColorPalette previewColors;

  const _ThemePreview({required this.previewColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: previewColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: previewColors.divider),
      ),
      child: Stack(
        children: [
          // Card preview
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: previewColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Accent preview
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: previewColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Success indicator
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: previewColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tile for use in settings screens
class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.themeProvider;
    final colors = themeProvider.colors;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.accentLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.palette,
          color: colors.accent,
        ),
      ),
      title: Text(
        'Theme',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        themeProvider.currentTheme.displayName,
        style: TextStyle(color: colors.textSecondary),
      ),
      trailing: Icon(
        themeProvider.currentTheme.icon,
        color: colors.textSecondary,
      ),
      onTap: () => showThemeSelector(context),
    );
  }
}
