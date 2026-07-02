import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/local/uza_database.dart';
import '../models/product_update_type.dart';
import 'platform_system_notifier.dart';
import 'push_notification_service.dart';

const String _kPrefScheduledDay = 'daily_engagement_scheduled_day';
const String _kPrefSlotsActive = 'daily_engagement_slots_active';
const String _kPrefSlot1Hour = 'daily_engagement_slot1_hour';
const String _kPrefSlot1Minute = 'daily_engagement_slot1_minute';
const String _kPrefSlot2Hour = 'daily_engagement_slot2_hour';
const String _kPrefSlot2Minute = 'daily_engagement_slot2_minute';
const String _kPrefMsg1Title = 'daily_engagement_msg1_title';
const String _kPrefMsg1Body = 'daily_engagement_msg1_body';
const String _kPrefMsg1Payload = 'daily_engagement_msg1_payload';
const String _kPrefMsg2Title = 'daily_engagement_msg2_title';
const String _kPrefMsg2Body = 'daily_engagement_msg2_body';
const String _kPrefMsg2Payload = 'daily_engagement_msg2_payload';
const String _kPrefSlot1Fired = 'daily_engagement_slot1_fired';
const String _kPrefSlot2Fired = 'daily_engagement_slot2_fired';

const int _kNotificationId1 = 8101;
const int _kNotificationId2 = 8102;

class _EngagementMessage {
  final String title;
  final String body;
  final String payload;

  const _EngagementMessage({
    required this.title,
    required this.body,
    required this.payload,
  });
}

/// Plans 2 engagement notifications per day at different random times.
/// Replanned once per day on first app open (or via background worker).
class DailyEngagementScheduler {
  static bool _tzInitialized = false;
  static final Random _rng = Random();
  static final List<Timer> _webTimers = [];

