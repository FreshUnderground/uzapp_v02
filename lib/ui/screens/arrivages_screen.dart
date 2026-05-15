import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../components/custom_refresh_indicator.dart';
import '../utils/page_transitions.dart';
import 'story_view_screen.dart';

class ArrivagesScreen extends StatelessWidget {
  const ArrivagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storyRepo = context.watch<StoryRepository>();
    final syncService = context.read<SyncService>();
    final shopRepo = context.read<ShopRepository>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Arrivages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronisation en cours...'),
                  duration: Duration(seconds: 2),
                ),
              );
              // Force full sync
              await syncService.fullResetAndSync();
              // Show success
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Synchronisation terminée!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip: 'Forcer la synchronisation',
          ),
        ],
      ),
      body: StreamBuilder<List<Story>>(
        stream: storyRepo.watchActiveArrivages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildGridShimmer();
          }

          final stories = snapshot.data ?? [];

          if (stories.isEmpty) {
            return UzaRefreshIndicator(
              onRefresh: () => syncService.syncNow(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun arrivage pour le moment',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => syncService.syncNow(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return UzaRefreshIndicator(
            onRefresh: () => syncService.syncNow(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                    ? 3
                    : 2;

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    return _ArrivageStoryCard(
                      story: stories[index],
                      shopRepo: shopRepo,
                      allStories: stories,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

/// Card that displays an arrivage story with its media thumbnail and shop name.
class _ArrivageStoryCard extends StatelessWidget {
  final Story story;
  final ShopRepository shopRepo;
  final List<Story> allStories;

  const _ArrivageStoryCard({
    required this.story,
    required this.shopRepo,
    required this.allStories,
  });

  @override
  Widget build(BuildContext context) {
    final decryptedUrl = story.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(story.mediaUrl)
        : '';

    return GestureDetector(
      onTap: () => _openStory(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            if (decryptedUrl.isNotEmpty)
              Hero(
                tag: 'arrivage_image_${story.id}',
                child: ImageUtils.buildCachedImage(
                  decryptedUrl,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            else
              Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[400],
                  size: 36,
                ),
              ),

            // Gradient overlay at bottom for shop name
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: FutureBuilder<Shop?>(
                  future: shopRepo.getShopById(story.shopId),
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            snapshot.data?.name ?? 'Arrivage',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens StoryViewScreen with stories from the same shop.
  Future<void> _openStory(BuildContext context) async {
    final storyRepo = context.read<StoryRepository>();
    storyRepo.logStoryView(story.id);

    // Get all stories for this shop to enable swiping
    final shopStories = await storyRepo.getStoriesForShop(story.shopId);
    final shop = await shopRepo.getShopById(story.shopId);
    final shopLookup = <int, Shop>{};
    if (shop != null) {
      shopLookup[story.shopId] = shop;
    }

    final initialIndex = shopStories.indexWhere((s) => s.id == story.id);

    if (context.mounted) {
      Navigator.push(
        context,
        SlideUpRoute(
          page: StoryViewScreen(
            stories: shopStories,
            initialIndex: initialIndex >= 0 ? initialIndex : 0,
            shopLookup: shopLookup,
          ),
        ),
      );
    }
  }
}
