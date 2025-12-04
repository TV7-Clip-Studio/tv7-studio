import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MidnightTheme {
  static const _bgPrimary = Color(0xFF0F1419);
  static const _bgSurface = Color(0xFF1F2937);
  static const _accentCyan = Color(0xFF00E5FF);
  static const _accentViolet = Color(0xFF7A5CFF);
  static const _accentAmber = Color(0xFFF59E0B);
  static const _errorRed = Color(0xFFEF4444); // Standard red, slightly warmer

  static ThemeData get themeData {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: _bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: _accentCyan,
        secondary: _accentViolet,
        surface: _bgSurface,
        error: _errorRed,
        tertiary: _accentAmber,
        onPrimary: _bgPrimary, // Dark text on cyan
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.instrumentSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      cardTheme: CardThemeData(
        color: _bgSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF374151)), // tv7.border
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161B22), // tv7.bgSecondary
        elevation: 0,
        titleTextStyle: GoogleFonts.instrumentSans(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentCyan,
          foregroundColor: _bgPrimary,
          elevation: 0,
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accentCyan, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)), // Slate 400
        hintStyle: const TextStyle(color: Color(0xFF6B7280)), // Slate 500
      ),
    );
  }
}
