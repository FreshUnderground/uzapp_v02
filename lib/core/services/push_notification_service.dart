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
  /// v2 channel — Android locks importance at first creation; new id upgrades delivery.
  static const String kWaStatusChannelId = 'uzaapp_wa_status_v2';

  static FlutterLocalNotificationsPlugin? _sharedPlugin;
  static NotificationService? _deepLinkHandler;
  static bool Function()? _appNotificationsEnabled;
  static Future<void>? _ensureReadyFuture;
  static bool _permissionsRequested = false;

  /// Initialized plugin instance (null until [ensureReady] completes).
  static FlutterLocalNotificationsPlugin? get plugin => _sharedPlugin;

  final NotificationService? notificationService;

  PushNotificationService({this.notificationService});

  /// Wire in-app deep-link routing after services start (idempotent).
  static void attachDeepLinkHandler(NotificationService? handler) {
    _deepLinkHandler = handler;
  }

  /// In-app settings toggle (SettingsService.notificationsEnabled).
  static void attachNotificationsGate(bool Function() gate) {
    _appNotificationsEnabled = gate;
  }

  /// Idempotent bootstrap — safe from main isolate and Workmanager background.
  static Future<void> ensureReady({bool requestPermission = true}) async {
    if (kIsWeb) return;

    if (_sharedPlugin != null) {
      if (requestPermission) {
        await requestOsPermissions();
      }
      return;
    }

    _ensureReadyFuture ??= _bootstrap(requestPermission: requestPermission);
    try {
      await _ensureReadyFuture;
    } catch (e) {
      _ensureReadyFuture = null;
      rethrow;
    }
  }

  static Future<void> _bootstrap({required bool requestPermission}) async {
    final plugin = FlutterLocalNotificationsPlugin();

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

    final initialized = await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    if (initialized != true) {
      throw StateError('flutter_local_notifications failed to initialize');
    }
    _sharedPlugin = plugin;

    const arrivagesChannel = AndroidNotificationChannel(
      kArrivagesChannelId,
      'Nouveaux arrivages',
      description: 'Notifications des nouveaux arrivages et promotions',
      importance: Importance.max,
    );

    const waStatusChannel = AndroidNotificationChannel(
      kWaStatusChannelId,
      'Statuts WhatsApp',
      description: 'Statuts WhatsApp, images et vidéos TikTok prêtes',
      importance: Importance.max,
    );

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(arrivagesChannel);
    await androidPlugin?.createNotificationChannel(waStatusChannel);

    if (requestPermission) {
      await requestOsPermissions();
    }

    debugPrint('PushNotificationService: ready');
  }

  /// Request OS permissions once the Activity is visible (call after first frame).
  static Future<void> requestOsPermissions() async {
    if (kIsWeb || _permissionsRequested) return;
    _permissionsRequested = true;

    await ensureReady(requestPermission: false);

    final plugin = _sharedPlugin;
    if (plugin == null) return;

    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      try {
        await android.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('PushNotificationService: exact alarm permission: $e');
      }
    }
  }

  /// Called once from main.dart after [NotificationService] exists.
  Future<void> initialize() async {
    attachDeepLinkHandler(notificationService);
    await ensureReady(requestPermission: false);
  }

  Future<void> requestPermissions() async {
    await requestOsPermissions();
    await ensureNotificationsEnabled();
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data['type']?.toString();
      final id = int.tryParse(data['id']?.toString() ?? '');
      if (type != null && id != null) {
        _deepLinkHandler?.setPendingDeepLink(type: type, id: id);
      }
    } catch (e) {
      debugPrint('Notification payload parse error: $e');
    }
  }

  /// Requests OS permission if needed. Returns false when notifications are blocked.
  static Future<bool> ensureNotificationsEnabled() async {
    if (kIsWeb) return false;

    await ensureReady(requestPermission: false);

    final android = _sharedPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      var enabled = await android.areNotificationsEnabled();
      if (enabled != true) {
        _permissionsRequested = false;
        await requestOsPermissions();
        enabled = await android.areNotificationsEnabled();
      }
      return enabled ?? false;
    }

    final ios = _sharedPlugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Show a notification in the phone system tray (not the in-app bell).
  /// Returns false when the notification could not be shown.
  static Future<bool> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = kArrivagesChannelId,
    int? notificationId,
  }) async {
    if (kIsWeb) return false;

    if (_appNotificationsEnabled != null && !_appNotificationsEnabled!()) {
      debugPrint('PushNotificationService: disabled in app settings');
      return false;
    }

    await ensureReady(requestPermission: false);

    final plugin = _sharedPlugin;
    if (plugin == null) {
      debugPrint('PushNotificationService: plugin not initialized, skip show');
      return false;
    }

    final allowed = await ensureNotificationsEnabled();
    if (!allowed) {
      debugPrint('PushNotificationService: notifications disabled by user');
      return false;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == kWaStatusChannelId ? 'Statuts WhatsApp' : 'Nouveaux arrivages',
      channelDescription: channelId == kWaStatusChannelId
          ? 'Statuts WhatsApp et génération d\'images'
          : 'Produits, arrivages et annonces UzaApp',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await plugin.show(
        notificationId ?? title.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
      debugPrint('PushNotificationService: shown "$title"');
      return true;
    } catch (e, st) {
      debugPrint('PushNotificationService: show failed: $e\n$st');
      return false;
    }
  }

  /// @deprecated Use [showSystemNotification].
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = kArrivagesChannelId,
    int? notificationId,
  }) async {
    await showSystemNotification(
      title: title,
      body: body,
      payload: payload,
      channelId: channelId,
      notificationId: notificationId,
    );
  }
}
