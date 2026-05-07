import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../screens/story_view_screen.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/crypto_utils.dart';

class StoryFeedScreen extends StatelessWidget {
  final Function(List<Story>, int)? onOpenStory;
  final bool isCompact;
  final VoidCallback? onCreateStory;
  final int? currentUserId;

  const StoryFeedScreen({
    super.key,
    this.onOpenStory,
    this.isCompact = false,
    this.onCreateStory,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final storyRepo = context.watch<StoryRepository>();

    return StreamBuilder<Map<int, List<Story>>>(
      stream: storyRepo.watchStoriesGroupedByShop(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pas de stories pour le moment',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final groupedStories = snapshot.data!;
        final shopIds = groupedStories.keys.toList();

        if (isCompact) {
          return _CompactStoryFeed(
            groupedStories: groupedStories,
            shopIds: shopIds,
            onOpenStory: onOpenStory,
            onCreateStory: onCreateStory,
          );
        }

        return _FullStoryFeed(
          groupedStories: groupedStories,
          shopIds: shopIds,
          onOpenStory: onOpenStory,
        );
      },
    );
  }
}

/// Compact horizontal story feed with one circle per shop.
class _CompactStoryFeed extends StatelessWidget {
  final Map<int, List<Story>> groupedStories;
  final List<int> shopIds;
  final Function(List<Story>, int)? onOpenStory;
  final VoidCallback? onCreateStory;

  const _CompactStoryFeed({
    required this.groupedStories,
    required this.shopIds,
    this.onOpenStory,
    this.onCreateStory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // +1 for the "add story" circle at the beginning
      itemCount: shopIds.length + 1,
      itemBuilder: (context, index) {
        // First item: "Add story" circle
        if (index == 0) {
          return _AddStoryCircle(onTap: onCreateStory);
        }

        final shopId = shopIds[index - 1];
        final stories = groupedStories[shopId]!;
        final firstStory = stories.first;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _handleShopTap(context, stories),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [UzaColors.primary, UzaColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UzaColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        firstStory.mediaUrl.isNotEmpty
                            ? CryptoUtils.decrypt(firstStory.mediaUrl)
                            : '',
                      ),
                      child: firstStory.mediaType == 'video'
                          ? const Positioned(
                              right: 0,
                              bottom: 0,
                              child: Icon(
                                Icons.play_arrow,
                                color: UzaColors.primary,
                                size: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: FutureBuilder<Shop?>(
                  future: context.read<ShopRepository>().getShopById(shopId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data?.name ?? '...',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShopTap(BuildContext context, List<Story> stories) {
    final storyRepo = context.read<StoryRepository>();
    // Log view for the first story
    storyRepo.logStoryView(stories.first.id);

    if (onOpenStory != null) {
      onOpenStory!(stories, 0);
    } else {
      _openStoryViewer(context, stories, 0);
    }
  }

  void _openStoryViewer(
    BuildContext context,
    List<Story> stories,
    int index,
  ) async {
    // Pre-fetch shop data for all stories in this group
    final shopRepo = context.read<ShopRepository>();
    final storyRepo = context.read<StoryRepository>();
    final shopIds = stories.map((s) => s.shopId).toSet();
    final shopLookup = <int, Shop>{};
    for (final id in shopIds) {
      final shop = await shopRepo.getShopById(id);
      if (shop != null) shopLookup[id] = shop;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewScreen(
            stories: stories,
            initialIndex: index,
            shopLookup: shopLookup,
            getViewCount: storyRepo.getStoryViewCount,
          ),
        ),
      );
    }
  }
}

/// "Add story" circle with dashed border and plus icon.
class _AddStoryCircle extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddStoryCircle({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: Colors.grey.withValues(alpha: 0.5),
                strokeWidth: 2,
                dashGap: 4,
              ),
              child: Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.grey[500], size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              'Ma story',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed circle border.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashGap;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashGap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const dashLength = 6.0;
    final circumference = 2 * 3.14159265 * radius;
    final dashCount = (circumference / (dashLength + dashGap)).floor();

    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + dashGap)) / radius;
      final sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashGap != dashGap;
  }
}

/// Full (grid) story feed.
class _FullStoryFeed extends StatelessWidget {
  final Map<int, List<Story>> groupedStories;
  final List<int> shopIds;
  final Function(List<Story>, int)? onOpenStory;

  const _FullStoryFeed({
    required this.groupedStories,
    required this.shopIds,
    this.onOpenStory,
  });

  String _formatTime(DateTime time) {
    // If time is in UTC (from server), convert to local for accurate diff
    final localTime = time.isUtc ? time.toLocal() : time;
    final diff = DateTime.now().difference(localTime);
    if (diff.isNegative) return "À l'instant";
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: shopIds.length,
          itemBuilder: (context, index) {
            final shopId = shopIds[index];
            final stories = groupedStories[shopId]!;
            final firstStory = stories.first;

            return GestureDetector(
              onTap: () => _handleShopTap(context, stories),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(
                      firstStory.mediaUrl.isNotEmpty
                          ? CryptoUtils.decrypt(firstStory.mediaUrl)
                          : '',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: UzaColors.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: UzaColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<Shop?>(
                              future: context
                                  .read<ShopRepository>()
                                  .getShopById(shopId),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data?.name ?? 'Boutique',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          // Story count badge
                          if (stories.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: UzaColors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${stories.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(firstStory.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleShopTap(BuildContext context, List<Story> stories) {
    final storyRepo = context.read<StoryRepository>();
    storyRepo.logStoryView(stories.first.id);

    if (onOpenStory != null) {
      onOpenStory!(stories, 0);
    } else {
      _openStoryViewer(context, stories, 0);
    }
  }

  void _openStoryViewer(
    BuildContext context,
    List<Story> stories,
    int index,
  ) async {
    final shopRepo = context.read<ShopRepository>();
    final storyRepo = context.read<StoryRepository>();
    final shopIds = stories.map((s) => s.shopId).toSet();
    final shopLookup = <int, Shop>{};
    for (final id in shopIds) {
      final shop = await shopRepo.getShopById(id);
      if (shop != null) shopLookup[id] = shop;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewScreen(
            stories: stories,
            initialIndex: index,
            shopLookup: shopLookup,
            getViewCount: storyRepo.getStoryViewCount,
          ),
        ),
      );
    }
  }
}
