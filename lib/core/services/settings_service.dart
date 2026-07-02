import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/uza_database.dart';
import '../l10n/app_translations.dart';
import 'package:drift/drift.dart';
import 'web_notification_service.dart';
import 'whatsapp_status_scheduler.dart';

class SettingsService extends ChangeNotifier {
  static const _prefThemeMode = 'theme_mode';

  final UzaDatabase _db;

  String _themeMode = 'system';
  String _language = 'system';
  bool _notificationsEnabled = true;
  bool _isLiteMode = false;
  bool _waStatusAutoEnabled = true;
  String? _userCommune;

  /// Préférence brute : `system`, `light` ou `dark`.
  String get themeModePreference => _themeMode;

  /// Préférence brute : `system`, `fr`, `en`, `ln` ou `sw`.
  String get languagePreference => _language;

  /// Langue effectivement utilisée (résout `system` → langue du téléphone).
  String get currentLanguage => AppTranslations.resolveLanguage(_language);

  String get language => currentLanguage;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale => AppTranslations.materialLocaleFor(currentLanguage);

  /// Conservé pour compatibilité UI existante.
  bool get isDarkMode => _themeMode == 'dark';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLiteMode => _isLiteMode;
  bool get waStatusAutoEnabled => _waStatusAutoEnabled;
  String? get userCommune => _userCommune;

  SettingsService(this._db) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    _waStatusAutoEnabled = sp.getBool(kPrefWaStatusEnabled) ?? true;
    _themeMode = sp.getString(_prefThemeMode) ?? '';

    final prefs = await (_db.select(
      _db.appPreferences,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    if (prefs != null) {
      if (_themeMode.isEmpty) {
        _themeMode = prefs.isDarkMode ? 'dark' : 'system';
        await sp.setString(_prefThemeMode, _themeMode);
      }
      _language = prefs.language;
      _notificationsEnabled = prefs.notificationsEnabled;
      _isLiteMode = prefs.isLiteMode;
      _userCommune = prefs.userCommune;
      if (prefs.biometricEnabled) {
        await (_db.update(_db.appPreferences)..where((t) => t.id.equals(1)))
            .write(const AppPreferencesCompanion(
          biometricEnabled: Value(false),
        ));
      }
      notifyListeners();
    } else {
      _themeMode = _themeMode.isEmpty ? 'system' : _themeMode;
      await _db.into(_db.appPreferences).insertOnConflictUpdate(
            AppPreferencesCompanion.insert(
              id: const Value(1),
              isDarkMode: const Value(false),
              language: const Value('system'),
              notificationsEnabled: const Value(true),
              isLiteMode: const Value(false),
              biometricEnabled: const Value(false),
            ),
          );
      await sp.setString(_prefThemeMode, _themeMode);
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String value) async {
    if (!['system', 'light', 'dark'].contains(value)) return;
    _themeMode = value;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefThemeMode, value);
    await _updateDb();
  }

  Future<void> toggleDarkMode(bool value) async {
    await setThemeMode(value ? 'dark' : 'light');
  }

  Future<void> setLanguage(String value) async {
    if (value != 'system' &&
        !AppTranslations.supportedLocales.contains(value)) {
      return;
    }
    _language = value;
    notifyListeners();
    await _updateDb();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _updateDb();
  }

  Future<void> toggleLiteMode(bool value) async {
    _isLiteMode = value;
    notifyListeners();
    await _updateDb();
  }

  Future<void> setUserCommune(String? commune) async {
    _userCommune = commune;
    notifyListeners();
    await (_db.update(_db.appPreferences)..where((t) => t.id.equals(1))).write(
      AppPreferencesCompanion(userCommune: Value(commune)),
    );
  }

  Future<void> toggleWaStatusAuto(bool value) async {
    _waStatusAutoEnabled = value;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(kPrefWaStatusEnabled, value);
    if (!value) {
      await WebNotificationService.syncNextReminder(null);
    }
  }

  Future<void> _updateDb() async {
    await (_db.update(_db.appPreferences)..where((t) => t.id.equals(1))).write(
      AppPreferencesCompanion(
        isDarkMode: Value(_themeMode == 'dark'),
        language: Value(_language),
        notificationsEnabled: Value(_notificationsEnabled),
        isLiteMode: Value(_isLiteMode),
        biometricEnabled: const Value(false),
      ),
    );
  }
}
