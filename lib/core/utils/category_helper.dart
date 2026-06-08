import '../../data/local/uza_database.dart';

/// Helper utility to map categories to form types and display types.
/// This ensures consistency between product creation forms and product detail displays.
class CategoryHelper {
  static const String autreRootRemoteId = 'cat_autre';
  static const int newCustomCategorySentinel = -1;

  /// True when [cat] is the root « Autre » category.
  static bool isAutreRoot(Category? cat) {
    if (cat == null || cat.level != 0) return false;
    if (cat.remoteId == autreRootRemoteId) return true;
    return cat.name.toLowerCase().contains('autre');
  }

  /// Server-side id for a category (remoteId when numeric, else local id).
  static int serverIdFor(Category cat) {
    final parsed = int.tryParse(cat.remoteId ?? '');
    return parsed ?? cat.id;
  }

  /// True when [category] is a user-contributed child under « Autre ».
  static bool isAutreChild(Category? category, Category? autreRoot) {
    if (category == null || autreRoot == null) return false;
    if (isAutreRoot(category)) return false;
    final autreServerId = serverIdFor(autreRoot);
    return category.parentId == autreRoot.id ||
        category.parentId == autreServerId;
  }

  /// Resolve the « Autre » root from a list of categories.
  static Category? findAutreRoot(Iterable<Category> categories) {
    for (final cat in categories) {
      if (isAutreRoot(cat)) return cat;
    }
    return null;
  }

  /// Maps a category to its form type for product creation/editing.
  static String getFormType(
    Category? category, {
    Category? autreRoot,
    Iterable<Category>? allCategories,
  }) {
    final root =
        autreRoot ??
        (allCategories != null ? findAutreRoot(allCategories) : null);

    if (root != null && isAutreChild(category, root)) {
      return 'autre';
    }

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
      case 'autre':
        return 'Autre';
      default:
        return 'Produit';
    }
  }
}
