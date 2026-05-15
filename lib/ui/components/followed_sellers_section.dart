import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/crypto_utils.dart';
import 'tap_animator.dart';

/// Section showing "Tes vendeurs" — horizontal scroll of followed shop circles
class FollowedSellersSection extends StatelessWidget {
  final List<Shop> followedShops;
  final Map<int, bool> hasNewProducts; // shopId -> has new products in 48h
  final Function(Shop) onShopTap;

  const FollowedSellersSection({
    super.key,
    required this.followedShops,
    required this.hasNewProducts,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: UzaColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: UzaColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tes vendeurs',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        // Shop circles or empty state
        if (followedShops.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: followedShops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final shop = followedShops[index];
                final isNew = hasNewProducts[shop.id] ?? false;
                return _SellerCircle(
                  shop: shop,
                  hasNew: isNew,
                  onTap: () => onShopTap(shop),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UzaColors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: UzaColors.secondary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_add_outlined,
              color: UzaColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Suis des vendeurs pour voir leurs nouveautés ici',
                style: TextStyle(
                  color: UzaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular avatar for a followed shop
class _SellerCircle extends StatelessWidget {
  final Shop shop;
  final bool hasNew;
  final VoidCallback onTap;

  const _SellerCircle({
    required this.shop,
    required this.hasNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapAnimator(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            // Avatar with optional NEW badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasNew
                        ? Border.all(color: UzaColors.primary, width: 2.5)
                        : Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                    boxShadow: hasNew
                        ? [
                            BoxShadow(
                              color: UzaColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: () {
                      if (shop.logoUrl == null || shop.logoUrl!.isEmpty) {
                        return null;
                      }
                      final decrypted = CryptoUtils.decrypt(shop.logoUrl!);
                      if (decrypted.isEmpty ||
                          (!decrypted.startsWith('http://') &&
                              !decrypted.startsWith('https://'))) {
                        return null;
                      }
                      return CachedNetworkImageProvider(decrypted)
                          as ImageProvider;
                    }(),
                    child: (shop.logoUrl == null || shop.logoUrl!.isEmpty)
                        ? Icon(
                            Icons.store,
                            size: 24,
                            color: UzaColors.secondary.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                ),
                // NEW badge
                if (hasNew)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: UzaColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: UzaColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Shop name
            Text(
              shop.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
