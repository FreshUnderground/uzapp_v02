import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../components/verification_badge.dart';
import '../utils/page_transitions.dart';
import 'shop_profile_screen.dart';

enum _ShopFilter { all, verified, unverified }

class ShopsDirectoryScreen extends StatefulWidget {
  const ShopsDirectoryScreen({super.key});

  @override
  State<ShopsDirectoryScreen> createState() => _ShopsDirectoryScreenState();
}

class _ShopsDirectoryScreenState extends State<ShopsDirectoryScreen> {
  _ShopFilter _filter = _ShopFilter.all;

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.watch<ShopRepository>();
    final syncService = context.watch<SyncService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Boutiques'),
        backgroundColor: Colors.white,
        foregroundColor: UzaColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (syncService.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncNow();
        },
        child: Column(
          children: [
            // Filter chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _buildFilterChip('Toutes', _ShopFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('Certifiées', _ShopFilter.verified),
                  const SizedBox(width: 8),
                  _buildFilterChip('Non certifiées', _ShopFilter.unverified),
                ],
              ),
            ),
            const Divider(height: 1),
            // Shop grid
            Expanded(
              child: StreamBuilder<List<Shop>>(
                stream: shopRepo.watchAllShops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allShops = snapshot.data ?? [];
                  final shops = _applyFilter(allShops);

                  if (shops.isEmpty) {
                    return _buildEmptyState(allShops.isEmpty);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      return _ShopDirectoryCard(shop: shops[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, _ShopFilter filter) {
    final isSelected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? UzaColors.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : UzaColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Shop> _applyFilter(List<Shop> shops) {
    switch (_filter) {
      case _ShopFilter.verified:
        return shops.where((s) => s.isVerified).toList();
      case _ShopFilter.unverified:
        return shops.where((s) => !s.isVerified).toList();
      case _ShopFilter.all:
        return shops;
    }
  }

  Widget _buildEmptyState(bool trulyEmpty) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trulyEmpty
                          ? 'Aucune boutique disponible'
                          : 'Aucune boutique ne correspond à ce filtre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trulyEmpty
                          ? 'Tirez vers le bas pour synchroniser les boutiques'
                          : 'Essayez un autre filtre',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShopDirectoryCard extends StatelessWidget {
  final Shop shop;

  const _ShopDirectoryCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final location = _formatLocation();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SlideUpRoute(page: ShopProfileScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildShopImage(),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shop.type == ShopType.wholesale ? 'GROS' : 'DÉTAIL',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: UzaColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        VerificationBadge(
                          isVerified: shop.isVerified,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (location == null)
                      Text(
                        shop.description ?? 'Boutique locale',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopImage() {
    final raw = shop.logoUrl ?? '';
    final decrypted = raw.isNotEmpty ? CryptoUtils.decrypt(raw) : '';
    if (decrypted.isEmpty) {
      return Container(
        color: UzaColors.primary.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.store, size: 40, color: UzaColors.primary),
        ),
      );
    }
    return ImageUtils.buildCachedImage(decrypted, fit: BoxFit.cover);
  }

  String? _formatLocation() {
    final parts = <String>[];
    if (shop.city != null && shop.city!.isNotEmpty) {
      parts.add(shop.city!);
    }
    if (shop.commune != null && shop.commune!.isNotEmpty) {
      parts.add(shop.commune!);
    }
    if (shop.address != null && shop.address!.isNotEmpty && parts.isEmpty) {
      parts.add(shop.address!);
    }
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
