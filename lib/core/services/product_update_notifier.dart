import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/uza_database.dart';
import '../../data/repositories/product_update_repository.dart';
import '../models/product_update_type.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

const String _kLastNotifiedUpdateAt = 'product_updates_last_notified_at';

/// Notifies users when new public product updates arrive from sync.
class ProductUpdateNotifier {
  final UzaDatabase db;
  final ProductUpdateRepository updateRepository;
  final NotificationService? notificationService;

  ProductUpdateNotifier({
    required this.db,
    required this.updateRepository,
    this.notificationService,
  });

  Future<void> notifyNewUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStr = prefs.getString(_kLastNotifiedUpdateAt);
      final lastNotified = lastStr != null
          ? DateTime.tryParse(lastStr)
          : DateTime.now().subtract(const Duration(hours: 24));

      final since = lastNotified ?? DateTime.now().subtract(const Duration(hours: 1));
      final updates = await updateRepository.getSince(since);
      if (updates.isEmpty) return;

      var newest = since;
      for (final update in updates) {
        if (update.createdAt.isAfter(newest)) {
          newest = update.createdAt;
        }

        final type = ProductUpdateType.fromCode(update.updateType);
        final title =
            '${type.emoji} ${type.notificationTitle(update.productName)}';
        final body = type.notificationBody(
          update.shopName,
          message: update.message,
        );

        notificationService?.addNotification(
          title,
          body,
          linkType: 'product',
          linkId: update.productId,
        );

        await PushNotificationService.showSystemNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'type': 'product_update',
            'id': update.productId,
          }),
          notificationId: 7100 + (update.id % 900),
        );
      }

      await prefs.setString(_kLastNotifiedUpdateAt, newest.toIso8601String());
    } catch (e) {
      debugPrint('ProductUpdateNotifier error: $e');
    }
  }
}
