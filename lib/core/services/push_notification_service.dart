import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Service for managing local notifications.
///
/// Firebase Cloud Messaging (FCM) has been removed from this project.
/// Push notifications are handled server-side; the client only shows
/// local notifications and handles deep-link navigation from taps.
class PushNotificationService {
  final NotificationService? notificationService;

  PushNotificationService({this.notificationService});

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called once from main.dart to initialize local notifications.
  Future<void> initialize() async {
    if (kIsWeb) return; // Platform channels not available on web
    try {
      await _initLocalNotifications();
    } catch (e) {
      debugPrint('Push notification initialization error: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'uzaapp_arrivages',
      'Nouveaux arrivages',
      description: 'Notifications des nouveaux arrivages et promotions',
      importance: Importance.max,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('Notification payload parse error: $e');
      }
    }
  }

  /// Parse notification data for deep linking.
  /// Expected data keys: type ('arrivage'|'product'|'shop'), id
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final id = int.tryParse(data['id']?.toString() ?? '');

    if (type != null && id != null) {
      notificationService?.setPendingDeepLink(type: type, id: id);
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'uzaapp_arrivages',
      'Nouveaux arrivages',
      channelDescription: 'Notifications des nouveaux arrivages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Show a local notification directly (used by BackgroundService).
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Platform channels not available on web
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await plugin.initialize(initSettings);

    const androidDetails = AndroidNotificationDetails(
      'uzaapp_arrivages',
      'Nouveaux arrivages',
      channelDescription: 'Notifications des nouveaux arrivages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await plugin.show(title.hashCode, title, body, details, payload: payload);
  }
}
