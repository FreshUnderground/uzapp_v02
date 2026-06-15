import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/uza_database.dart';
import '../utils/status_batch_storage.dart';
import 'platform_system_notifier.dart';
import 'push_notification_service.dart';
import 'web_notification_service.dart';
import 'whatsapp_status_service.dart';
import '../utils/status_template_prefs.dart';

/// Interval between automatic WhatsApp status preparations.
const Duration kWaStatusInterval = Duration(hours: 24, minutes: 30);

const int kWaStatusNotificationId = 9001;

const String kPrefWaStatusEnabled = 'wa_status_auto_enabled';
const String kPrefWaStatusLastPreparedAt = 'wa_status_last_prepared_at';
const String kPrefWaStatusNextAt = 'wa_status_next_at';
const String kPrefWaStatusShopId = 'wa_status_prepared_shop_id';
const String kPrefWaStatusImagePaths = 'wa_status_prepared_paths';
const String kPrefWaStatusImageCount = 'wa_status_prepared_count';
const String kPrefWaStatusOwnerPhone = 'wa_status_owner_phone';
const String kPrefWaStatusPreparing = 'wa_status_preparing_lock';

/// Prepares daily WhatsApp status collections and notifies the seller.
class WhatsAppStatusScheduler {
  final UzaDatabase db;
  final WhatsAppStatusService statusService;

  WhatsAppStatusScheduler(this.db, this.statusService);

  static bool isDue(DateTime? lastPrepared, DateTime? nextAt) {
    final now = DateTime.now();
    if (nextAt != null && now.isBefore(nextAt)) return false;
    if (lastPrepared == null) return true;
    return now.difference(lastPrepared) >= kWaStatusInterval;
  }

