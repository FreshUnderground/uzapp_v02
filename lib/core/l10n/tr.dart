import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'app_translations.dart';

/// Resolved locale from [SettingsService] without listening.
String localeOf(BuildContext context) {
  return Provider.of<SettingsService>(context, listen: false).currentLanguage;
}

/// Translate without [BuildContext] — safe in async callbacks and error handlers.
String trL(String key, String locale) =>
    AppTranslations.translate(key, locale);

/// [trf] without [BuildContext].
String trfL(String key, String locale, Map<String, String> params) {
  var text = trL(key, locale);
  for (final entry in params.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

/// Convenience accessor for app translations.
///
/// Usage: `tr(context, 'home')` → returns the localized string
/// for the current language setting.
///
/// Uses [Provider.of] with `listen: false` so it is safe in event handlers.
/// Locale rebuilds are handled by [Consumer] around [MaterialApp].
///
/// Requires [SettingsService] to be available via [Provider].
String tr(BuildContext context, String key) => trL(key, localeOf(context));

/// Libellé d'une préférence de langue (y compris `system`).
String trLanguageName(BuildContext context, String code) {
  if (code == 'system') return tr(context, 'language_system');
  return AppTranslations.languageNames[code] ?? code;
}

/// Libellé d'une préférence de thème.
String trThemeMode(BuildContext context, String mode) {
  switch (mode) {
    case 'light':
      return tr(context, 'theme_light');
    case 'dark':
      return tr(context, 'theme_dark');
    default:
      return tr(context, 'theme_system');
  }
}

/// Traduction avec paramètres `{key}` remplacés dans la chaîne.
String trf(BuildContext context, String key, Map<String, String> params) =>
    trfL(key, localeOf(context), params);
