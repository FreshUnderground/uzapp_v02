import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../services/api_service.dart';
import '../utils/crypto_utils.dart';
import '../utils/image_prepare_utils.dart';
import '../utils/image_utils.dart';

/// Pending image bytes saved locally until network upload completes.
class ProductUploadService {
  static const _kPendingMetaKey = 'pending_upload_paths';
  static const _kInlineBytesPrefix = 'inline_base64:';

  /// Persist bytes to temp files; returns map slotIndex -> file path.
  static Future<Map<int, String>> persistPendingImages(
    List<({int slot, Uint8List bytes})> pending,
  ) async {
    final paths = <int, String>{};
    if (kIsWeb) {
      // Web does not expose a writable temp directory through path_provider.
      for (final item in pending) {
        paths[item.slot] = '$_kInlineBytesPrefix${base64Encode(item.bytes)}';
      }
      return paths;
    }

    Directory uploadDir;
    try {
      final dir = await getTemporaryDirectory();
      uploadDir = Directory('${dir.path}/uza_pending_uploads');
    } catch (_) {
      // Fallback for environments where path_provider is not registered yet.
      uploadDir = Directory('${Directory.systemTemp.path}/uza_pending_uploads');
    }

    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }
    for (final item in pending) {
      final file = File(
        '${uploadDir.path}/slot_${item.slot}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(item.bytes);
      paths[item.slot] = file.path;
    }
    return paths;
  }

  static Map<String, dynamic> mergePendingPaths(
    Map<String, dynamic>? existing,
    Map<int, String> paths,
  ) {
    final map = Map<String, dynamic>.from(existing ?? {});
    if (paths.isEmpty) {
      map.remove(_kPendingMetaKey);
    } else {
      map[_kPendingMetaKey] = paths.map((k, v) => MapEntry('$k', v));
    }
    return map;
  }

  static Map<int, String> readPendingPaths(Product product) {
    final raw = product.metadata;
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final pending = map[_kPendingMetaKey];
      if (pending is! Map) return {};
      return pending.map(
        (k, v) => MapEntry(int.parse(k.toString()), v.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  /// Upload pending files, update product URLs, push sync queue.
  static Future<void> processPendingForProduct({
    required Product product,
    required ApiService api,
    required ProductRepository productRepo,
    required ShopRepository shopRepo,
    required SyncService syncService,
  }) async {
    final pending = readPendingPaths(product);
    if (pending.isEmpty) return;

    final images = ImageUtils.getDecryptedList(product.imageUrls);
    final finalUrls = List<String>.from(images);

    for (final entry in pending.entries) {
      try {
        Uint8List bytes;
        File? file;
        if (entry.value.startsWith(_kInlineBytesPrefix)) {
          final encoded = entry.value.substring(_kInlineBytesPrefix.length);
          bytes = base64Decode(encoded);
        } else {
          file = File(entry.value);
          if (!await file.exists()) continue;
          bytes = await file.readAsBytes();
        }
        final prepared = await ImagePrepareUtils.prepareForUpload(
          bytes,
          prefix: 'prod_${entry.key}',
        );
        final sized = await ImagePrepareUtils.ensureUploadSize(prepared.bytes);
        final url = await api.uploadFileOrThrow(
          sized,
          prepared.fileName,
          folder: 'produits',
          timeout: const Duration(seconds: 45),
        );
        while (finalUrls.length <= entry.key) {
          finalUrls.add('');
        }
        finalUrls[entry.key] = url;
        if (file != null) {
          try {
            await file.delete();
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Pending upload slot ${entry.key} failed: $e');
      }
    }

    final cleaned = finalUrls.where((u) => u.isNotEmpty).toList();
    if (cleaned.isEmpty) return;

    Map<String, dynamic>? metaMap;
    if (product.metadata != null && product.metadata!.isNotEmpty) {
      try {
        metaMap = jsonDecode(product.metadata!) as Map<String, dynamic>;
      } catch (_) {}
    }
    metaMap?.remove(_kPendingMetaKey);
    final metaJson = metaMap != null && metaMap.isNotEmpty
        ? jsonEncode(metaMap)
        : null;

    await productRepo.updateProduct(
      ProductsCompanion(
        id: drift.Value(product.id),
        imageUrls: drift.Value(CryptoUtils.encrypt(cleaned.join(','))),
        metadata: drift.Value(metaJson),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final shop = await shopRepo.resolveShopForStoredId(product.shopId);
    final remoteShopId = int.tryParse(shop?.remoteId ?? '') ?? product.shopId;
    final remoteProductId = int.tryParse(product.remoteId ?? '');

    await syncService.addToQueue('UPDATE', 'products', {
      if (remoteProductId != null) 'id': remoteProductId,
      'local_id': product.id,
      'shop_id': remoteShopId,
      'name': product.name,
      'description': product.description ?? '',
      'price': product.price ?? 0,
      'image_urls': cleaned.join(','),
      'category_id': product.categoryId,
      'metadata': metaJson,
    });
  }

  /// Process all products with pending uploads in metadata.
  static Future<void> processAllPending({
    required UzaDatabase db,
    required ApiService api,
    required ProductRepository productRepo,
    required ShopRepository shopRepo,
    required SyncService syncService,
  }) async {
    final all = await db.select(db.products).get();
    for (final product in all) {
      if (readPendingPaths(product).isEmpty) continue;
      await processPendingForProduct(
        product: product,
        api: api,
        productRepo: productRepo,
        shopRepo: shopRepo,
        syncService: syncService,
      );
    }
  }
}
