import 'package:flutter/material.dart';

/// Centralized design tokens and ThemeData for the Life OS app.
/// Light theme: warm beige with orange accent.
/// Dark theme: charcoal with orange accent.

class AppTheme {
  AppTheme._();

  // ─── Shared accent ────────────────────────────────────────────────────
  static const accent = Color(0xFFE8601C);
  static const accentLight = Color(0xFFFFF0E8);

  // ─── Light palette ────────────────────────────────────────────────────
  static const _lightBg = Color(0xFFF5F0EB);
  static const _lightCard = Colors.white;
  static const _lightTextPrimary = Color(0xFF1A1A1A);
  static const _lightTextSecondary = Color(0xFF7A7A7A);
  static const _lightDivider = Color(0xFFE8E4DF);
  static const _lightNavBg = Colors.white;

  // ─── Dark palette ─────────────────────────────────────────────────────
  static const _darkBg = Color(0xFF1A1A2E);
  static const _darkCard = Color(0xFF242440);
  static const _darkTextPrimary = Color(0xFFF0F0F0);
  static const _darkTextSecondary = Color(0xFF9A9AB0);
  static const _darkDivider = Color(0xFF33334D);
  static const _darkNavBg = Color(0xFF1E1E34);

  // ─── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: ColorScheme.light(
      primary: accent,
      secondary: accent,
      surface: _lightCard,
      onPrimary: Colors.white,
      onSurface: _lightTextPrimary,
      onSurfaceVariant: _lightTextSecondary,
      outline: _lightDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBg,
      foregroundColor: _lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightNavBg,
      indicatorColor: accentLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accent, size: 24);
        }
        return const IconThemeData(color: _lightTextSecondary, size: 24);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF3E2F1C),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    dividerColor: _lightDivider,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextSecondary),
      labelLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Dark Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: _darkCard,
      onPrimary: Colors.white,
      onSurface: _darkTextPrimary,
      onSurfaceVariant: _darkTextSecondary,
      outline: _darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBg,
      foregroundColor: _darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkNavBg,
      indicatorColor: accent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accent, size: 24);
        }
        return const IconThemeData(color: _darkTextSecondary, size: 24);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    dividerColor: _darkDivider,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _darkTextPrimary),
      bodyMedium: TextStyle(color: _darkTextSecondary),
      labelLarge: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
