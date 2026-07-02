import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/product_price_utils.dart';
import '../../core/utils/product_promo_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import 'condition_badge.dart';
import 'uza_badge.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final String? condition;
  final String? shopPhone;
  final String? thumbnailUrl;
  final double? distanceKm;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.condition,
    this.shopPhone,
    this.thumbnailUrl,
    this.distanceKm,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final productRepo = context.read<ProductRepository>();
    final scheme = Theme.of(context).colorScheme;
    final onSurface = UzaColors.onSurface(context);
    final onSurfaceSecondary = UzaColors.onSurfaceSecondary(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          decoration: BoxDecoration(
            color: UzaColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(UzaColors.radiusSm),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(UzaColors.radiusSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(UzaColors.radiusSm),
                      ),
                      child: Hero(
                        tag: 'product_card_${widget.product.id}',
                        child: AspectRatio(
                          aspectRatio: 1.2,
                          child: ImageUtils.buildCachedFirstProductImage(
                            widget.product.imageUrls,
                            fit: BoxFit.cover,
                            thumbnailUrl: widget.thumbnailUrl,
                            memCacheWidth: 150,
                          ),
                        ),
                      ),
                    ),
                    if (widget.product.isArrival)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: UzaBadge(
                          label: tr(context, 'badge_new'),
                          color: UzaColors.secondary,
                        ),
                      ),
                    if (ProductPromoUtils.isFlashProduct(widget.product))
                      Positioned(
                        top: 8,
                        left: widget.product.isArrival ? 78 : 8,
                        child: UzaBadge(
                          label: tr(context, 'badge_promo'),
                          color: Colors.red,
                          icon: Icons.local_offer,
                        ),
                      ),
                    if (widget.product.viewsCount > 50)
                      Positioned(
                        top: 8,
                        right: 48,
                        child: UzaBadge(
                          label: tr(context, 'badge_high_demand'),
                          color: Colors.orange,
                          icon: FontAwesomeIcons.fire,
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: StreamBuilder<bool>(
                        stream: productRepo.watchIsInWishlist(widget.product.id),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data ?? false;
                          return Semantics(
                            label: tr(context, 'wishlist'),
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => productRepo.toggleWishlist(
                                  widget.product.id,
                                ),
                                customBorder: const CircleBorder(),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSaved
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 14,
                                        color: isSaved
                                            ? Colors.red
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.product.viewsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ProductPriceUtils.displayLabel(widget.product),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ProductPriceUtils.hasVisiblePrice(
                            widget.product,
                          )
                              ? scheme.primary
                              : onSurfaceSecondary,
                        ),
                      ),
                      if (widget.condition != null &&
                          widget.condition != 'new') ...[
                        const SizedBox(height: 4),
                        ConditionBadge(condition: widget.condition),
                      ],
                      const SizedBox(height: 4),
                      FutureBuilder<Shop?>(
                        future: productRepo.resolveShopForProduct(widget.product),
                        builder: (context, snapshot) {
                          final shop = snapshot.data;
                          if (shop == null || shop.name.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final address = shop.address?.trim();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      shop.name,
                                      style: TextStyle(
                                        color: onSurfaceSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.distanceKm != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '~${_formatDistance(widget.distanceKm!)}',
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (address != null && address.isNotEmpty)
                                Text(
                                  address,
                                  style: TextStyle(
                                    color: onSurfaceSecondary.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }
}
