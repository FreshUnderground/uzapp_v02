// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web Notifications API — works when the tab/PWA is open or as a reminder.
class WebNotificationService {
  static Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    final perm = await html.Notification.requestPermission();
    return perm == 'granted';
  }

  static Future<void> show({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') {
      final ok = await requestPermission();
      if (!ok) return;
    }
    html.Notification(title, body: body, icon: '/icons/Icon-192.png', tag: tag);
  }

  /// Writes next reminder time for the JS watchdog in index.html.
  static Future<void> syncNextReminder(DateTime? nextAt) async {
    if (nextAt == null) {
      html.window.localStorage.remove('uzaapp_wa_status_next_at');
      return;
    }
    html.window.localStorage['uzaapp_wa_status_next_at'] =
        nextAt.toIso8601String();
  }
}