  /// Call on app open / resume and from background workers.
  static Future<void> planOnAppOpen([UzaDatabase? database]) async {
    if (!kIsWeb) {
      await _ensureTimezones();
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dayKey(DateTime.now());

    if (prefs.getString(_kPrefScheduledDay) != todayKey) {
      await _planTodaySlots(prefs, todayKey);
      await prefs.setBool(_kPrefSlot1Fired, false);
      await prefs.setBool(_kPrefSlot2Fired, false);
    }

    if (prefs.getString(_kPrefScheduledDay) == todayKey &&
        prefs.getBool(_kPrefSlotsActive) == true) {
      if (kIsWeb) {
        await _fireDueWebSlots(prefs);
        _armWebTimers(prefs);
      } else {
        await _fireDueMobileSlots(prefs);
      }
      return;
    }

    final db = database ?? UzaDatabase();
    final messages = await _buildEngagementMessages(db);

    await _persistMessages(prefs, messages);

    if (kIsWeb) {
      await _scheduleWebSlots(prefs, messages);
    } else {
      await _schedulePendingSlots(prefs, messages);
    }

    await prefs.setBool(_kPrefSlotsActive, true);

    debugPrint(
      'DailyEngagementScheduler: planned $todayKey — '
      '"${messages[0].title}" & "${messages[1].title}"',
    );
  }

  static Future<void> _ensureTimezones() async {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    // Etc/GMT signs are inverted relative to UTC offsets.
    final etcName = 'Etc/GMT${offsetHours >= 0 ? '-' : '+'}${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(etcName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _tzInitialized = true;
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Future<void> _planTodaySlots(
    SharedPreferences prefs,
    String todayKey,
  ) async {
    final now = DateTime.now();

    int hour1 = 8 + _rng.nextInt(6);
    int minute1 = _rng.nextInt(60);
    int hour2 = hour1 + 3 + _rng.nextInt(5);
    int minute2 = _rng.nextInt(60);

    if (hour2 > 21) {
      hour2 = 21;
      minute2 = _rng.nextInt(60);
    }
    if (hour2 < hour1 + 3) {
      hour2 = (hour1 + 3).clamp(0, 21);
    }
    if (hour1 == hour2 && minute1 == minute2) {
      minute2 = (minute2 + 17) % 60;
    }

    var slot1 = DateTime(now.year, now.month, now.day, hour1, minute1);
    var slot2 = DateTime(now.year, now.month, now.day, hour2, minute2);

    if (!slot2.isAfter(slot1.add(const Duration(hours: 3)))) {
      slot2 = slot1.add(const Duration(hours: 3, minutes: 15));
    }

    // Ensure both slots are still in the future when planning late in the day.
    if (!slot1.isAfter(now) && !slot2.isAfter(now)) {
      slot1 = now.add(Duration(minutes: 20 + _rng.nextInt(40)));
      slot2 = slot1.add(Duration(hours: 3, minutes: _rng.nextInt(30)));
    } else {
      if (!slot1.isAfter(now)) {
        slot1 = now.add(Duration(minutes: 15 + _rng.nextInt(30)));
      }
      if (!slot2.isAfter(now)) {
        slot2 = slot1.add(Duration(hours: 3, minutes: 15 + _rng.nextInt(30)));
      }
    }

    // Cap evening slots.
    if (slot2.hour > 22) {
      slot2 = DateTime(now.year, now.month, now.day, 22, _rng.nextInt(45));
    }

    await prefs.setString(_kPrefScheduledDay, todayKey);
    await prefs.setInt(_kPrefSlot1Hour, slot1.hour);
    await prefs.setInt(_kPrefSlot1Minute, slot1.minute);
    await prefs.setInt(_kPrefSlot2Hour, slot2.hour);
    await prefs.setInt(_kPrefSlot2Minute, slot2.minute);
    await prefs.setBool(_kPrefSlotsActive, false);

    debugPrint(
      'DailyEngagementScheduler: slots $todayKey '
      '${slot1.hour}:${slot1.minute.toString().padLeft(2, '0')} & '
      '${slot2.hour}:${slot2.minute.toString().padLeft(2, '0')}',
    );
  }

  static Future<List<_EngagementMessage>> _buildEngagementMessages(
    UzaDatabase db,
  ) async {
    final pool = <_EngagementMessage>[];
    final now = DateTime.now();

    try {
      // Wishlist: price drops & back-in-stock style alerts (wishlist products).
      final wishlistRows = await db.select(db.wishlistProducts).get();
      for (final w in wishlistRows.take(10)) {
        final product = await (db.select(db.products)
              ..where((t) => t.id.equals(w.productId)))
            .getSingleOrNull();
        if (product == null || product.isSold) continue;
        pool.add(
          _EngagementMessage(
            title: '❤️ ${product.name}',
            body: product.isPromotion
                ? 'Un favori est en promo — ouvrez UzaApp avant la fin de l\'offre 🔥'
                : 'Votre article favori vous attend toujours sur UzaApp ✨',
            payload: jsonEncode({'type': 'product', 'id': product.id}),
          ),
        );
      }

      // Followed shops: new arrivals & updates.
      final follows = await db.select(db.shopFollows).get();
      final legacyFollows = await db.select(db.followedShops).get();
      final followedShopIds = {
        ...follows.map((f) => f.shopId),
        ...legacyFollows.map((f) => f.shopId),
      };
      for (final shopId in followedShopIds.take(10)) {
        final shop = await (db.select(db.shops)
              ..where((t) => t.id.equals(shopId)))
            .getSingleOrNull();
        if (shop == null) continue;

        final recentArrivage = await (db.select(db.stories)
              ..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.isArrivage.equals(true) &
                    t.expiresAt.isBiggerThanValue(now),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();

        if (recentArrivage != null) {
          pool.add(
            _EngagementMessage(
              title: '📦 ${shop.name}',
              body: 'Nouvel arrivage chez une boutique que vous suivez !',
              payload: jsonEncode({'type': 'arrivage', 'id': recentArrivage.id}),
            ),
          );
        } else {
          pool.add(
            _EngagementMessage(
              title: '🏪 ${shop.name}',
              body: 'Une boutique suivie a peut-être de nouvelles offres 👀',
              payload: jsonEncode({'type': 'shop', 'id': shop.id}),
            ),
          );
        }
      }

      final products =
          await (db.select(db.products)
                ..where((t) => t.isSold.equals(false))
                ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
                ..limit(25))
              .get();

      for (final product in products) {
        final name = product.name.trim();
        if (name.isEmpty) continue;
        pool.add(
          _EngagementMessage(
            title: '🛍️ $name',
            body:
                'Un produit qui pourrait vous plaire — ouvrez UzaApp pour le découvrir ✨',
            payload: jsonEncode({'type': 'product', 'id': product.id}),
          ),
        );
      }

      final arrivages =
          await (db.select(db.stories)
                ..where(
                  (t) =>
                      t.isArrivage.equals(true) &
                      t.expiresAt.isBiggerThanValue(now),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(20))
              .get();

      for (final arrivage in arrivages) {
        final shop = await (db.select(
          db.shops,
        )..where((t) => t.id.equals(arrivage.shopId))).getSingleOrNull();
        final shopName = shop?.name ?? 'Une boutique';
        pool.add(
          _EngagementMessage(
            title: '📦 Nouvel arrivage !',
            body: '$shopName vient de publier un arrivage — jetez un œil 🔥',
            payload: jsonEncode({'type': 'arrivage', 'id': arrivage.id}),
          ),
        );
      }

      final productUpdates =
          await (db.select(db.productUpdates)
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(20))
              .get();

      for (final update in productUpdates) {
        final type = ProductUpdateType.fromCode(update.updateType);
        pool.add(
          _EngagementMessage(
            title: '${type.emoji} ${type.notificationTitle(update.productName)}',
            body: type.notificationBody(
              update.shopName,
              message: update.message,
            ),
            payload: jsonEncode({
              'type': 'product_update',
              'id': update.productId,
            }),
          ),
        );
      }

      final shops =
          await (db.select(db.shops)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(20))
              .get();

      for (final shop in shops) {
        pool.add(
          _EngagementMessage(
            title: '🏪 ${shop.name}',
            body:
                'Découvrez cette boutique sur UzaApp — de belles offres vous attendent 💎',
            payload: jsonEncode({'type': 'shop', 'id': shop.id}),
          ),
        );
      }
    } catch (e) {
      debugPrint('DailyEngagementScheduler: content pool error: $e');
    }

    pool.addAll(_marketingMessages());
    pool.shuffle(_rng);

    final picked = <_EngagementMessage>[];
    final usedTitles = <String>{};

    for (final message in pool) {
      if (picked.length >= 2) break;
      if (usedTitles.add(message.title)) {
        picked.add(message);
      }
    }

    while (picked.length < 2) {
      final marketing = _marketingMessages();
      picked.add(marketing[_rng.nextInt(marketing.length)]);
    }

    return picked.take(2).toList();
  }

  static List<_EngagementMessage> _marketingMessages() {
    return const [
      _EngagementMessage(
        title: '✨ UzaApp — Le marché près de chez vous',
        body:
            'Des milliers de produits locaux vous attendent. Ouvrez l\'app et explorez 🚀',
        payload: '{"type":"product","id":0}',
      ),
      _EngagementMessage(
        title: '🔥 Tendances du jour sur UzaApp',
        body:
            'Ne ratez pas les coups de cœur du moment — swipez dans Découvrir 👀',
        payload: '{"type":"product","id":0}',
      ),
      _EngagementMessage(
        title: '🛒 Bon plan du jour',
        body:
            'De nouvelles offres arrivent chaque jour. Revenez voir ce qui est nouveau 💰',
        payload: '{"type":"product","id":0}',
      ),
      _EngagementMessage(
        title: '📣 Annonce UzaApp',
        body:
            'Achetez et vendez localement en toute simplicité — votre marché en poche 📲',
        payload: '{"type":"product","id":0}',
      ),
      _EngagementMessage(
        title: '❤️ Votre shopping local commence ici',
        body:
            'Boutiques, arrivages et promos — tout est sur UzaApp. Ouvrez maintenant !',
        payload: '{"type":"product","id":0}',
      ),
    ];
  }

  static Future<void> _persistMessages(
    SharedPreferences prefs,
    List<_EngagementMessage> messages,
  ) async {
    if (messages.isEmpty) return;
    await prefs.setString(_kPrefMsg1Title, messages[0].title);
    await prefs.setString(_kPrefMsg1Body, messages[0].body);
    await prefs.setString(_kPrefMsg1Payload, messages[0].payload);
    if (messages.length > 1) {
      await prefs.setString(_kPrefMsg2Title, messages[1].title);
      await prefs.setString(_kPrefMsg2Body, messages[1].body);
      await prefs.setString(_kPrefMsg2Payload, messages[1].payload);
    }
  }

  static List<_EngagementMessage> _loadPersistedMessages(
    SharedPreferences prefs,
  ) {
    final m1 = _EngagementMessage(
      title: prefs.getString(_kPrefMsg1Title) ?? '✨ UzaApp',
      body:
          prefs.getString(_kPrefMsg1Body) ??
          'Découvrez les nouveautés sur UzaApp 🚀',
      payload:
          prefs.getString(_kPrefMsg1Payload) ?? '{"type":"product","id":0}',
    );
    final m2 = _EngagementMessage(
      title: prefs.getString(_kPrefMsg2Title) ?? '🔥 Tendances du jour',
      body:
          prefs.getString(_kPrefMsg2Body) ??
          'Ouvrez UzaApp pour voir les derniers produits 👀',
      payload:
          prefs.getString(_kPrefMsg2Payload) ?? '{"type":"product","id":0}',
    );
    return [m1, m2];
  }

  static Future<void> _schedulePendingSlots(
    SharedPreferences prefs, [
    List<_EngagementMessage>? messages,
  ]) async {
    await PushNotificationService.ensureReady(requestPermission: false);
    final plugin = PushNotificationService.plugin;
    if (plugin == null) {
      debugPrint(
        'DailyEngagementScheduler: notification plugin not ready, '
        'will fire due slots on next open',
      );
      return;
    }

    final now = DateTime.now();
    final content = messages ?? _loadPersistedMessages(prefs);
    final slots = _readSlots(prefs, now);
    final firedKeys = [_kPrefSlot1Fired, _kPrefSlot2Fired];

    await plugin.cancel(_kNotificationId1);
    await plugin.cancel(_kNotificationId2);

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    for (var i = 0; i < slots.length && i < content.length; i++) {
      final slot = slots[i];
      final msg = content[i];
      final id = i == 0 ? _kNotificationId1 : _kNotificationId2;

      if (!slot.isAfter(now)) {
        if (prefs.getBool(firedKeys[i]) != true) {
          await PlatformSystemNotifier.show(
            title: msg.title,
            body: msg.body,
            payload: msg.payload,
            notificationId: id,
          );
          await prefs.setBool(firedKeys[i], true);
        }
        continue;
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          PushNotificationService.kArrivagesChannelId,
          'Nouveaux arrivages',
          channelDescription: 'Rappels et annonces UzaApp',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(msg.body),
        ),
        iOS: iosDetails,
      );

      await plugin.zonedSchedule(
        id,
        msg.title,
        msg.body,
        tz.TZDateTime.from(slot, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: msg.payload,
      );
    }
  }

  static Future<void> _fireDueMobileSlots(SharedPreferences prefs) async {
    final now = DateTime.now();
    final slots = _readSlots(prefs, now);
    final content = _loadPersistedMessages(prefs);
    final firedKeys = [_kPrefSlot1Fired, _kPrefSlot2Fired];

    for (var i = 0; i < slots.length && i < content.length; i++) {
      if (prefs.getBool(firedKeys[i]) == true) continue;
      if (slots[i].isAfter(now)) continue;

      final msg = content[i];
      await PlatformSystemNotifier.show(
        title: msg.title,
        body: msg.body,
        payload: msg.payload,
        notificationId: i == 0 ? _kNotificationId1 : _kNotificationId2,
      );
      await prefs.setBool(firedKeys[i], true);
    }
  }

  static List<DateTime> _readSlots(SharedPreferences prefs, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      DateTime(
        today.year,
        today.month,
        today.day,
        prefs.getInt(_kPrefSlot1Hour) ?? 10,
        prefs.getInt(_kPrefSlot1Minute) ?? 0,
      ),
      DateTime(
        today.year,
        today.month,
        today.day,
        prefs.getInt(_kPrefSlot2Hour) ?? 16,
        prefs.getInt(_kPrefSlot2Minute) ?? 30,
      ),
    ];
  }

  static void _cancelWebTimers() {
    for (final timer in _webTimers) {
      timer.cancel();
    }
    _webTimers.clear();
  }

  static Future<void> _fireDueWebSlots(SharedPreferences prefs) async {
    final now = DateTime.now();
    final slots = _readSlots(prefs, now);
    final content = _loadPersistedMessages(prefs);
    final firedKeys = [_kPrefSlot1Fired, _kPrefSlot2Fired];

    for (var i = 0; i < slots.length && i < content.length; i++) {
      if (prefs.getBool(firedKeys[i]) == true) continue;
      if (slots[i].isAfter(now)) continue;

      final msg = content[i];
      await PlatformSystemNotifier.show(
        title: msg.title,
        body: msg.body,
        payload: msg.payload,
        notificationId: i == 0 ? _kNotificationId1 : _kNotificationId2,
      );
      await prefs.setBool(firedKeys[i], true);
    }
  }

  static Future<void> _scheduleWebSlots(
    SharedPreferences prefs,
    List<_EngagementMessage> messages,
  ) async {
    _cancelWebTimers();
    await _fireDueWebSlots(prefs);
    _armWebTimers(prefs, messages: messages);
  }

  static void _armWebTimers(
    SharedPreferences prefs, {
    List<_EngagementMessage>? messages,
  }) {
    _cancelWebTimers();
    final now = DateTime.now();
    final slots = _readSlots(prefs, now);
    final content = messages ?? _loadPersistedMessages(prefs);
    final firedKeys = [_kPrefSlot1Fired, _kPrefSlot2Fired];

    for (var i = 0; i < slots.length && i < content.length; i++) {
      final delay = slots[i].difference(now);
      if (delay.isNegative) continue;

      final msg = content[i];
      final firedKey = firedKeys[i];
      final id = i == 0 ? _kNotificationId1 : _kNotificationId2;

      _webTimers.add(
        Timer(delay, () async {
          final latest = await SharedPreferences.getInstance();
          if (latest.getBool(firedKey) == true) return;

          await PlatformSystemNotifier.show(
            title: msg.title,
            body: msg.body,
            payload: msg.payload,
            notificationId: id,
          );
          await latest.setBool(firedKey, true);
        }),
      );
    }
  }
}
