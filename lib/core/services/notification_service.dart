import 'package:flutter/material.dart';

class NotificationModel {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  bool _enabled = true;
  final Map<String, DateTime> _lastNotificationTime = {};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void addNotification(String title, String message) {
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
}
