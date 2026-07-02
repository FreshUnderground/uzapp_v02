import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/product_update_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../models/product_update_type.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/product_upload_service.dart';
import '../services/push_notification_service.dart';
import '../utils/crypto_utils.dart';

/// Input for publishing a product update (not a new product listing).
class PublishProductUpdateInput {
  final Product product;
  final Shop shop;
  final ProductUpdateType updateType;
  final String? note;
  final double? price;
  final int? stockCount;
  final bool? showStock;
  final bool markAvailable;
  final bool setArrival;
  final List<({int slot, Uint8List bytes})>? newImages;
  final Map<int, String>? existingImageUrlsBySlot;

  const PublishProductUpdateInput({
    required this.product,
    required this.shop,
    required this.updateType,
    this.note,
    this.price,
    this.stockCount,
    this.showStock,
    this.markAvailable = false,
    this.setArrival = false,
    this.newImages,
    this.existingImageUrlsBySlot,
  });
}

class ProductUpdateService {
  final UzaDatabase db;
  final ProductRepository productRepository;
  final ProductUpdateRepository updateRepository;
  final ShopRepository shopRepository;
  final ApiService apiService;
  final NotificationService? notificationService;

  ProductUpdateService({
    required this.db,
    required this.productRepository,
    required this.updateRepository,
    required this.shopRepository,
    required this.apiService,
    this.notificationService,
  });

  Future<ProductUpdate> publishUpdate(PublishProductUpdateInput input) async {
    final product = input.product;
    final shop = input.shop;
    final now = DateTime.now();

    var imageUrls = _decodeImageUrls(product.imageUrls);
    Map<String, dynamic>? metadataMap;
    if (product.metadata != null && product.metadata!.isNotEmpty) {
      try {
        metadataMap =
            jsonDecode(product.metadata!) as Map<String, dynamic>;
      } catch (_) {
        metadataMap = null;
      }
    }

    if (input.existingImageUrlsBySlot != null) {
      final slots = input.existingImageUrlsBySlot!;
      final maxSlot = slots.keys.fold(0, (a, b) => a > b ? a : b);
      if (imageUrls.length <= maxSlot) {
        imageUrls = List<String>.from(imageUrls);
        while (imageUrls.length <= maxSlot) {
          imageUrls.add('');
        }
      }
      slots.forEach((slot, url) {
        if (slot < 3) {
          while (imageUrls.length <= slot) {
            imageUrls.add('');
          }
          imageUrls[slot] = url;
        }
      });
    }

    Map<int, String>? pendingPaths;
    if (input.newImages != null && input.newImages!.isNotEmpty) {
      pendingPaths =
          await ProductUploadService.persistPendingImages(input.newImages!);
      metadataMap = ProductUploadService.mergePendingPaths(
        metadataMap,
        pendingPaths,
      );
      for (final item in input.newImages!) {
        while (imageUrls.length <= item.slot) {
          imageUrls.add('');
        }
      }
    }

    imageUrls = imageUrls.where((u) => u.trim().isNotEmpty).toList();
    final encryptedImages = imageUrls.isEmpty
        ? product.imageUrls
        : CryptoUtils.encrypt(imageUrls.join(','));

    final companion = ProductsCompanion(
      id: Value(product.id),
      price: input.price != null ? Value(input.price!) : const Value.absent(),
      stockCount: input.stockCount != null
          ? Value(input.stockCount!)
          : const Value.absent(),
      showStock: input.showStock != null
          ? Value(input.showStock!)
          : const Value.absent(),
      isSold: input.markAvailable ? const Value(false) : const Value.absent(),
      isArrival: input.setArrival || input.updateType == ProductUpdateType.arrivage
          ? const Value(true)
          : const Value.absent(),
      imageUrls: encryptedImages != product.imageUrls
          ? Value(encryptedImages)
          : const Value.absent(),
      metadata: metadataMap != null
          ? Value(jsonEncode(metadataMap))
          : const Value.absent(),
      updatedAt: Value(now),
    );

    await productRepository.updateProduct(companion);

    final message = input.note?.trim();
    final updateRow = ProductUpdatesCompanion.insert(
      productId: product.id,
      shopId: shop.id,
      updateType: input.updateType.code,
      message: Value(message?.isNotEmpty == true ? message : null),
      productName: product.name,
      shopName: shop.name,
      synced: const Value(0),
      createdAt: Value(now),
    );
    final localUpdateId = await updateRepository.insertUpdate(updateRow);

    final localUpdate = ProductUpdate(
      id: localUpdateId,
      remoteId: null,
      productId: product.id,
      shopId: shop.id,
      updateType: input.updateType.code,
      message: message,
      productName: product.name,
      shopName: shop.name,
      synced: 0,
      createdAt: now,
    );

    unawaited(shopRepository.recordShopActivity(shop.id));
    unawaited(_syncProductAndUpdate(product, shop, localUpdate, input));
    await _broadcastPublicNotification(localUpdate, input.updateType);

    return localUpdate;
  }

