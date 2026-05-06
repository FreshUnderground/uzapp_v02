import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'push_notification_service.dart';

/// Task identifiers.
const String _kTaskCheckNewArrivages = 'checkNewArrivages';
const String _kTaskInactivityReminder = 'inactivityReminder';

/// Initialize and register background tasks.
class BackgroundService {
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task: check for new arrivages every 2 hours
    Workmanager().registerPeriodicTask(
      _kTaskCheckNewArrivages,
      _kTaskCheckNewArrivages,
      frequency: const Duration(hours: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    // Register periodic task: inactivity reminder every 6 hours
    Workmanager().registerPeriodicTask(
      _kTaskInactivityReminder,
      _kTaskInactivityReminder,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// Cancel all background tasks.
  static void cancelAll() {
    Workmanager().cancelAll();
    _isInitialized = false;
  }
}

/// Entry-point for background task execution.
/// Must be a top-level or static function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task executed: $task');

    try {
      switch (task) {
        case _kTaskCheckNewArrivages:
          await _checkNewArrivages();
          break;
        case _kTaskInactivityReminder:
          await _inactivityReminder();
          break;
        default:
          debugPrint('Unknown background task: $task');
      }
    } catch (e) {
      debugPrint('Background task error ($task): $e');
    }

    return true;
  });
}

Future<void> _checkNewArrivages() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString('last_arrivage_check');
    final lastCheck = lastCheckStr != null
        ? DateTime.tryParse(lastCheckStr)
        : null;

    // For simplicity, we show a generic notification.
    // In production this could query the server for new stories
    // from followed shops and only notify if there are new ones.
    final now = DateTime.now();

    // Only notify if we haven't checked in the last hour (avoid duplicates)
    if (lastCheck == null || now.difference(lastCheck).inHours >= 1) {
      await PushNotificationService.showLocalNotification(
        title: 'Nouveaux arrivages!',
        body: 'Decouvrez les nouveaux arrivages sur UzaApp!',
      );
      await prefs.setString('last_arrivage_check', now.toIso8601String());
    }
  } catch (e) {
    debugPrint('checkNewArrivages error: $e');
  }
}

Future<void> _inactivityReminder() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenStr = prefs.getString('last_app_open');
    final lastOpen = lastOpenStr != null
        ? DateTime.tryParse(lastOpenStr)
        : null;

    final now = DateTime.now();

    if (lastOpen == null || now.difference(lastOpen).inHours >= 6) {
      await PushNotificationService.showLocalNotification(
        title: 'Nouveaux arrivages!',
        body: 'Decouvrez les nouveaux arrivages sur UzaApp!',
      );
    }
  } catch (e) {
    debugPrint('inactivityReminder error: $e');
  }
}
