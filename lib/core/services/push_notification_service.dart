import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'notification_service.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Must be a static or top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background message: ${message.messageId}');
  await _showLocalNotificationFromRemote(message);
}

Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings(
    '@drawable/ic_notification',
  );
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final notification = message.notification;

  final title = notification?.title ?? 'Nouveaux arrivages!';
  final body =
      notification?.body ?? 'Decouvrez les nouveaux arrivages sur UzaApp!';

  const androidDetails = AndroidNotificationDetails(
    'uzaapp_arrivages',
    'Nouveaux arrivages',
    channelDescription: 'Notifications des nouveaux arrivages',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const iosDetails = DarwinNotificationDetails();

  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    details,
    payload: jsonEncode(message.data),
  );
}

class PushNotificationService {
  final ApiService api;
  final NotificationService? notificationService;

  PushNotificationService({required this.api, this.notificationService});

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Called once from main.dart after Firebase initialization.
  Future<void> initialize() async {
    try {
      // Request permission (critical for iOS and Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      // Set foreground presentation options for iOS
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Initialize local notifications
      await _initLocalNotifications();

      // Get and register token
      await _refreshToken();

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle notification taps when app is in background (but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationData(initialMessage.data);
      }
    } catch (e) {
      debugPrint('FCM initialization error: $e');
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

  Future<void> _refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      }
    } catch (e) {
      debugPrint('FCM token refresh error: $e');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    _fcmToken = token;
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final shopId = prefs.getString('shop_id');

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : 'web';

      final response = await http.post(
        Uri.parse('${api.baseUrl}/fcm.php'),
        headers: {
          'X-API-Key': ApiService.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          if (userId != null) 'user_id': userId,
          if (shopId != null) 'shop_id': shopId,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token registered on server');
      } else {
        debugPrint('FCM token registration failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM token send error: $e');
    }
  }

  /// Remove token from server on logout.
  Future<void> removeTokenFromServer() async {
    if (_fcmToken == null) return;
    try {
      await http.delete(
        Uri.parse('${api.baseUrl}/fcm.php'),
        headers: {
          'X-API-Key': ApiService.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': _fcmToken}),
      );
      _fcmToken = null;
    } catch (e) {
      debugPrint('FCM token removal error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Nouveaux arrivages!',
        body:
            notification.body ?? 'Decouvrez les nouveaux arrivages sur UzaApp!',
        payload: jsonEncode(message.data),
      );
    }

    // Also add to in-app notification list
    notificationService?.addNotification(
      notification?.title ?? 'Nouveaux arrivages!',
      notification?.body ?? 'Decouvrez les nouveaux arrivages sur UzaApp!',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM Message opened app: ${message.messageId}');
    _handleNotificationData(message.data);
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
