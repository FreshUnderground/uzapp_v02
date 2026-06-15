import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Official brand colors and icons for social platforms.
abstract final class PlatformBrands {
  static const Color whatsApp = Color(0xFF25D366);
  static const Color facebook = Color(0xFF1877F2);
  static const Color tikTok = Color(0xFF010101);

  static const IconData whatsAppIcon = FontAwesomeIcons.whatsapp;
  static const IconData facebookIcon = FontAwesomeIcons.facebook;
  static const IconData tikTokIcon = FontAwesomeIcons.tiktok;

  static bool isFontAwesomeBrand(IconData icon) =>
      icon == whatsAppIcon ||
      icon == facebookIcon ||
      icon == tikTokIcon ||
      icon == FontAwesomeIcons.instagram ||
      icon == FontAwesomeIcons.youtube;
}
