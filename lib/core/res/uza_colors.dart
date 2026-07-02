import 'package:flutter/material.dart';

class UzaColors {
  static const Color primary = Color(0xFFFE3E00);
  static const Color secondary = Color(0xFF019C94);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color error = Colors.redAccent;
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Texte principal — blanc en mode sombre, noir en mode clair.
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Texte secondaire — adapté au thème actif.
  static Color onSurfaceSecondary(BuildContext context) => isDark(context)
      ? Colors.white70
      : textSecondary;

  /// Fond d'écran selon le thème.
  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Surface de carte / composant selon le thème.
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Variante de surface (champs, puces, etc.).
  static Color surfaceVariantOf(BuildContext context) => isDark(context)
      ? const Color(0xFF2C2C2C)
      : surfaceVariant;

  static Color glassOverlay(BuildContext context, {double alpha = 0.85}) {
    return Theme.of(context).colorScheme.surface.withValues(alpha: alpha);
  }

  /// Couleurs shimmer pour les squelettes de chargement.
  static ({Color base, Color highlight, Color container}) shimmerOf(
    BuildContext context,
  ) {
    final dark = isDark(context);
    return (
      base: dark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      highlight: dark ? const Color(0xFF3A3A3A) : Colors.white,
      container: dark ? const Color(0xFF1E1E1E) : Colors.white,
    );
  }
}
