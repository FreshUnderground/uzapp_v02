import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../data/repositories/recently_viewed_repository.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';

class RecentlyViewedSection extends StatelessWidget {
  final List<RecentlyViewedItem> items;
  final Function(RecentlyViewedItem) onItemTap;
  final VoidCallback onClear;

  const RecentlyViewedSection({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: Text(tr(context, 'clear')),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, RecentlyViewedItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 120,
        child: InkWell(
          onTap: () => onItemTap(item),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ImageUtils.buildCachedImage(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: Container(color: Colors.grey[200]),
                          errorWidget: Icon(
                            item.type == 'shop' ? Icons.store : Icons.image,
                            color: Colors.grey[400],
                          ),
                        )
                      : Center(
                          child: Icon(
                            item.type == 'shop' ? Icons.store : Icons.image,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.price != null && item.price!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.price!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: UzaColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