  static Future<DateTime> computeNextRun(DateTime from) async {
    final schedule = await StatusTemplatePrefs.loadSchedule();
    if (schedule.enabled) {
      var next = DateTime(
        from.year,
        from.month,
        from.day,
        schedule.hour,
        schedule.minute,
      );
      if (!next.isAfter(from)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    }
    return from.add(kWaStatusInterval);
  }

  Future<bool> isAutoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kPrefWaStatusEnabled) ?? true;
  }

  Future<void> setAutoEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefWaStatusEnabled, value);
    if (!value) {
      await WebNotificationService.syncNextReminder(null);
    }
  }

  Future<void> registerShopOwner(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefWaStatusOwnerPhone, phone.trim());
  }

  Future<void> registerShop(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kPrefWaStatusShopId, shopId);
  }

  /// Called on app start, resume, and from background workers.
  Future<WaStatusPrepResult?> prepareIfDue({bool force = false}) async {
    if (!force && !await isAutoEnabled()) return null;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kPrefWaStatusPreparing) == true) {
      debugPrint('WhatsAppStatusScheduler: already preparing, skip');
      return null;
    }

    final lastStr = prefs.getString(kPrefWaStatusLastPreparedAt);
    final nextStr = prefs.getString(kPrefWaStatusNextAt);
    final lastPrepared =
        lastStr != null ? DateTime.tryParse(lastStr) : null;
    final nextAt = nextStr != null ? DateTime.tryParse(nextStr) : null;

    if (!force && !isDue(lastPrepared, nextAt)) {
      return null;
    }

    final shop = await _resolveShop();
    if (shop == null) {
      debugPrint('WhatsAppStatusScheduler: no shop found');
      return null;
    }

    await prefs.setBool(kPrefWaStatusPreparing, true);
    try {
      final products = await statusService.getEligibleProducts(shop.id);
      if (products.isEmpty) {
        debugPrint('WhatsAppStatusScheduler: no eligible products');
        return null;
      }

      final count = statusService.pickRandomTargetCount(products.length);
      final selected = statusService.pickRandomProducts(
        products,
        count: count,
      );

      final images = await statusService.prepareCollection(
        shop: shop,
        products: selected,
      );

      if (images.isEmpty) return null;

      final paths = await StatusBatchStorage.saveBatch(shop.id, images);
      final now = DateTime.now();
      final nextRun = await computeNextRun(now);

      await prefs.setString(kPrefWaStatusLastPreparedAt, now.toIso8601String());
      await prefs.setString(kPrefWaStatusNextAt, nextRun.toIso8601String());
      await prefs.setInt(kPrefWaStatusShopId, shop.id);
      await prefs.setString(kPrefWaStatusImagePaths, jsonEncode(paths));
      await prefs.setInt(kPrefWaStatusImageCount, images.length);

      await _notifyReady(shop.id, images.length, nextRun);

      return WaStatusPrepResult(
        shopId: shop.id,
        imageCount: images.length,
        preparedAt: now,
        nextAt: nextRun,
      );
    } catch (e, st) {
      debugPrint('WhatsAppStatusScheduler: prepare failed: $e\n$st');
      return null;
    } finally {
      await prefs.setBool(kPrefWaStatusPreparing, false);
    }
  }

  Future<void> syncWebReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final nextStr = prefs.getString(kPrefWaStatusNextAt);
    final nextAt = nextStr != null ? DateTime.tryParse(nextStr) : null;
    await WebNotificationService.syncNextReminder(nextAt);
  }

  Future<PreparedWaStatusBatch?> loadPreparedBatch(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedShopId = prefs.getInt(kPrefWaStatusShopId);
    if (storedShopId != shopId) return null;

    final pathsJson = prefs.getString(kPrefWaStatusImagePaths);
    if (pathsJson == null) return null;

    final paths = (jsonDecode(pathsJson) as List).cast<String>();
    if (paths.isEmpty) return null;

    final images = await StatusBatchStorage.loadBatch(paths);
    if (images.isEmpty) return null;

    final preparedStr = prefs.getString(kPrefWaStatusLastPreparedAt);
    final nextStr = prefs.getString(kPrefWaStatusNextAt);

    return PreparedWaStatusBatch(
      shopId: shopId,
      images: images,
      preparedAt: preparedStr != null ? DateTime.tryParse(preparedStr) : null,
      nextAt: nextStr != null ? DateTime.tryParse(nextStr) : null,
    );
  }

  Future<Shop?> _resolveShop() async {
    final prefs = await SharedPreferences.getInstance();
    final storedShopId = prefs.getInt(kPrefWaStatusShopId);
    if (storedShopId != null) {
      final shop = await (db.select(db.shops)
            ..where((t) => t.id.equals(storedShopId)))
          .getSingleOrNull();
      if (shop != null) return shop;
    }

    final ownerPhone = prefs.getString(kPrefWaStatusOwnerPhone);
    final shops = await db.select(db.shops).get();

    if (ownerPhone != null && ownerPhone.isNotEmpty) {
      for (final shop in shops) {
        if (shop.ownerId == ownerPhone || shop.phone == ownerPhone) {
          return shop;
        }
      }
    }

    if (shops.length == 1) return shops.first;
    return null;
  }

  Future<void> _notifyReady(int shopId, int count, DateTime nextRun) async {
    final title = 'Statuts WhatsApp prêts';
    final body =
        '$count image(s) prête(s) à publier. Ouvrez Uzaapp pour partager.';
    final payload = jsonEncode({
      'type': 'whatsapp_status',
      'id': shopId,
    });

    await PlatformSystemNotifier.show(
      title: title,
      body: body,
      payload: payload,
      channelId: PushNotificationService.kWaStatusChannelId,
      notificationId: kWaStatusNotificationId,
      tag: 'wa_status_ready',
    );
    if (kIsWeb) {
      await WebNotificationService.syncNextReminder(nextRun);
    }
  }
}

class WaStatusPrepResult {
  final int shopId;
  final int imageCount;
  final DateTime preparedAt;
  final DateTime nextAt;

  const WaStatusPrepResult({
    required this.shopId,
    required this.imageCount,
    required this.preparedAt,
    required this.nextAt,
  });
}

class PreparedWaStatusBatch {
  final int shopId;
  final List<Uint8List> images;
  final DateTime? preparedAt;
  final DateTime? nextAt;

  const PreparedWaStatusBatch({
    required this.shopId,
    required this.images,
    this.preparedAt,
    this.nextAt,
  });
}

/// Top-level entry for Workmanager — must stay free of instance state.
Future<void> runWhatsAppStatusBackgroundPrep() async {
  try {
    if (!kIsWeb) {
      await PushNotificationService.ensureReady(requestPermission: false);
    }
    final db = UzaDatabase();
    final service = WhatsAppStatusService(db);
    final scheduler = WhatsAppStatusScheduler(db, service);
    await scheduler.prepareIfDue();
  } catch (e) {
    debugPrint('runWhatsAppStatusBackgroundPrep error: $e');
  }
}
