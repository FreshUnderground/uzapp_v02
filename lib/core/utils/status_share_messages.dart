import '../../data/local/uza_database.dart';
import 'shop_qr_utils.dart';

/// Textes marketing d'accompagnement pour le partage de statuts WhatsApp (images produits).
class StatusShareMessages {
  StatusShareMessages._();

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

  static String _verifiedLine(Shop shop) {
    if (!shop.isVerified) return '';
    return '✅ Boutique vérifiée UzaApp\n';
  }

  static String _productCountLine(int? imageCount) {
    if (imageCount == null || imageCount <= 0) return '';
    final label = imageCount == 1 ? '1 nouveauté' : '$imageCount nouveautés';
    return '📸 $label à découvrir dans ce statut\n';
  }

  /// Message marketing pour accompagner la collection d'images statut.
  static String collectionShare(Shop shop, {int? imageCount}) {
    final url = ShopQrUtils.shopUrl(shop);
    return '🔥 *${shop.name.toUpperCase()}* — Nouveautés en ligne ! 🔥\n\n'
        '${_productCountLine(imageCount)}'
        'Vous aimez ce que vous voyez ? Chaque photo est un produit disponible *maintenant* sur UzaApp.\n\n'
        '✨ Qualité garantie\n'
        '💬 Contact direct avec le vendeur\n'
        '🛒 Commande simple en quelques clics\n\n'
        '${_locationLine(shop)}'
        '${_verifiedLine(shop)}'
        '👉 *Voir toute la boutique :*\n$url\n\n'
        '📲 *UzaApp* — Le marché en ligne N°1 en RDC\n'
        'Shoppez malin. Shoppez local. 💪\n\n'
        '#UzaApp #Nouveautés #WhatsAppStatus #RDC #${shop.name.replaceAll(RegExp(r'\s+'), '')}';
  }

  static String collectionShareSubject(Shop shop) =>
      '🔥 Nouveautés ${shop.name} | UzaApp';
}
