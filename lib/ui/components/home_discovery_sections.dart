import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../utils/page_transitions.dart';
import '../screens/product_detail_screen.dart';
import '../screens/shop_profile_screen.dart';
import 'followed_sellers_section.dart';
import 'nearby_products_section.dart';

/// Home sections: followed sellers + nearby products (commune-based).
class HomeDiscoverySections extends StatefulWidget {
  const HomeDiscoverySections({super.key});

  @override
  State<HomeDiscoverySections> createState() => _HomeDiscoverySectionsState();
}

class _HomeDiscoverySectionsState extends State<HomeDiscoverySections> {
  List<Product> _nearbyProducts = [];
  Map<int, bool> _newByShop = {};
  bool _loadingNearby = false;

  @override
  void initState() {
    super.initState();
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
          children: [
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
        );
      },
    );
  }
}
