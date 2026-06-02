import 'package:flutter/material.dart';

class NotificationModel {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? linkType;
  final int? linkId;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.linkType,
    this.linkId,
  });
}

class NotificationService extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  bool _enabled = true;
  final Map<String, DateTime> _lastNotificationTime = {};

  /// Pending deep link from notification tap (type + id).
  Map<String, dynamic>? _pendingDeepLink;
  Map<String, dynamic>? get pendingDeepLink => _pendingDeepLink;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void addNotification(
    String title,
    String message, {
    String? linkType,
    int? linkId,
  }) {
    if (!_enabled) return;

    final now = DateTime.now();
    final lastTime = _lastNotificationTime[title];
    if (lastTime != null && now.difference(lastTime).inMinutes < 5) {
      return;
    }
    _lastNotificationTime[title] = now;

    _notifications.insert(
      0,
      NotificationModel(
        title: title,
        message: message,
        timestamp: DateTime.now(),
        linkType: linkType,
        linkId: linkId,
      ),
    );
    notifyListeners();
  }

  void markAsRead(int index) {
    _notifications[index].isRead = true;
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // ── Push notification payload handling ───────────────────────────────

  /// Store a pending deep link from a push notification tap.
  /// [type] should be 'arrivage', 'product', or 'shop'.
  /// [id] is the entity ID.
  void setPendingDeepLink({required String type, required int id}) {
    _pendingDeepLink = {'type': type, 'id': id};
    notifyListeners();
  }

  /// Consume and return the pending deep link, clearing it.
  Map<String, dynamic>? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    if (link != null) notifyListeners();
    return link;
  }

  /// Handle a push notification payload by adding it to the notification
  /// list and optionally setting a deep link.
  void handlePushPayload(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Nouveaux arrivages!';
    final body =
        data['body']?.toString() ??
        'Decouvrez les nouveaux arrivages sur UzaApp!';
    final type = data['type']?.toString();
    final id = int.tryParse(data['id']?.toString() ?? '');

    addNotification(title, body);

    if (type != null && id != null) {
      setPendingDeepLink(type: type, id: id);
    }
  }
}
