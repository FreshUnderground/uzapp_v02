import '../../data/local/uza_database.dart';
import '../../data/repositories/cart_repository.dart';
import 'product_price_utils.dart';
import 'shop_qr_utils.dart';

/// Structured WhatsApp messages for orders, quotes and single-product checkout.
class WhatsAppCheckoutUtils {
  WhatsAppCheckoutUtils._();

  static String _productRef(Product product) {
    if (product.remoteId != null && product.remoteId!.isNotEmpty) {
      return product.remoteId!;
    }
    return product.id.toString();
  }

  static String _productUrl(Product product) =>
      'https://uzaapp.com/product/${_productRef(product)}';

  /// Single product — direct order via WhatsApp.
  static String singleProductOrder({
    required Product product,
    required Shop shop,
    int quantity = 1,
    String? buyerPhone,
    String? buyerCommune,
    String? note,
  }) {
    final buf = StringBuffer();
    buf.writeln('🛒 *COMMANDE UZAAPP*');
    buf.writeln('Bonjour ${shop.name} !');
    buf.writeln();
    buf.writeln('📦 *${product.name.trim()}*');
    buf.writeln('   Qté : $quantity');
    buf.writeln('   ${ProductPriceUtils.shareLine(product)}');
    buf.writeln('   🔗 ${_productUrl(product)}');
    buf.writeln();
    if (buyerCommune != null && buyerCommune.isNotEmpty) {
      buf.writeln('📍 Commune : $buyerCommune');
    }
    if (buyerPhone != null && buyerPhone.isNotEmpty) {
      buf.writeln('📱 Mon numéro : $buyerPhone');
    }
    if (note != null && note.trim().isNotEmpty) {
      buf.writeln('💬 Note : ${note.trim()}');
    }
    buf.writeln();
    buf.writeln('Merci de me confirmer disponibilité, prix final et livraison.');
    buf.writeln('_Envoyé via UzaApp_ 🇨🇩');
    return buf.toString();
  }

  /// Cart / multi-item quote request.
  static String cartQuote({
    required Shop shop,
    required List<CartItemWithProduct> items,
    String? buyerPhone,
    String? buyerCommune,
  }) {
    final buf = StringBuffer();
    buf.writeln('🌟 *DEMANDE DE DEVIS UZAAPP*');
    buf.writeln('Bonjour ${shop.name},');
    buf.writeln('Je souhaite commander :');
    buf.writeln();

    var total = 0.0;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final linePrice = (item.product.price ?? 0) * item.cartItem.quantity;
      total += linePrice;
      buf.writeln('${i + 1}. *${item.product.name.trim()}*');
      buf.writeln('   Qté : ${item.cartItem.quantity}');
      if (!item.product.hidePrice && item.product.price != null) {
        buf.writeln('   ${item.product.price!.toInt()} FC / unité');
      }
      buf.writeln('   🔗 ${_productUrl(item.product)}');
      buf.writeln();
    }

    buf.writeln('─────────────');
    if (total > 0) {
      buf.writeln('💰 Estimation : *${total.toInt()} FC*');
    }
    if (buyerCommune != null && buyerCommune.isNotEmpty) {
      buf.writeln('📍 Commune : $buyerCommune');
    }
    if (buyerPhone != null && buyerPhone.isNotEmpty) {
      buf.writeln('📱 Mon numéro : $buyerPhone');
    }
    buf.writeln();
    buf.writeln('Pouvez-vous confirmer le total et les options de livraison ?');
    buf.writeln('🏪 ${ShopQrUtils.shopUrl(shop)}');
    buf.writeln('_Envoyé via UzaApp_');
    return buf.toString();
  }

  /// B2B wholesale quote request.
  static String b2bQuote({
    required Product product,
    required Shop shop,
    required int quantity,
    String? buyerPhone,
  }) {
    final buf = StringBuffer();
    buf.writeln('🏭 *DEMANDE GROS / B2B — UZAAPP*');
    buf.writeln('Bonjour ${shop.name},');
    buf.writeln();
    buf.writeln('📦 *${product.name.trim()}*');
    buf.writeln('   Quantité souhaitée : *$quantity*');
    buf.writeln('   ${ProductPriceUtils.shareLine(product)}');
    buf.writeln('   🔗 ${_productUrl(product)}');
    buf.writeln();
    if (buyerPhone != null && buyerPhone.isNotEmpty) {
      buf.writeln('📱 Contact : $buyerPhone');
    }
    buf.writeln('Merci de m\'envoyer votre grille tarifaire gros.');
    buf.writeln('_UzaApp B2B_');
    return buf.toString();
  }

  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  static Uri whatsAppUri(String phone, String message) => Uri.parse(
        'https://wa.me/${normalizePhone(phone)}?text=${Uri.encodeComponent(message)}',
      );
}
