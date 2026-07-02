import '../../data/local/uza_database.dart';
import 'product_price_utils.dart';
import 'share_message_labels.dart';

/// Textes marketing pour le partage public d'un produit.
class ProductShareMessages {
  ProductShareMessages._();

  /// Public product id for URLs (server/MySQL id when synced).
  static String publicId(Product product) {
    if (product.remoteId != null && product.remoteId!.isNotEmpty) {
      return product.remoteId!;
    }
    return product.id.toString();
  }

  static String publicUrl(Product product) =>
      'https://uzaapp.com/product/${publicId(product)}';

  static String share(Product product, Shop? shop) {
    final url = publicUrl(product);

    final condition = product.condition == 'new'
        ? ShareMessageLabels.conditionNew()
        : ShareMessageLabels.conditionUsed();
    final priceText = ProductPriceUtils.shareLine(product);
    final descLine =
        (product.description != null && product.description!.isNotEmpty)
        ? '${ShareMessageLabels.description(product.description!.length > 120 ? '${product.description!.substring(0, 120)}...' : product.description!)}\n'
        : '';
    final shopLine = shop != null
        ? '${ShareMessageLabels.shop(shop.name)}\n'
        : '';
    final promoLine =
        (product.promotionMessage != null &&
            product.promotionMessage!.trim().isNotEmpty)
        ? '${ShareMessageLabels.promo(product.promotionMessage!.trim())}\n'
        : '';
    final categoryLine =
        (product.category != null && product.category!.trim().isNotEmpty)
        ? '${ShareMessageLabels.category(product.category!.trim())}\n'
        : '';

    return '${ShareMessageLabels.productTitle(product.name)}\n\n'
        '$descLine'
        '$categoryLine'
        '$promoLine'
        '$condition\n'
        '$priceText\n'
        '$shopLine'
        '\n'
        '${ShareMessageLabels.productLink(url)}\n\n'
        '${ShareMessageLabels.footerCatalog}\n\n'
        '${ShareMessageLabels.hashtagsShopping}';
  }

  static String subject(Product product) => '${product.name} | UzaApp';
}
