import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Temas do app: claro, escuro e as variantes de alto contraste de cada um.
abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) =>
      _build(Brightness.light, highContrast: highContrast);

  static ThemeData dark({bool highContrast = false}) =>
      _build(Brightness.dark, highContrast: highContrast);

  static ThemeData _build(Brightness brightness, {required bool highContrast}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      side: highContrast
          ? BorderSide(color: scheme.outline, width: 1.5)
          : BorderSide.none,
    );
    const buttonSize = Size(
      AppSpacing.minTouchTarget,
      AppSpacing.minTouchTarget,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: shape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: buttonSize),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius / 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
      extensions: [
        brightness == Brightness.dark
            ? AppColors.severityDark
            : AppColors.severityLight,
      ],
    );
  }
}
