import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/utils/image_utils.dart';
import '../../core/res/uza_colors.dart';
import 'condition_badge.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final String? condition;
  final String? shopPhone;
  final String? thumbnailUrl;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.condition,
    this.shopPhone,
    this.thumbnailUrl,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.read<ShopRepository>();
    final productRepo = context.read<ProductRepository>();

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
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: AspectRatio(
                          aspectRatio: 1.35,
                          child: Builder(
                            builder: (context) {
                              final images = ImageUtils.getDecryptedList(
                                widget.product.imageUrls,
                              );
                              final firstImage = images.isNotEmpty
                                  ? images.first
                                  : '';
                              if (firstImage.isEmpty)
                                return ImageUtils.buildPlaceholder();
                              return ImageUtils.buildCachedImage(
                                firstImage,
                                fit: BoxFit.cover,
                                thumbnailUrl: widget.thumbnailUrl,
                                memCacheWidth: 200,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Top Badges
                    if (widget.product.isArrival)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildBadge('NOUVEAU', UzaColors.secondary),
                      ),
                    if (widget.product.viewsCount > 50)
                      Positioned(
                        top: 12,
                        right: 44,
                        child: _buildBadge(
                          'TRÈS DEMANDÉ',
                          Colors.orange,
                          icon: FontAwesomeIcons.fire,
                        ),
                      ),
                    // Top Right: Favorite Heart (always visible, subtle)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: StreamBuilder<bool>(
                        stream: productRepo.watchIsInWishlist(
                          widget.product.id,
                        ),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data ?? false;
                          return GestureDetector(
                            onTap: () =>
                                productRepo.toggleWishlist(widget.product.id),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 13,
                                color: isSaved ? Colors.red : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom Left: Views Badge (subtle)
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
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.product.viewsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Info Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 9.5,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.condition != null &&
                          widget.condition != 'new') ...[
                        const SizedBox(height: 2),
                        ConditionBadge(condition: widget.condition),
                      ],
                      const SizedBox(height: 3),
                      // Shop Name (subtle, no logo)
                      FutureBuilder<Shop?>(
                        future: shopRepo.getShopById(widget.product.shopId),
                        builder: (context, snapshot) {
                          final shop = snapshot.data;
                          if (shop == null || shop.name.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            shop.name,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
