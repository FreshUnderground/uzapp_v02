import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Records anonymous platform opens and visits on the server.
class PlatformAnalyticsService {
  static const _visitorIdKey = 'platform_visitor_id';
  static const _lastResumeKey = 'platform_last_resume_logged';
  static const _resumeCooldown = Duration(minutes: 30);

  static bool _openLoggedThisSession = false;
  static bool _webVisitLoggedThisSession = false;

  static String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  static Future<String> _visitorId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_visitorIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final id =
        '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
        '${random.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0')}';
    await prefs.setString(_visitorIdKey, id);
    return id;
  }

  static Future<void> trackAppOpen(
    ApiService api, {
    String? userPhone,
  }) async {
    if (_openLoggedThisSession) return;
    _openLoggedThisSession = true;

    final eventType = kIsWeb ? 'web_visit' : 'app_open';
    if (kIsWeb && _webVisitLoggedThisSession) return;
    if (kIsWeb) _webVisitLoggedThisSession = true;

    await _send(api, eventType, userPhone: userPhone);
  }

  static Future<void> trackSessionResume(
    ApiService api, {
    String? userPhone,
  }) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_lastResumeKey);
    if (lastRaw != null) {
      final last = DateTime.tryParse(lastRaw);
      if (last != null &&
          DateTime.now().difference(last) < _resumeCooldown) {
        return;
      }
    }

    final ok = await _send(api, 'session_resume', userPhone: userPhone);
    if (ok) {
      await prefs.setString(
        _lastResumeKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  static Future<bool> _send(
    ApiService api,
    String eventType, {
    String? userPhone,
  }) async {
    try {
      final visitorId = await _visitorId();
      return await api.trackPlatformVisit(
        eventType: eventType,
        platform: _platformName(),
        visitorId: visitorId,
        userPhone: userPhone,
      );
    } catch (e) {
      debugPrint('PlatformAnalyticsService: $e');
      return false;
    }
  }
}
