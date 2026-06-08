import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/uza_database.dart';
import '../utils/image_utils.dart';
import '../utils/status_image_composer.dart';
import '../utils/status_temp_files.dart';

const int kMaxStatusImages = 20;
const int kDefaultRandomStatusCount = 10;

class WhatsAppStatusService {
  final UzaDatabase db;
  final Random _random = Random();

  static Uint8List? _cachedUzaLogoBytes;

  WhatsAppStatusService(this.db);

  Future<List<Product>> getEligibleProducts(int shopId) async {
    final products =
        await (db.select(db.products)
              ..where((t) => t.shopId.equals(shopId) & t.isSold.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    return products
        .where((p) => ImageUtils.hasDisplayableImage(p.imageUrls))
        .toList();
  }

  List<Product> pickRandomProducts(List<Product> products, {required int count}) {
    if (products.isEmpty) return [];
    final pool = List<Product>.from(products)..shuffle(_random);
    final limit = count.clamp(1, kMaxStatusImages);
    return pool.take(limit).toList();
  }

  String? pickRandomImageUrl(Product product) {
    final urls = ImageUtils.getDecryptedList(product.imageUrls)
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty) return null;
    urls.shuffle(_random);
    return urls.first;
  }

  Set<int> pickRandomProductIds(
    List<Product> products, {
    required int count,
  }) {
    return pickRandomProducts(products, count: count).map((p) => p.id).toSet();
  }

  int pickRandomTargetCount(int available) {
    if (available <= 0) return 0;
    const options = [5, 10, 15, 20];
    final valid = options.where((c) => c <= available).toList();
    if (valid.isEmpty) {
      return available.clamp(1, kMaxStatusImages);
    }
    valid.shuffle(_random);
    return valid.first;
  }

  Future<List<Uint8List>> prepareCollection({
    required Shop shop,
    required List<Product> products,
    void Function(int current, int total)? onProgress,
  }) async {
    final selected = products.take(kMaxStatusImages).toList();
    final total = selected.length;
    final results = <Uint8List>[];

    final shopLogoBytes = await _downloadImageBytes(shop.logoUrl);
    final uzaLogoBytes = await _loadUzaLogoBytes();

    for (var i = 0; i < selected.length; i++) {
      final product = selected[i];
      onProgress?.call(i + 1, total);

      final bytes = await _downloadRandomProductImage(product);
      if (bytes == null || bytes.isEmpty) {
        debugPrint(
          'WhatsAppStatusService: skip product ${product.id} (no image)',
        );
        continue;
      }

      try {
        final composed = await StatusImageComposer.composeStatusImage(
          productImageBytes: bytes,
          productName: product.name,
          shopName: shop.name,
          shopLogoBytes: shopLogoBytes,
          uzaLogoBytes: uzaLogoBytes,
        );
        results.add(composed);
      } catch (e) {
        debugPrint(
          'WhatsAppStatusService: compose failed for ${product.id}: $e',
        );
      }
    }

    return results;
  }

  Future<Uint8List?> _loadUzaLogoBytes() async {
    if (_cachedUzaLogoBytes != null) return _cachedUzaLogoBytes;
    try {
      final data = await rootBundle.load('assets/logo.png');
      _cachedUzaLogoBytes = data.buffer.asUint8List();
      return _cachedUzaLogoBytes;
    } catch (e) {
      debugPrint('WhatsAppStatusService: UzaApp logo load failed: $e');
      return null;
    }
  }

  Future<Uint8List?> _downloadImageBytes(String? source) async {
    return ImageUtils.downloadImageBytes(source);
  }

  Future<Uint8List?> _downloadRandomProductImage(Product product) async {
    final url = pickRandomImageUrl(product);
    return _downloadImageBytes(url);
  }

  Future<(List<XFile>, List<String>)> toShareableFiles(
    int shopId,
    List<Uint8List> images,
  ) {
    return writeStatusShareFiles(shopId, images);
  }
}