  List<String> _decodeImageUrls(String encrypted) {
    if (encrypted.isEmpty) return [];
    try {
      final decoded = CryptoUtils.decrypt(encrypted);
      if (decoded.contains(',')) {
        return decoded.split(',').where((u) => u.trim().isNotEmpty).toList();
      }
      return [decoded];
    } catch (_) {
      return encrypted.split(',').where((u) => u.trim().isNotEmpty).toList();
    }
  }

  String _plainImageUrlsForServer(
    PublishProductUpdateInput input,
    String currentEncrypted,
  ) {
    var urls = _decodeImageUrls(currentEncrypted);
    if (input.existingImageUrlsBySlot != null) {
      urls = List<String>.from(urls);
      input.existingImageUrlsBySlot!.forEach((slot, url) {
        while (urls.length <= slot) {
          urls.add('');
        }
        urls[slot] = url;
      });
    }
    return urls.where((u) => u.trim().isNotEmpty).join(',');
  }

  Future<void> _syncProductAndUpdate(
    Product product,
    Shop shop,
    ProductUpdate update,
    PublishProductUpdateInput input,
  ) async {
    try {
      final remoteShopId =
          (shop.remoteId != null && shop.remoteId!.isNotEmpty)
              ? (int.tryParse(shop.remoteId!) ?? shop.id)
              : shop.id;
      final remoteProductId =
          product.remoteId != null && product.remoteId!.isNotEmpty
              ? int.tryParse(product.remoteId!)
              : product.id;

      await apiService.pushChange('products', 'UPDATE', {
        'id': remoteProductId,
        'local_id': product.id,
        'shop_id': remoteShopId,
        'name': product.name,
        'price': input.price ?? product.price,
        'image_urls': _plainImageUrlsForServer(
          input,
          product.imageUrls,
        ),
        'stock_count': input.stockCount ?? product.stockCount,
        'show_stock': input.showStock ?? product.showStock,
        'is_arrival': input.setArrival ||
                input.updateType == ProductUpdateType.arrivage
            ? 1
            : (product.isArrival ? 1 : 0),
        'is_sold': input.markAvailable ? 0 : (product.isSold ? 1 : 0),
      });

      final response = await apiService.postProductUpdate({
        'product_id': remoteProductId ?? product.id,
        'shop_id': remoteShopId,
        'update_type': update.updateType,
        'message': update.message,
        'product_name': update.productName,
        'shop_name': update.shopName,
        'created_at': update.createdAt.toIso8601String(),
      });

      final serverId = response?['id']?.toString();
      if (serverId != null) {
        await (db.update(db.productUpdates)
              ..where((t) => t.id.equals(update.id)))
            .write(
          ProductUpdatesCompanion(
            remoteId: Value(serverId),
            synced: const Value(1),
          ),
        );
      }
    } catch (e) {
      debugPrint('ProductUpdateService sync error: $e');
    }
  }

  Future<void> _broadcastPublicNotification(
    ProductUpdate update,
    ProductUpdateType type,
  ) async {
    final title = '${type.emoji} ${type.notificationTitle(update.productName)}';
    final body = type.notificationBody(
      update.shopName,
      message: update.message,
    );
    final payload = jsonEncode({
      'type': 'product_update',
      'id': update.productId,
      'update_id': update.id,
    });

    notificationService?.addNotification(
      title,
      body,
      linkType: 'product',
      linkId: update.productId,
    );

    await PushNotificationService.showSystemNotification(
      title: title,
      body: body,
      payload: payload,
      notificationId: 7000 + (update.id % 1000),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'product_updates_last_notified_at',
        update.createdAt.toIso8601String(),
      );
    } catch (_) {}
  }
}
