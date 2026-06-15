import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/uza_database.dart';
import 'platform_system_notifier.dart';
import 'push_notification_service.dart';

const String _kLastOpenNotifAt = 'system_push_last_open_notif_at';

const int _kIdDiscoveryBase = 8200;
const int _kIdStatusReady = 8201;
const int _kIdTikTokReady = 8202;

class _PushContent {
  final String title;
  final String body;
  final String payload;

  const _PushContent({
    required this.title,
    required this.body,
    required this.payload,
  });
}

/// Phone system notifications only (notification tray) — no in-app bell list.
class SystemPushNotifier {
  static final Random _rng = Random();

  /// Random arrivage or recent product, shown after app open (system tray).
  static Future<void> notifyRandomAfterAppOpen(UzaDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_kLastOpenNotifAt);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && DateTime.now().difference(last).inMinutes < 45) {
      return;
    }

    // Brief delay so the tray notification appears after the splash/home screen.
    await Future<void>.delayed(const Duration(seconds: 2));

    final content = await _pickRandomDiscovery(db);
    if (content == null) return;

    await PlatformSystemNotifier.show(
      title: content.title,
      body: content.body,
      payload: content.payload,
      channelId: PushNotificationService.kArrivagesChannelId,
      notificationId: _kIdDiscoveryBase + _rng.nextInt(20),
    );

    await prefs.setString(_kLastOpenNotifAt, DateTime.now().toIso8601String());
    debugPrint('SystemPushNotifier: discovery push "${content.title}"');
  }

  /// Status image generation finished (system tray).
  static Future<bool> notifyStatusGenerationComplete({
    required int shopId,
    required String shopName,
    required int imageCount,
  }) async {
    final payload = jsonEncode({'type': 'whatsapp_status', 'id': shopId});
    final shown = await PlatformSystemNotifier.show(
      title: '✅ Génération terminée',
      body:
          '$imageCount image(s) prête(s) pour $shopName. Touchez pour partager.',
      payload: payload,
      channelId: PushNotificationService.kWaStatusChannelId,
      notificationId: _kIdStatusReady,
      tag: 'wa_status_ready',
    );
    debugPrint('SystemPushNotifier: status ready push ($imageCount images)');
    return shown;
  }

  /// TikTok slideshow MP4 finished (system tray).
  static Future<bool> notifyTikTokVideoReady({
    required int shopId,
    required String shopName,
  }) async {
    final payload = jsonEncode({'type': 'whatsapp_status', 'id': shopId});
    final shown = await PlatformSystemNotifier.show(
      title: '🎬 Vidéo TikTok prête',
      body: 'Votre vidéo pour $shopName est prête. Touchez pour partager.',
      payload: payload,
      channelId: PushNotificationService.kWaStatusChannelId,
      notificationId: _kIdTikTokReady,
      tag: 'tiktok_status_ready',
    );
    debugPrint('SystemPushNotifier: TikTok video ready push ($shopName)');
    return shown;
  }

  static Future<_PushContent?> _pickRandomDiscovery(UzaDatabase db) async {
    final pool = <_PushContent>[];
    final now = DateTime.now();

    try {
      final products = await (db.select(db.products)
            ..where((t) => t.isSold.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(15))
          .get();

      for (final product in products) {
        final name = product.name.trim();
        if (name.isEmpty) continue;
        pool.add(
          _PushContent(
            title: '🛍️ $name',
            body: 'Produit récemment ajouté — ouvrez UzaApp pour le découvrir ✨',
            payload: jsonEncode({'type': 'product', 'id': product.id}),
          ),
        );
      }

      final arrivages = await (db.select(db.stories)
            ..where(
              (t) =>
                  t.isArrivage.equals(true) &
                  t.expiresAt.isBiggerThanValue(now),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(15))
          .get();

      for (final arrivage in arrivages) {
        final shop = await (db.select(db.shops)
              ..where((t) => t.id.equals(arrivage.shopId)))
            .getSingleOrNull();
        pool.add(
          _PushContent(
            title: '📦 Nouvel arrivage',
            body:
                '${shop?.name ?? 'Une boutique'} a publié un arrivage — jetez un œil 🔥',
            payload: jsonEncode({'type': 'arrivage', 'id': arrivage.id}),
          ),
        );
      }
    } catch (e) {
      debugPrint('SystemPushNotifier: pool error: $e');
    }

    if (pool.isEmpty) return null;
    pool.shuffle(_rng);
    return pool.first;
  }
}
