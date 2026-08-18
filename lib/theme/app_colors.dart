import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// White / brown design tokens for the "warm ChatGPT-clone" aesthetic.
///
/// Light and dark variants expose the same semantic slots so the entire app
/// swaps cleanly between modes without re-typing hex values in widgets.
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.bubbleUser,
    required this.bubbleAssistant,
    required this.primaryBrown,
    required this.accentBrown,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  final Color background;
  final Color surface;
  final Color bubbleUser;
  final Color bubbleAssistant;
  final Color primaryBrown;
  final Color accentBrown;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  static const AppColors light = AppColors(
    background: Color(0xFFFBF8F4),
    surface: Color(0xFFFFFFFF),
    bubbleUser: Color(0xFFEFE3D6),
    bubbleAssistant: Color(0xFFF7F3EE),
    primaryBrown: Color(0xFF6F4E37),
    accentBrown: Color(0xFF8B5E3C),
    textPrimary: Color(0xFF2A211D),
    textSecondary: Color(0xFF7A6A5E),
    divider: Color(0xFFE7DCCE),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF1B1512),
    surface: Color(0xFF241C18),
    bubbleUser: Color(0xFF3A2C24),
    bubbleAssistant: Color(0xFF2A211D),
    primaryBrown: Color(0xFFC08552),
    accentBrown: Color(0xFFD9A066),
    textPrimary: Color(0xFFF5F0EA),
    textSecondary: Color(0xFFB8A99B),
    divider: Color(0xFF3A2E27),
  );

  static AppColors of(Brightness brightness) =>
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}

/// Maps [AppColors] onto [ColorScheme] + Material surfaces so widgets can
/// reference Theme.of(context) uniformly while staying on-brand.
class AppColorScheme {
  const AppColorScheme._();

  static ColorScheme fromAppColors(AppColors c) {
    return ColorScheme(
      brightness: c == AppColors.dark ? Brightness.dark : Brightness.light,
      primary: c.primaryBrown,
      onPrimary: c == AppColors.dark ? const Color(0xFF1B1512) : Colors.white,
      secondary: c.accentBrown,
      onSecondary: c.background,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.bubbleAssistant,
      outline: c.divider,
      outlineVariant: c.divider,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      inversePrimary: c.accentBrown,
    );
  }

  /// System UI chrome (status/navigation bar tinting).
  static SystemUiOverlayStyle overlayStyle(AppColors c) {
    final isDark = c == AppColors.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: c.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }
}