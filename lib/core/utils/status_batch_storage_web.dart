import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Web: stores prepared images as base64 in SharedPreferences (small batches).
class StatusBatchStorage {
  static String _key(int shopId) => 'wa_status_web_batch_$shopId';

  static Future<List<String>> saveBatch(
    int shopId,
    List<Uint8List> images,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = images.map(base64Encode).toList();
    await prefs.setStringList(_key(shopId), encoded);
    return List.generate(images.length, (i) => 'web:$shopId:$i');
  }

  static Future<List<Uint8List>> loadBatch(List<String> paths) async {
    if (paths.isEmpty) return [];
    final shopPart = paths.first.split(':');
    if (shopPart.length < 2) return [];
    final shopId = int.tryParse(shopPart[1]);
    if (shopId == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_key(shopId)) ?? [];
    return encoded.map((s) => base64Decode(s)).toList();
  }

  static Future<void> clearBatch(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(shopId));
  }
}
