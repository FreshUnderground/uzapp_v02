import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Service for managing local notifications.
///
/// Local notifications + deep-link handling on the client.
/// Device tokens are registered server-side via [FcmService] (fcm.php).
/// Server push delivery uses FCM when FCM_SERVER_KEY is configured.
class PushNotificationService {
  static const String kArrivagesChannelId = 'uzaapp_arrivages';
  static const String kWaStatusChannelId = 'uzaapp_wa_status';

  final NotificationService? notificationService;

  PushNotificationService({this.notificationService});

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called once from main.dart to initialize local notifications.
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _initLocalNotifications();
      await requestPermissions();
    } catch (e) {
      debugPrint('Push notification initialization error: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final ios = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
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

    const arrivagesChannel = AndroidNotificationChannel(
      kArrivagesChannelId,
      'Nouveaux arrivages',
      description: 'Notifications des nouveaux arrivages et promotions',
      importance: Importance.max,
    );

    const waStatusChannel = AndroidNotificationChannel(
      kWaStatusChannelId,
      'Statuts WhatsApp',
      description:
          'Rappels quotidiens lorsque vos statuts WhatsApp sont prêts',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(arrivagesChannel);
    await androidPlugin?.createNotificationChannel(waStatusChannel);
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
  /// Expected data keys: type ('arrivage'|'product'|'shop'|'whatsapp_status'), id
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final id = int.tryParse(data['id']?.toString() ?? '');

    if (type != null && id != null) {
      notificationService?.setPendingDeepLink(type: type, id: id);
    }
  }

  /// Show a local notification directly (used by BackgroundService).
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = kArrivagesChannelId,
    int? notificationId,
  }) async {
    if (kIsWeb) return;
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

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == kWaStatusChannelId ? 'Statuts WhatsApp' : 'Nouveaux arrivages',
      channelDescription: channelId == kWaStatusChannelId
          ? 'Statuts WhatsApp quotidiens'
          : 'Notifications des nouveaux arrivages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view',
          'Voir',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await plugin.show(
      notificationId ?? title.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
  }

}
