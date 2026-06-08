import '../../data/local/uza_database.dart';
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
}
