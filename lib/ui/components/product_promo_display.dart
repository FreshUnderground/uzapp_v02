import 'package:flutter/material.dart';

import '../../core/utils/product_promo_utils.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';

/// Promo badge + strikethrough price for flash sales.
class ProductPromoDisplay extends StatelessWidget {
  final Product product;
  final double? fontSize;
  final bool showBadge;

  const ProductPromoDisplay({
    super.key,
    required this.product,
    this.fontSize,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final promo = ProductPromoUtils.parse(product);
    final active = ProductPromoUtils.isFlashProduct(product);
    final displayPrice = active && promo.promoPrice != null
        ? promo.promoPrice!
        : product.price;

    if (product.hidePrice || displayPrice == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBadge && active) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (promo.countdownLabel() != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    promo.countdownLabel()!,
                    style: const TextStyle(color: Colors.white, fontSize: 7),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
        Row(
          children: [
            Text(
              '${displayPrice.toInt()} FC',
              style: TextStyle(
                color: active ? Colors.red.shade700 : UzaColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: fontSize ?? 12,
              ),
            ),
            if (active &&
                promo.promoPrice != null &&
                product.price != null &&
                product.price! > promo.promoPrice!) ...[
              const SizedBox(width: 4),
              Text(
                '${product.price!.toInt()}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontSize: (fontSize ?? 12) - 2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
