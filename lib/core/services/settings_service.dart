import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import 'package:drift/drift.dart';

class SettingsService extends ChangeNotifier {
  final UzaDatabase _db;

  bool _isDarkMode = false;
  String _language = 'fr';
  bool _notificationsEnabled = true;
  bool _isLiteMode = false;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get currentLanguage => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLiteMode => _isLiteMode;

  SettingsService(this._db) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await (_db.select(
      _db.appPreferences,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    if (prefs != null) {
      _isDarkMode = prefs.isDarkMode;
      _language = prefs.language;
      _notificationsEnabled = prefs.notificationsEnabled;
      _isLiteMode = prefs.isLiteMode;
      if (prefs.biometricEnabled) {
        await (_db.update(_db.appPreferences)..where((t) => t.id.equals(1)))
            .write(const AppPreferencesCompanion(
          biometricEnabled: Value(false),
        ));
      }
      notifyListeners();
    } else {
      // First time initialization
      await _db
          .into(_db.appPreferences)
          .insertOnConflictUpdate(
            AppPreferencesCompanion.insert(
              id: const Value(1),
              isDarkMode: const Value(false),
              language: const Value('fr'),
              notificationsEnabled: const Value(true),
              isLiteMode: const Value(false),
              biometricEnabled: const Value(false),
            ),
          );
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _updateDb();
  }

  Future<void> setLanguage(String value) async {
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

  Future<void> _updateDb() async {
    await (_db.update(_db.appPreferences)..where((t) => t.id.equals(1))).write(
      AppPreferencesCompanion(
        isDarkMode: Value(_isDarkMode),
        language: Value(_language),
        notificationsEnabled: Value(_notificationsEnabled),
        isLiteMode: Value(_isLiteMode),
        biometricEnabled: const Value(false),
      ),
    );
  }
}
