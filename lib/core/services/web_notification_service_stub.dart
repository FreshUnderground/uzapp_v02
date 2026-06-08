/// No-op on mobile — local notifications handled by PushNotificationService.
class WebNotificationService {
  static Future<bool> requestPermission() async => false;

  static Future<void> show({
    required String title,
    required String body,
    String? tag,
  }) async {}

  static Future<void> syncNextReminder(DateTime? nextAt) async {}
}
