import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class RecentlyViewedItem {
  final String id;
  final String type; // 'product' or 'shop'
  final String title;
  final String? imageUrl;
  final String? price;
  final DateTime viewedAt;

  RecentlyViewedItem({
    required this.id,
    required this.type,
    required this.title,
    this.imageUrl,
    this.price,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'imageUrl': imageUrl,
    'price': price,
    'viewedAt': viewedAt.toIso8601String(),
  };

  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) =>
      RecentlyViewedItem(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        imageUrl: json['imageUrl'],
        price: json['price'],
        viewedAt: DateTime.parse(json['viewedAt']),
      );
}

class RecentlyViewedRepository extends ChangeNotifier {
  static const String _key = 'recently_viewed';
  static const int _maxItems = 30;
  List<RecentlyViewedItem> _items = [];

  List<RecentlyViewedItem> get items => _items;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        _items = list.map((e) => RecentlyViewedItem.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        // Gracefully degrade on web if plugin not ready
        return;
      }
      debugPrint('RecentlyViewedRepository: Failed to load: $e');
    }
  }

  Future<void> addItem(RecentlyViewedItem item) async {
    _items.removeWhere((e) => e.id == item.id && e.type == item.type);
    _items.insert(0, item);
    if (_items.length > _maxItems) _items = _items.sublist(0, _maxItems);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        // Gracefully degrade on web if plugin not ready
        return;
      }
      debugPrint('RecentlyViewedRepository: Failed to save: $e');
    }
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        // Gracefully degrade on web if plugin not ready
        return;
      }
      debugPrint('RecentlyViewedRepository: Failed to clear: $e');
    }
  }
}
