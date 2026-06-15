import '../../data/local/uza_database.dart';
import 'product_price_utils.dart';
import 'shop_qr_utils.dart';

/// Textes marketing d'accompagnement pour le partage boutique (lien ou QR code).
class ShopShareMessages {
  ShopShareMessages._();

  static String _locationLine(Shop shop) {
    final parts = <String>[
      if (shop.commune?.trim().isNotEmpty == true) shop.commune!.trim(),
      if (shop.city?.trim().isNotEmpty == true) shop.city!.trim(),
    ];
    if (parts.isNotEmpty) return '📍 ${parts.join(', ')}\n';
    final address = shop.address?.trim();
    if (address != null && address.isNotEmpty) return '📍 $address\n';
    return '';
  }

  static String _descriptionLine(Shop shop) {
    final desc = shop.description?.trim();
    if (desc == null || desc.isEmpty) return '';
    final short = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;
    return '💬 $short\n\n';
  }

  static String _verifiedLine(Shop shop) {
    if (!shop.isVerified) return '';
    return '✅ Boutique vérifiée UzaApp\n';
  }

  /// Message marketing pour partager le lien de la boutique.
  static String linkShare(Shop shop) {
    final url = ShopQrUtils.shopUrl(shop);
    return '✨ *${shop.name.toUpperCase()}* — Votre shopping commence ici ✨\n\n'
        '${_descriptionLine(shop)}'
        'Des produits soigneusement sélectionnés, des prix accessibles et un vendeur à votre écoute.\n\n'
        '🛍️ Parcourez notre catalogue\n'
        '💬 Écrivez-nous en direct sur WhatsApp\n'
        '🚚 Livraison & retrait selon disponibilité\n\n'
        '${_locationLine(shop)}'
        '${_verifiedLine(shop)}'
        '👉 *Découvrez la boutique :*\n$url\n\n'
        '📲 *UzaApp* — Le marché en ligne N°1 en RDC\n'
        'Achetez local. Vivez mieux. 🇨🇩\n\n'
        '#UzaApp #Boutique #Shopping #RDC #${shop.name.replaceAll(RegExp(r'\s+'), '')}';
  }

  /// Message marketing pour accompagner le QR code partagé.
  static String qrShare(Shop shop) {
    final url = ShopQrUtils.shopUrl(shop);
    return '📲 *${shop.name}* — Scannez & shoppez !\n\n'
        '${_descriptionLine(shop)}'
        'Un simple scan du QR code et vous êtes dans notre boutique UzaApp.\n'
        'Pas d\'appli compliquée : tout est à portée de main.\n\n'
        '🔍 Scannez l\'image du QR code\n'
        '🛍️ Découvrez nos produits & promos\n'
        '💬 Contactez-nous en un clic\n\n'
        '${_locationLine(shop)}'
        '${_verifiedLine(shop)}'
        '🔗 *Ou ouvrez ce lien :*\n$url\n\n'
        '📲 *UzaApp* — Votre marketplace locale en RDC\n'
        'Le commerce de proximité, digitalisé. 💪\n\n'
        '#UzaApp #QRCode #Boutique #RDC';
  }

  static String linkShareSubject(Shop shop) =>
      '✨ ${shop.name} — Boutique UzaApp';

  static String qrShareSubject(Shop shop) =>
      '📲 QR Code ${shop.name} | UzaApp';

  static String _productUrl(Product product) {
    final ref = (product.remoteId != null && product.remoteId!.isNotEmpty)
        ? product.remoteId!
        : product.id.toString();
    return 'https://uzaapp.com/product/$ref';
  }

  static String _productLine(Product product, int index) {
    final price = ProductPriceUtils.shareLine(product);
    return '$index. *${product.name.trim()}*\n   $price\n   🔗 ${_productUrl(product)}';
  }

  /// Catalogue texte : arrivages puis produits (sans infos boutique superflues).
  static String catalogShare(
    Shop shop, {
    required List<Product> arrivals,
    required List<Product> products,
    int? activeArrivageStories,
  }) {
    final shopUrl = ShopQrUtils.shopUrl(shop);
    final buf = StringBuffer();
    buf.writeln('📋 *CATALOGUE — ${shop.name.toUpperCase()}*');
    buf.writeln();

    if (arrivals.isNotEmpty) {
      buf.writeln('📦 *NOUVEAUX ARRIVAGES*');
      for (var i = 0; i < arrivals.length; i++) {
        buf.writeln(_productLine(arrivals[i], i + 1));
        if (i < arrivals.length - 1) buf.writeln();
      }
      if (activeArrivageStories != null && activeArrivageStories > 0) {
        buf.writeln();
        buf.writeln(
          '📸 $activeArrivageStories arrivage(s) en story sur UzaApp',
        );
      }
      buf.writeln();
    } else if (activeArrivageStories != null && activeArrivageStories > 0) {
      buf.writeln('📦 *ARRIVAGES*');
      buf.writeln(
        '$activeArrivageStories nouvel(le)s arrivage(s) — voir sur UzaApp',
      );
      buf.writeln();
    }

    if (products.isNotEmpty) {
      buf.writeln('🛍️ *PRODUITS*');
      for (var i = 0; i < products.length; i++) {
        buf.writeln(_productLine(products[i], i + 1));
        if (i < products.length - 1) buf.writeln();
      }
      buf.writeln();
    }

    if (arrivals.isEmpty && products.isEmpty) {
      buf.writeln('Aucun produit publié pour le moment.');
      buf.writeln();
    }

    buf.writeln('👉 *Boutique complète :*');
    buf.writeln(shopUrl);
    buf.writeln();
    buf.writeln('📲 *UzaApp* — Le marché local en RDC 🇨🇩');
    buf.writeln(
      '#UzaApp #Catalogue #${shop.name.replaceAll(RegExp(r'\s+'), '')}',
    );

    return buf.toString().trim();
  }

  static String catalogShareSubject(Shop shop) =>
      '📋 Catalogue ${shop.name} | UzaApp';
}
