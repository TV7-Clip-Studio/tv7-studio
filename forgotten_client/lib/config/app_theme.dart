import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tv7_colors.dart';

class MidnightTheme {
  static ThemeData get themeData {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: TV7Colors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: TV7Colors.primary,
        secondary: TV7Colors.secondary,
        surface: TV7Colors.bgSurface,
        error: TV7Colors.error,
        tertiary: TV7Colors.amber,
        onPrimary: TV7Colors.bgPrimary, // Dark text on cyan
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.instrumentSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      cardTheme: CardThemeData(
        color: TV7Colors.bgSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: TV7Colors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: TV7Colors.bgSecondary,
        elevation: 0,
        titleTextStyle: GoogleFonts.instrumentSans(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TV7Colors.primary,
          foregroundColor: TV7Colors.bgPrimary,
          elevation: 0,
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TV7Colors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TV7Colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TV7Colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TV7Colors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: TV7Colors.textSecondary),
        hintStyle: const TextStyle(color: TV7Colors.textTertiary),
      ),
    );
  }
}
