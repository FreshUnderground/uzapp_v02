import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'push_notification_service.dart';

/// Local notifications when new delivery requests arrive for a shop.
class DeliveryNotificationHelper {
  DeliveryNotificationHelper._();

  static final Set<String> _notifiedKeys = {};

  static Future<void> notifySellerNewDelivery({
    required int deliveryLocalId,
    required int shopLocalId,
    required String buyerLabel,
  }) async {
    final key = '$shopLocalId:$deliveryLocalId';
    if (_notifiedKeys.contains(key)) return;
    _notifiedKeys.add(key);
    if (_notifiedKeys.length > 200) {
      _notifiedKeys.remove(_notifiedKeys.first);
    }

    final payload = jsonEncode({
      'type': 'delivery',
      'id': deliveryLocalId,
      'shop_id': shopLocalId,
    });

    await PushNotificationService.showSystemNotification(
      title: 'Nouvelle livraison',
      body: '$buyerLabel demande une livraison',
      channelId: PushNotificationService.kDeliveriesChannelId,
      notificationId: deliveryLocalId,
      payload: payload,
    );

    debugPrint('DeliveryNotificationHelper: notified $key');
  }
}
