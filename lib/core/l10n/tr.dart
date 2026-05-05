import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'app_translations.dart';

/// Convenience accessor for app translations.
///
/// Usage: `tr(context, 'home')` → returns the localized string
/// for the current language setting.
///
/// Requires [SettingsService] to be available via [Provider].
String tr(BuildContext context, String key) {
  final locale = context.watch<SettingsService>().currentLanguage;
  return AppTranslations.translate(key, locale);
}
