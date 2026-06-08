import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Persists prepared WhatsApp status images on disk (mobile/desktop).
class StatusBatchStorage {
  static Future<Directory> _batchDir(int shopId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/wa_status/$shopId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<String>> saveBatch(
    int shopId,
    List<Uint8List> images,
  ) async {
    await clearBatch(shopId);
    final dir = await _batchDir(shopId);
    final paths = <String>[];

    for (var i = 0; i < images.length; i++) {
      final path = '${dir.path}/status_$i.jpg';
      await File(path).writeAsBytes(images[i]);
      paths.add(path);
    }

    return paths;
  }

  static Future<List<Uint8List>> loadBatch(List<String> paths) async {
    final images = <Uint8List>[];
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          images.add(await file.readAsBytes());
        }
      } catch (_) {}
    }
    return images;
  }

  static Future<void> clearBatch(int shopId) async {
    try {
      final dir = await _batchDir(shopId);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
