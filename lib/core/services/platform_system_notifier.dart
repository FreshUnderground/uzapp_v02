import 'package:flutter/foundation.dart';

import 'push_notification_service.dart';
import 'web_notification_service.dart';

/// System tray / browser notifications — works on Android, iOS and Web.
class PlatformSystemNotifier {
  /// Returns true when the notification was shown (or permission granted on web).
  static Future<bool> show({
    required String title,
    required String body,
    String? tag,
    String? payload,
    String channelId = PushNotificationService.kArrivagesChannelId,
    int? notificationId,
  }) async {
    if (kIsWeb) {
      final granted = await WebNotificationService.requestPermission();
      if (!granted) {
        debugPrint('PlatformSystemNotifier: web notification permission denied');
        return false;
      }
      await WebNotificationService.show(
        title: title,
        body: body,
        tag: tag ?? 'uza_${notificationId ?? title.hashCode}',
      );
      return true;
    }

    return PushNotificationService.showSystemNotification(
      title: title,
      body: body,
      payload: payload,
      channelId: channelId,
      notificationId: notificationId,
    );
  }
}
