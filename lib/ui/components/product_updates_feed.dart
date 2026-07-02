import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/product_update_type.dart';
import '../../core/res/uza_colors.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_update_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../utils/page_transitions.dart';
import '../screens/product_detail_screen.dart';

/// Horizontal feed of recent public product updates.
class ProductUpdatesFeed extends StatelessWidget {
  const ProductUpdatesFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductUpdateRepository>();

    return StreamBuilder<List<ProductUpdate>>(
      stream: repo.watchRecent(limit: 15),
      builder: (context, snapshot) {
        final updates = snapshot.data ?? [];
        if (updates.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: UzaColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mises à jour récentes',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: UzaColors.onSurface(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: updates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final update = updates[index];
                  final type = ProductUpdateType.fromCode(update.updateType);
                  return _UpdateChip(
                    update: update,
                    type: type,
                    onTap: () async {
                      final product = await context
                          .read<ProductRepository>()
                          .getProductById(update.productId);
                      if (!context.mounted || product == null) return;
                      Navigator.push(
                        context,
                        SlideUpRoute(
                          page: ProductDetailScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _UpdateChip extends StatelessWidget {
  final ProductUpdate update;
  final ProductUpdateType type;
  final VoidCallback onTap;

  const _UpdateChip({
    required this.update,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: UzaColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${type.emoji} ${type.notificationTitle(update.productName)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: UzaColors.onSurface(context),
                ),
              ),
              const Spacer(),
              Text(
                update.shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: UzaColors.onSurfaceSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
