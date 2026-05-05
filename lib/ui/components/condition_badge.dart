import 'package:flutter/material.dart';

/// Enum representing the condition of a product in the DRC marketplace.
///
/// Labels are in French to match the app's primary locale.
enum ProductCondition {
  newProduct('Neuf', Color(0xFF4CAF50)),
  usedLikeNew('Comme neuf', Color(0xFF2196F3)),
  usedGood('Bon état', Color(0xFFFF9800)),
  usedFair('État moyen', Color(0xFFF44336));

  final String label;
  final Color color;
  const ProductCondition(this.label, this.color);

  /// Parse from the database string value.
  static ProductCondition fromString(String? value) {
    switch (value) {
      case 'used_like_new':
        return ProductCondition.usedLikeNew;
      case 'used_good':
        return ProductCondition.usedGood;
      case 'used_fair':
        return ProductCondition.usedFair;
      default:
        return ProductCondition.newProduct;
    }
  }

  /// Convert to the database string value.
  String toDbString() {
    switch (this) {
      case ProductCondition.newProduct:
        return 'new';
      case ProductCondition.usedLikeNew:
        return 'used_like_new';
      case ProductCondition.usedGood:
        return 'used_good';
      case ProductCondition.usedFair:
        return 'used_fair';
    }
  }
}

/// A colored pill badge showing the product condition label.
class ConditionBadge extends StatelessWidget {
  final String? condition;

  const ConditionBadge({super.key, this.condition});

  @override
  Widget build(BuildContext context) {
    final cond = ProductCondition.fromString(condition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cond.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cond.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        cond.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cond.color,
        ),
      ),
    );
  }
}
