import 'package:flutter/material.dart';

/// Spacing scale; widgets use these instead of raw numbers.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

abstract final class AppLayout {
  /// Above this width the app switches to a side navigation rail.
  static const double wideBreakpoint = 840;

  /// Content never stretches wider than this on desktop browsers.
  static const double maxContentWidth = 720;
  static const double cardRadius = 16;
}

/// Calm "command center" look: deep navy surfaces in dark mode, a teal
/// accent, and no punitive reds for missed work.
abstract final class AppTheme {
  static const _seed = Color(0xFF14B8A6);
  static const _darkSurface = Color(0xFF0B1220);

  static ThemeData light() => _build(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: 8,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
