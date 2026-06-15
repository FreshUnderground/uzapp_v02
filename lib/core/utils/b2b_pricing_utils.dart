import 'dart:convert';

import '../../data/local/uza_database.dart';

class B2bPriceTier {
  final int minQty;
  final double unitPrice;

  const B2bPriceTier({required this.minQty, required this.unitPrice});
}

/// Wholesale tier pricing stored in [Product.metadata] JSON.
class B2bPricingUtils {
  B2bPricingUtils._();

  static const _kTiers = 'b2b_tiers';

  static List<B2bPriceTier> parseTiers(Product product) {
    final raw = product.metadata;
    if (raw == null || raw.isEmpty) return [];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map[_kTiers];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map(
            (e) => B2bPriceTier(
              minQty: (e['min_qty'] as num?)?.toInt() ?? 1,
              unitPrice: (e['unit_price'] as num?)?.toDouble() ?? 0,
            ),
          )
          .where((t) => t.unitPrice > 0)
          .toList()
        ..sort((a, b) => a.minQty.compareTo(b.minQty));
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> mergeTiersIntoMetadata(
    Map<String, dynamic>? existing,
    List<B2bPriceTier> tiers,
  ) {
    final map = Map<String, dynamic>.from(existing ?? {});
    if (tiers.isEmpty) {
      map.remove(_kTiers);
    } else {
      map[_kTiers] = tiers
          .map((t) => {'min_qty': t.minQty, 'unit_price': t.unitPrice})
          .toList();
    }
    return map;
  }

  static double? priceForQuantity(Product product, int quantity) {
    final tiers = parseTiers(product);
    if (tiers.isEmpty) return product.price;
    B2bPriceTier? best;
    for (final tier in tiers) {
      if (quantity >= tier.minQty) best = tier;
    }
    return best?.unitPrice ?? product.price;
  }

  static bool hasWholesalePricing(Product product) =>
      parseTiers(product).isNotEmpty;
}
