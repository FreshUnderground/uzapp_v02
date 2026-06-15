import 'package:shared_preferences/shared_preferences.dart';

import 'product_alerts_service.dart';
import 'push_notification_service.dart';

/// Checks watched products and fires local notifications on price drop / restock.
class ProductAlertNotifier {
  static const _kFiredPrefix = 'uza_alert_fired_';

  static Future<void> checkAndNotify({
    required Map<int, ({String name, double? price, bool isSold})> products,
    required ProductAlertsService alerts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in products.entries) {
      final id = entry.key;
      final p = entry.value;
      final triggered = await alerts.checkTriggers(
        productId: id,
        currentPrice: p.price,
        isSold: p.isSold,
      );
      if (triggered.isEmpty) continue;

      final type = await alerts.alertType(id);
      final firedKey = '$_kFiredPrefix${id}_$type';
      if (prefs.getBool(firedKey) == true) continue;

      final String title;
      final String body;
      if (type == 'price_drop') {
        title = 'Prix en baisse';
        body = '${p.name} — nouveau prix : ${p.price?.toInt() ?? '?'} FC';
      } else {
        title = 'De retour en stock';
        body = '${p.name} est à nouveau disponible';
      }

      final shown = await PushNotificationService.showSystemNotification(
        title: title,
        body: body,
        payload: '{"type":"product","id":$id}',
        notificationId: 9000 + id,
      );
      if (shown) {
        await prefs.setBool(firedKey, true);
        if (type == 'price_drop' && p.price != null) {
          await alerts.watchPriceDrop(id, p.price!);
        }
      }
    }
  }
}
