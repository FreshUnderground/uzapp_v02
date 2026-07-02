/// Types of public product updates merchants can publish.
enum ProductUpdateType {
  arrivage('arrivage', 'Nouvel arrivage', '📦'),
  restock('restock', 'De retour en stock', '✅'),
  price('price', 'Prix modifié', '💰'),
  photos('photos', 'Nouvelles photos', '📸'),
  note('note', 'Mise à jour', '🔔');

  const ProductUpdateType(this.code, this.label, this.emoji);

  final String code;
  final String label;
  final String emoji;

  static ProductUpdateType fromCode(String? code) {
    return ProductUpdateType.values.firstWhere(
      (t) => t.code == code,
      orElse: () => ProductUpdateType.note,
    );
  }

  String notificationTitle(String productName) {
    switch (this) {
      case ProductUpdateType.arrivage:
        return 'Nouvel arrivage : $productName';
      case ProductUpdateType.restock:
        return 'De retour en stock : $productName';
      case ProductUpdateType.price:
        return 'Prix mis à jour : $productName';
      case ProductUpdateType.photos:
        return 'Nouvelles photos : $productName';
      case ProductUpdateType.note:
        return 'Mise à jour : $productName';
    }
  }

  String notificationBody(String shopName, {String? message}) {
    if (message != null && message.trim().isNotEmpty) {
      return '$message — chez $shopName';
    }
    return 'Disponible chez $shopName';
  }
}
