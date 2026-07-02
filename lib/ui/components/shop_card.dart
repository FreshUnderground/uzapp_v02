import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import 'verification_badge.dart';
import 'seller_activity.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopCard({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: _buildShopCover(),
                    ),
                  ),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ImageUtils.getLogoWidget(shop.logoUrl, size: 56),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shop.type == ShopType.wholesale
                            ? tr(context, 'shop_wholesale')
                            : tr(context, 'shop_retail'),
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            shop.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 4),
                        VerificationBadge(isVerified: shop.isVerified),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.description ?? "Boutique locale",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (shop.responseTimeMinutes != null) ...[
                      const SizedBox(height: 4),
                      SellerActivityIndicator(
                        responseTimeMinutes: shop.responseTimeMinutes,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCover() {
    final coverSource = ImageUtils.getShopCoverSource(
      shop.bannerUrl,
      shop.logoUrl,
    );
    if (coverSource != null) {
      return ImageUtils.buildCachedImage(
        coverSource,
        fit: BoxFit.cover,
        errorWidget: _shopCoverFallback(),
      );
    }
    return _shopCoverFallback();
  }

  Widget _shopCoverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UzaColors.primary.withValues(alpha: 0.85),
            UzaColors.secondary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront, size: 40, color: Colors.white70),
      ),
    );
  }
}
