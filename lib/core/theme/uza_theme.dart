import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../res/uza_colors.dart';

class UzaTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const darkSurface = Color(0xFF1E1E1E);
    const darkBackground = Color(0xFF121212);
    const darkSurfaceVariant = Color(0xFF2C2C2C);

    final primaryText = isDark ? Colors.white : UzaColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : UzaColors.textSecondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: UzaColors.primary,
      brightness: brightness,
      primary: UzaColors.primary,
      secondary: UzaColors.secondary,
      surface: isDark ? darkSurface : UzaColors.surface,
      error: UzaColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryText,
      onSurfaceVariant: secondaryText,
    );

    final baseTextTheme = GoogleFonts.outfitTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: primaryText,
      displayColor: primaryText,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkBackground : UzaColors.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: primaryText),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : UzaColors.background,
        foregroundColor: primaryText,
        iconTheme: IconThemeData(color: primaryText),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkSurface : UzaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UzaColors.radiusSm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primaryText,
        textColor: primaryText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkSurface : UzaColors.surface,
        titleTextStyle: GoogleFonts.outfit(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: secondaryText,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : UzaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UzaColors.radiusLg),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkSurface : UzaColors.surface,
        textStyle: GoogleFonts.outfit(color: primaryText, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurfaceVariant : Colors.grey[100],
        labelStyle: GoogleFonts.outfit(color: primaryText, fontSize: 13),
        side: BorderSide.none,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryText,
        unselectedLabelColor: secondaryText,
        indicatorColor: UzaColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UzaColors.radiusMd),
        ),
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
        fillColor: isDark ? darkSurfaceVariant : Colors.grey[100],
        hintStyle: GoogleFonts.outfit(color: secondaryText),
        labelStyle: GoogleFonts.outfit(color: secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UzaColors.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white24 : UzaColors.divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UzaColors.primary;
          }
          return isDark ? Colors.grey[400] : Colors.grey[300];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UzaColors.primary.withValues(alpha: 0.4);
          }
          return isDark ? Colors.grey[700] : Colors.grey[300];
        }),
      ),
    );
  }
}
