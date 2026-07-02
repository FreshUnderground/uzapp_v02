/// Préfixes texte pour messages WhatsApp / partage (sans emoji).
///
/// Les emoji s'affichent parfois en caractères sur WhatsApp Web,
/// certains Android ou lors du copier-coller depuis la PWA.
class ShareMessageLabels {
  ShareMessageLabels._();

  static String productTitle(String name) => '*${name.toUpperCase()}*';

  static String promo(String text) => '> $text';

  static String description(String text) => '• $text';

  static String category(String text) => '• Catégorie : $text';

  static String conditionNew() => '• État : Neuf';

  static String conditionUsed() => '• État : Occasion';

  static String price(String amount) => '• Prix : $amount';

  static String priceDiscuss() => 'Prix à discuter';

  static String shop(String name) => '• Boutique : $name';

  static String location(String text) => '• $text';

  static String verifiedShop() => '• Boutique vérifiée UzaApp';

  static String productLink(String url) => '>> Voir le produit :\n$url';

  static String shopLink(String url) => '>> Voir la boutique :\n$url';

  static String arrivageTitle(String name) => '*${name.toUpperCase()}*';

  static const footerBody =
      'Des milliers de produits disponibles près de chez vous !\n'
      'Téléchargez UzaApp — Le marché en ligne N°1 en RDC';

  static const footerCatalog = '---\n$footerBody';

  static const hashtagsShopping = '#UzaApp #Shopping #RDC #Kinshasa';

  static const hashtagsShop = '#UzaApp #Boutique #Shopping #RDC';

  static const hashtagsArrivage = '#UzaApp #Arrivage #Shopping #RDC';
}
