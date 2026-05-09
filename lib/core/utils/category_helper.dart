import '../../data/local/uza_database.dart';

/// Helper utility to map categories to form types and display types.
/// This ensures consistency between product creation forms and product detail displays.
class CategoryHelper {
  /// Maps a category to its form type for product creation/editing.
  static String getFormType(Category? category) {
    if (category == null) return 'generic';
    final name = category.name.toLowerCase();

    // Auto/Vehicles
    if (name.contains('auto') ||
        name.contains('vehicule') ||
        name.contains('voiture') ||
        name.contains('location') ||
        name.contains('moto') ||
        name.contains('camion')) {
      return 'vehicule';
    }

    // Restaurant/Food
    if (name.contains('restau') ||
        name.contains('food') ||
        name.contains('aliment') ||
        name.contains('take away') ||
        name.contains('fast food') ||
        name.contains('livraison')) {
      return 'restaurant';
    }

    // Phones/Tablets
    if (name.contains('phone') ||
        name.contains('tablet') ||
        name.contains('téléphone') ||
        name.contains('iphone') ||
        name.contains('samsung') ||
        name.contains('tecno')) {
      return 'phone';
    }

    // Informatique/Computers
    if (name.contains('ordi') ||
        name.contains('computer') ||
        name.contains('laptop') ||
        name.contains('desktop') ||
        name.contains('imprimante') ||
        name.contains('composant') ||
        name.contains('logiciel') ||
        name.contains('reseau')) {
      return 'informatique';
    }

    // Gadgets/Electronics
    if (name.contains('gadget') ||
        name.contains('montre') ||
        name.contains('audio') ||
        name.contains('camera') ||
        name.contains('drone') ||
        name.contains('gaming') ||
        name.contains('power bank')) {
      return 'gadget';
    }

    // Style/Fashion/Clothing
    if (name.contains('style') ||
        name.contains('habillement') ||
        name.contains('fashion') ||
        name.contains('vetement') ||
        name.contains('homme') ||
        name.contains('femme') ||
        name.contains('enfant') ||
        name.contains('chaussure')) {
      return 'style';
    }

    return 'generic';
  }

  /// Gets a user-friendly display name for a category type.
  static String getCategoryTypeDisplayName(String formType) {
    switch (formType) {
      case 'vehicule':
        return 'Véhicule';
      case 'restaurant':
        return 'Restaurant';
      case 'phone':
        return 'Téléphone/Tablette';
      case 'informatique':
        return 'Informatique';
      case 'gadget':
        return 'Gadget';
      case 'style':
        return 'Style/Habillement';
      default:
        return 'Produit';
    }
  }
}
