import 'dart:convert';

import '../../data/local/uza_database.dart';

/// Flash-sale fields stored inside [Product.metadata] JSON.
class ProductPromoInfo {
  final double? promoPrice;
  final DateTime? endsAt;

  const ProductPromoInfo({this.promoPrice, this.endsAt});

  bool get isActive {
    if (promoPrice == null) return false;
    if (endsAt == null) return true;
    return DateTime.now().isBefore(endsAt!);
  }

  Duration? get remaining {
    if (endsAt == null) return null;
    final diff = endsAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String? countdownLabel() {
    final rem = remaining;
    if (rem == null) return null;
    if (rem == Duration.zero) return 'Terminé';
    if (rem.inDays > 0) return '${rem.inDays}j ${rem.inHours % 24}h';
    if (rem.inHours > 0) return '${rem.inHours}h ${rem.inMinutes % 60}min';
    return '${rem.inMinutes}min';
  }
}

class ProductPromoUtils {
  static const _kPromoPrice = 'flash_promo_price';
  static const _kEndsAt = 'flash_ends_at';

  static ProductPromoInfo parse(Product? product) {
    if (product == null) return const ProductPromoInfo();
    final raw = product.metadata;
    if (raw == null || raw.isEmpty) {
      return product.isPromotion
          ? ProductPromoInfo(promoPrice: product.price)
          : const ProductPromoInfo();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final price = (map[_kPromoPrice] as num?)?.toDouble();
      final endsRaw = map[_kEndsAt]?.toString();
      final endsAt = endsRaw != null ? DateTime.tryParse(endsRaw) : null;
      return ProductPromoInfo(promoPrice: price, endsAt: endsAt);
    } catch (_) {
      return const ProductPromoInfo();
    }
  }

  static Map<String, dynamic> mergeFlashIntoMetadata(
    Map<String, dynamic>? existing, {
    required bool isFlash,
    double? promoPrice,
    DateTime? endsAt,
  }) {
    final map = Map<String, dynamic>.from(existing ?? {});
    if (!isFlash) {
      map.remove(_kPromoPrice);
      map.remove(_kEndsAt);
      return map;
    }
    if (promoPrice != null) map[_kPromoPrice] = promoPrice;
    if (endsAt != null) map[_kEndsAt] = endsAt.toIso8601String();
    return map;
  }

  static bool isFlashProduct(Product product) {
    if (!product.isPromotion) return false;
    return parse(product).isActive;
  }
}
