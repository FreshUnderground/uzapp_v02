import 'package:flutter/material.dart';
import '../../core/utils/product_price_utils.dart';
import '../../data/local/uza_database.dart';

/// Price label for product detail and cart — not used on list cards.
class UzaPriceLabel extends StatelessWidget {
  final Product product;
  final double fontSize;

  const UzaPriceLabel({
    super.key,
    required this.product,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      ProductPriceUtils.displayLabel(product),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
