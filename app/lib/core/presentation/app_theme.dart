import 'package:flutter/material.dart';

/// Explicit light/dark tokens for the approved visual direction.
///
/// Contrast targets: normal text >= 4.5:1, large text >= 3:1, meaningful
/// non-text controls >= 3:1. Touch targets: 44 pt iOS / 48 dp Android.
class AppTheme {
  const AppTheme._();

  static const Color lightBackground = Color(0xFFFDFBF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1F5C3A);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1B1B1B);
  static const Color lightMuted = Color(0xFF4A4A4A);
  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOutline = Color(0xFF6B6B6B);

  static const Color darkBackground = Color(0xFF121412);
  static const Color darkSurface = Color(0xFF1E211E);
  static const Color darkPrimary = Color(0xFF9FD6B4);
  static const Color darkOnPrimary = Color(0xFF00391F);
  static const Color darkText = Color(0xFFF2F2F2);
  static const Color darkMuted = Color(0xFFC6C6C6);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOutline = Color(0xFF9A9A9A);

  static const double iosMinTarget = 44;
  static const double androidMinTarget = 48;

  static double minTargetFor(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? iosMinTarget : androidMinTarget;

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: lightBackground,
        surface: lightSurface,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        text: lightText,
        muted: lightMuted,
        error: lightError,
        outline: lightOutline,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        text: darkText,
        muted: darkMuted,
        error: darkError,
        outline: darkOutline,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color onPrimary,
    required Color text,
    required Color muted,
    required Color error,
    required Color outline,
  }) {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: surface,
      onSurface: text,
      error: error,
      onError: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF690005),
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: base,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: outline.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        textColor: text,
        iconColor: muted,
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: text,
            displayColor: text,
          ),
    );
  }
}
