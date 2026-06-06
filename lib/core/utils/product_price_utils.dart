import '../../data/local/uza_database.dart';

class ProductPriceUtils {
  static bool hasVisiblePrice(Product product) {
    return !product.hidePrice &&
        product.price != null &&
        product.price! > 0;
  }

  static String formatAmount(double price) {
    if (price == price.roundToDouble()) {
      return '${price.toStringAsFixed(0)} \$';
    }
    return '${price.toStringAsFixed(2)} \$';
  }

  /// Libellé affiché dans l'app (fiche produit, cartes, etc.).
  static String displayLabel(Product product) {
    if (!hasVisiblePrice(product)) return 'À discuter';
    return formatAmount(product.price!);
  }

  /// Ligne prix pour les messages WhatsApp / partage.
  static String shareLine(Product product) {
    if (!hasVisiblePrice(product)) return '💬 Prix : à discuter';
    return '💰 Prix : ${formatAmount(product.price!)}';
  }

  static String shareLineFromValues({
    required double? price,
    bool hidePrice = false,
  }) {
    if (hidePrice || price == null || price <= 0) {
      return '💬 Prix : à discuter';
    }
    return '💰 Prix : ${formatAmount(price)}';
  }
}
