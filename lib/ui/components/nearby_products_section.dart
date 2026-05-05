import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/location_data.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import 'modern_card.dart';
import 'tap_animator.dart';

/// Section showing "Près de toi" — nearby products from shops in the user's commune
class NearbyProductsSection extends StatelessWidget {
  final String? userCommune;
  final List<Product> nearbyProducts;
  final VoidCallback onChangeCommune;
  final Function(Product) onProductTap;

  const NearbyProductsSection({
    super.key,
    this.userCommune,
    required this.nearbyProducts,
    required this.onChangeCommune,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    // No commune set — show prompt
    if (userCommune == null || userCommune!.isEmpty) {
      return _buildNoCommunePrompt(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UzaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: UzaColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Près de toi',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'à $userCommune',
                      style: TextStyle(
                        color: UzaColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TapAnimator(
                onTap: onChangeCommune,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: UzaColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Changer',
                    style: TextStyle(
                      color: UzaColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Products list
        if (nearbyProducts.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nearbyProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _NearbyProductCard(
                  product: nearbyProducts[index],
                  onTap: () => onProductTap(nearbyProducts[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNoCommunePrompt(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UzaColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: UzaColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Définis ta zone',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Trouve les produits disponibles près de chez toi',
            style: TextStyle(color: UzaColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TapAnimator(
            onTap: onChangeCommune,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: UzaColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Choisir ma commune',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun produit trouvé près de $userCommune pour le moment',
                style: TextStyle(color: UzaColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact product card for the nearby section horizontal list
class _NearbyProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _NearbyProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final images = ImageUtils.getDecryptedList(product.imageUrls);
    final firstImage = images.isNotEmpty ? images.first : '';

    return TapAnimator(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: firstImage.isEmpty
                    ? ImageUtils.buildPlaceholder()
                    : ImageUtils.buildCachedImage(
                        firstImage,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.price != null && !product.hidePrice)
                    Text(
                      '${product.price!.toInt()} FC',
                      style: const TextStyle(
                        color: UzaColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Commune picker bottom sheet
class CommunePickerSheet extends StatefulWidget {
  final String? currentCommune;

  const CommunePickerSheet({super.key, this.currentCommune});

  /// Show the commune picker as a modal bottom sheet
  static Future<String?> show(BuildContext context, {String? currentCommune}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommunePickerSheet(currentCommune: currentCommune),
    );
  }

  @override
  State<CommunePickerSheet> createState() => _CommunePickerSheetState();
}

class _CommunePickerSheetState extends State<CommunePickerSheet> {
  String? _selectedCity;
  String? _selectedCommune;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentCommune != null) {
      _selectedCity = LocationData.getCityForCommune(widget.currentCommune!);
      _selectedCommune = widget.currentCommune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = LocationData.cities.keys.toList();
    final communes = _selectedCity != null
        ? LocationData.cities[_selectedCity]!
              .where(
                (c) =>
                    _searchQuery.isEmpty ||
                    c.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList()
        : <String>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: UzaColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Ta commune',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Spacer(),
                TapAnimator(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          // City chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = city == _selectedCity;
                return TapAnimator(
                  onTap: () => setState(() {
                    _selectedCity = city;
                    _searchQuery = '';
                    _selectedCommune = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? UzaColors.primary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      city,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : UzaColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Search
          if (_selectedCity != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Chercher une commune...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconColor: UzaColors.textSecondary,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          const SizedBox(height: 8),
          // Communes list
          if (_selectedCity != null)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: communes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final commune = communes[index];
                  final isSelected = commune == _selectedCommune;
                  return TapAnimator(
                    onTap: () {
                      setState(() => _selectedCommune = commune);
                      Navigator.pop(context, commune);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? UzaColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: UzaColors.primary.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.location_on_outlined,
                            color: isSelected
                                ? UzaColors.primary
                                : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            commune,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: isSelected
                                  ? UzaColors.primary
                                  : UzaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_selectedCity == null)
            Expanded(
              child: Center(
                child: Text(
                  'Choisis une ville d\'abord',
                  style: TextStyle(
                    color: UzaColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
