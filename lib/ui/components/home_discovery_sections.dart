import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/settings_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../utils/page_transitions.dart';
import '../screens/product_detail_screen.dart';
import '../screens/shop_profile_screen.dart';
import 'followed_sellers_section.dart';
import 'nearby_products_section.dart';

/// Followed sellers + nearby products (commune-based), collapsible in search.
class HomeDiscoverySections extends StatefulWidget {
  final bool initiallyExpanded;

  const HomeDiscoverySections({super.key, this.initiallyExpanded = false});

  @override
  State<HomeDiscoverySections> createState() => _HomeDiscoverySectionsState();
}

class _HomeDiscoverySectionsState extends State<HomeDiscoverySections> {
  late bool _expanded;
  List<Product> _nearbyProducts = [];
  Map<int, bool> _newByShop = {};
  bool _loadingNearby = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearby());
  }

  Future<void> _loadNearby() async {
    final settings = context.read<SettingsService>();
    final commune = settings.userCommune;
    if (commune == null || commune.isEmpty) {
      if (mounted) setState(() => _nearbyProducts = []);
      return;
    }
    setState(() => _loadingNearby = true);
    final products = await context.read<ProductRepository>().getNearbyProducts(
      commune,
      limit: 16,
    );
    if (mounted) {
      setState(() {
        _nearbyProducts = products;
        _loadingNearby = false;
      });
    }
  }

  Future<void> _refreshNewFlags(List<Shop> shops) async {
    if (shops.isEmpty) return;
    final productRepo = context.read<ProductRepository>();
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    final flags = <int, bool>{};
    for (final shop in shops) {
      final products = await productRepo.getProductsByShop(shop.id);
      flags[shop.id] = products.any((p) => p.updatedAt.isAfter(cutoff));
    }
    if (mounted) setState(() => _newByShop = flags);
  }

  Future<void> _pickCommune() async {
    final settings = context.read<SettingsService>();
    final picked = await CommunePickerSheet.show(
      context,
      currentCommune: settings.userCommune,
    );
    if (picked != null && picked.isNotEmpty) {
      await settings.setUserCommune(picked);
      await _loadNearby();
    }
  }

  void _openShop(Shop shop) {
    Navigator.push(
      context,
      SlideUpRoute(page: ShopProfileScreen(shop: shop)),
    );
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      SlideUpRoute(page: ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return StreamBuilder<List<Shop>>(
      stream: context.read<ShopRepository>().watchFollowedShops(),
      builder: (context, snapshot) {
        final followed = snapshot.data ?? [];
        if (followed.isNotEmpty && _newByShop.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _refreshNewFlags(followed),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UzaColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        color: UzaColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tes vendeurs & près de toi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: UzaColors.onSurfaceSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              FollowedSellersSection(
                followedShops: followed,
                hasNewProducts: _newByShop,
                onShopTap: _openShop,
              ),
              if (_loadingNearby && _nearbyProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                NearbyProductsSection(
                  userCommune: settings.userCommune,
                  nearbyProducts: _nearbyProducts,
                  onChangeCommune: _pickCommune,
                  onProductTap: _openProduct,
                ),
            ],
          ],
        );
      },
    );
  }
}
