import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../res/uza_colors.dart';

class UzaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: UzaColors.primary,
        primary: UzaColors.primary,
        secondary: UzaColors.secondary,
        surface: UzaColors.surface,
        background: UzaColors.background,
        error: UzaColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: UzaColors.textPrimary,
        onBackground: UzaColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: UzaColors.textPrimary,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: UzaColors.textPrimary,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: UzaColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: UzaColors.textSecondary,
          fontSize: 14,
        ),
      ).apply(
        fontFamily: GoogleFonts.outfit().fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: UzaColors.background,
        foregroundColor: UzaColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UzaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
