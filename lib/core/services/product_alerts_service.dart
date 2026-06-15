import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local price-drop and back-in-stock alerts (no server required).
class ProductAlertsService {
  static const _kAlertsKey = 'uza_product_alerts_v1';

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlertsKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAlertsKey, jsonEncode(data));
  }

  String _key(int productId) => '$productId';

  Future<void> watchPriceDrop(int productId, double currentPrice) async {
    final all = await _loadAll();
    all[_key(productId)] = {
      'type': 'price_drop',
      'price': currentPrice,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _saveAll(all);
  }

  Future<void> watchBackInStock(int productId) async {
    final all = await _loadAll();
    all[_key(productId)] = {
      'type': 'back_in_stock',
      'created_at': DateTime.now().toIso8601String(),
    };
    await _saveAll(all);
  }

  Future<bool> isWatching(int productId) async {
    final all = await _loadAll();
    return all.containsKey(_key(productId));
  }

  Future<String?> alertType(int productId) async {
    final all = await _loadAll();
    final entry = all[_key(productId)];
    if (entry is Map) return entry['type'] as String?;
    return null;
  }

  Future<void> unwatch(int productId) async {
    final all = await _loadAll();
    all.remove(_key(productId));
    await _saveAll(all);
  }

  /// Returns product IDs that should notify (price dropped or back in stock).
  Future<List<int>> checkTriggers({
    required int productId,
    required double? currentPrice,
    required bool isSold,
  }) async {
    final all = await _loadAll();
    final entry = all[_key(productId)];
    if (entry is! Map) return [];

    final type = entry['type'] as String?;
    if (type == 'price_drop' && currentPrice != null) {
      final watched = (entry['price'] as num?)?.toDouble();
      if (watched != null && currentPrice < watched) {
        return [productId];
      }
    }
    if (type == 'back_in_stock' && !isSold) {
      return [productId];
    }
    return [];
  }
}
