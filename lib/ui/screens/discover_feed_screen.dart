import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../core/res/uza_colors.dart';
import '../utils/page_transitions.dart';
import '../components/shop_video_player.dart';
import 'product_detail_screen.dart';
import 'story_view_screen.dart';
import 'arrivages_screen.dart';
import 'shops_directory_screen.dart';
import 'shop_profile_screen.dart';
import 'dart:ui';
import 'dart:math';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  final PageController _pageController = PageController();
  List<dynamic> _mixedFeed = [];
  final Random _random = Random();
  bool _hasInitializedFeed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Shuffle and mix products and arrivages randomly
  void _updateMixedFeed(
    List<Product> products,
    Map<int, List<Story>> arrivageGroups,
  ) {
    // Check if we actually need to update
    final totalItems =
        products.length +
        arrivageGroups.values.fold<int>(0, (sum, list) => sum + list.length);

    if (_hasInitializedFeed && _mixedFeed.length == totalItems) {
      return; // No change, skip update
    }

    final mixed = <dynamic>[];

    // Flatten arrivages
    final allArrivages = <Story>[];
    for (final stories in arrivageGroups.values) {
      allArrivages.addAll(stories);
    }

    // Add all products and arrivages to mixed list
    mixed.addAll(products);
    mixed.addAll(allArrivages);

    // Shuffle randomly (TikTok style)
    for (var i = mixed.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = mixed[i];
      mixed[i] = mixed[j];
      mixed[j] = temp;
    }

    debugPrint(
      'DiscoverFeed: Updating feed with ${mixed.length} items (${products.length} products, ${allArrivages.length} arrivages)',
    );

    setState(() {
      _mixedFeed = mixed;
      _hasInitializedFeed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final storyRepo = context.watch<StoryRepository>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Product>>(
        stream: productRepo.watchTrendingProducts(limit: 50),
        builder: (context, productSnapshot) {
          return StreamBuilder<Map<int, List<Story>>>(
            stream: storyRepo.watchArrivagesGroupedByShop(),
            builder: (context, arrivageSnapshot) {
              final products = productSnapshot.data ?? [];
              final arrivageGroups = arrivageSnapshot.data ?? {};

              if (productSnapshot.connectionState == ConnectionState.waiting &&
                  arrivageSnapshot.connectionState == ConnectionState.waiting &&
                  !_hasInitializedFeed) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              // Update feed when data changes or on first load
              // Must be deferred to avoid setState during build
              if (!_hasInitializedFeed || _mixedFeed.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _updateMixedFeed(products, arrivageGroups);
                  }
                });
              }

              if (_mixedFeed.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune d\u00e9couverte pour le moment',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // TikTok-style full-screen vertical scroll
              return PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(),
                pageSnapping: true,
                itemCount: _mixedFeed.length,
                itemBuilder: (context, index) {
                  final item = _mixedFeed[index];

                  if (item is Product) {
                    return _DiscoverItem(product: item);
                  } else if (item is Story) {
                    // Full-screen TikTok-style arrivage display
                    return _FullArrivageStoryItem(
                      story: item,
                      allShopStories: arrivageGroups[item.shopId] ?? [item],
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the Arrivages vertical scroll section with header.
  Widget _buildArrivagesSection(Map<int, List<Story>> grouped) {
    // Flatten all arrivage stories into a single list for vertical grid
    final allArrivageStories = <Story>[];
    for (final stories in grouped.values) {
      allArrivageStories.addAll(stories);
    }

    return Container(
      color: Colors.black,
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: UzaColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Arrivages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    SlideUpRoute(page: const ArrivagesScreen()),
                  ),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      color: UzaColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vertical scrollable grid of arrivage cards
          Expanded(
            child: GridView.builder(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: allArrivageStories.length.clamp(0, 6),
              itemBuilder: (context, index) {
                final story = allArrivageStories[index];
                return _ArrivageFeedCard(
                  story: story,
                  shopStories: grouped[story.shopId] ?? [story],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Builds the Boutiques horizontal scroll section with header.
  Widget _buildBoutiquesSection(List<Shop> shops) {
    final featured = shops.take(8).toList();

    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: UzaColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Boutiques',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    SlideUpRoute(page: const ShopsDirectoryScreen()),
                  ),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      color: UzaColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Horizontal scroll of shop avatars
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: featured.length,
              itemBuilder: (context, index) {
                final shop = featured[index];
                return _FeaturedShopAvatar(shop: shop);
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A single arrivage card in the horizontal list.
class _ArrivageFeedCard extends StatelessWidget {
  final Story story;
  final List<Story> shopStories;

  const _ArrivageFeedCard({required this.story, required this.shopStories});

  @override
  Widget build(BuildContext context) {
    final decryptedUrl = story.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(story.mediaUrl)
        : '';

    return GestureDetector(
      onTap: () {
        final storyRepo = context.read<StoryRepository>();
        storyRepo.logStoryView(story.id);
        final shopRepo = context.read<ShopRepository>();
        _openStoryWithShopLookup(context, shopRepo);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (decryptedUrl.isNotEmpty)
                ImageUtils.buildCachedImage(decryptedUrl, fit: BoxFit.cover)
              else
                Container(
                  color: Colors.grey[800],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[600],
                  ),
                ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Shop info at bottom
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Row(
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
                        color: UzaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FutureBuilder<Shop?>(
                        future: context.read<ShopRepository>().getShopById(
                          story.shopId,
                        ),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data?.name ?? '...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    if (shopStories.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: UzaColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${shopStories.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open StoryViewScreen after fetching shop data for the lookup map.
  Future<void> _openStoryWithShopLookup(
    BuildContext context,
    ShopRepository shopRepo,
  ) async {
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

/// A small circular shop avatar for the Boutiques horizontal list.
class _FeaturedShopAvatar extends StatelessWidget {
  final Shop shop;

  const _FeaturedShopAvatar({required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SlideUpRoute(page: ShopProfileScreen(shop: shop)),
        );
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: UzaColors.secondary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: ImageUtils.getLogoWidget(
                  shop.logoUrl,
                  size: 64,
                  fallbackIcon: Icons.store,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              shop.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
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

class _DiscoverItem extends StatefulWidget {
  final Product product;
  const _DiscoverItem({required this.product});

  @override
  State<_DiscoverItem> createState() => _DiscoverItemState();
}

class _DiscoverItemState extends State<_DiscoverItem> {
  Shop? _shop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final shopRepo = context.read<ShopRepository>();
    final shop = await shopRepo.getShopById(widget.product.shopId);
    if (mounted) {
      setState(() {
        _shop = shop;
      });
    }
  }

  String get _firstImage {
    final images = ImageUtils.getDecryptedList(widget.product.imageUrls);
    return images.isNotEmpty ? images.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    // Decrypt video URL if available
    String? decryptedVideoUrl;
    if (_shop?.videoUrl != null && _shop!.videoUrl!.isNotEmpty) {
      decryptedVideoUrl = CryptoUtils.decrypt(_shop!.videoUrl!);
    }

    final backgroundWidget = decryptedVideoUrl != null
        ? _buildVideoBackground(decryptedVideoUrl)
        : ImageUtils.buildCachedImage(_firstImage, fit: BoxFit.cover);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. BLURRED BACKDROP (Web only)
        if (isWide) ...[
          backgroundWidget,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ],

        // 2. MAIN CONTENT FRAME
        Center(
          child: Container(
            constraints: isWide ? const BoxConstraints(maxWidth: 450) : null,
            decoration: isWide
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                backgroundWidget,

                // Darkened overlay for readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                ),

                // Product Info (Bottom Left)
                Positioned(
                  left: 16,
                  bottom: 40,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.product.description != null)
                        Text(
                          widget.product.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _shop?.name ?? '...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons (Right)
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: Column(
                    children: [
                      StreamBuilder<bool>(
                        stream: context
                            .read<ProductRepository>()
                            .watchIsInWishlist(widget.product.id),
                        builder: (context, snapshot) {
                          final isInWishlist = snapshot.data ?? false;
                          return _buildActionButton(
                            icon: isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: 'J\'aime',
                            color: isInWishlist ? Colors.red : Colors.white,
                            onTap: () => context
                                .read<ProductRepository>()
                                .toggleWishlist(widget.product.id),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: FontAwesomeIcons.whatsapp,
                        label: 'WhatsApp',
                        color: Colors.green,
                        onTap: () {
                          if (_shop?.whatsapp != null) {
                            context.read<ContactService>().launchWhatsApp(
                              phone: _shop!.whatsapp!,
                              entityType: 'product',
                              entityId: widget.product.id,
                              name: widget.product.name,
                              imageUrl: _firstImage,
                              productUrl:
                                  'https://uzaapp.com/product/${widget.product.id}',
                              price: widget.product.price,
                              condition: widget.product.condition,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Partager',
                        onTap: () => context
                            .read<ContactService>()
                            .shareProduct(widget.product, null),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.info_outline,
                        label: 'Détails',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: widget.product),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoBackground(String videoUrl) {
    return ShopVideoPlayer(
      videoUrl: videoUrl,
      isBackground:
          true, // We'll need to add this flag to the player if we want auto-loop/mute
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          radius: 25,
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                icon,
                key: ValueKey(icon.codePoint),
                color: color,
                size: 24,
              ),
            ),
            onPressed: onTap,
            tooltip: label, // Accessibility
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Full-screen TikTok-style arrivage story display
class _FullArrivageStoryItem extends StatefulWidget {
  final Story story;
  final List<Story> allShopStories;

  const _FullArrivageStoryItem({
    required this.story,
    required this.allShopStories,
  });

  @override
  State<_FullArrivageStoryItem> createState() => _FullArrivageStoryItemState();
}

class _FullArrivageStoryItemState extends State<_FullArrivageStoryItem> {
  int _currentImageIndex = 0;
  late List<Story> _stories;

  @override
  void initState() {
    super.initState();
    _stories = widget.allShopStories;
    _currentImageIndex = _stories.indexWhere((s) => s.id == widget.story.id);
    if (_currentImageIndex < 0) _currentImageIndex = 0;
  }

  void _goToNextImage() {
    if (_currentImageIndex < _stories.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  void _goToPreviousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = _stories[_currentImageIndex];
    final decryptedUrl = currentStory.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(currentStory.mediaUrl)
        : '';

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen image
          if (decryptedUrl.isNotEmpty)
            GestureDetector(
              onTap: _goToNextImage,
              child: ImageUtils.buildCachedImage(
                decryptedUrl,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),

          // Tap zones for navigation
          Positioned.fill(
            child: Row(
              children: [
                // Left side - previous
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _goToPreviousImage,
                    child: Container(),
                  ),
                ),
                // Right side - next
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _goToNextImage,
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),

          // Top gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Bottom gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Image counter (if multiple images)
          if (_stories.length > 1)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${_stories.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Image navigation dots
          if (_stories.length > 1)
            Positioned(
              top: 60,
              left: 20,
              right: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_stories.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _currentImageIndex == index ? 20 : 8,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),

          // Shop info at bottom
          Positioned(
            left: 20,
            right: 80,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop name
                FutureBuilder<Shop?>(
                  future: context.read<ShopRepository>().getShopById(
                    currentStory.shopId,
                  ),
                  builder: (context, snapshot) {
                    final shop = snapshot.data;
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: UzaColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 20,
                            color: UzaColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop?.name ?? 'Boutique',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Arrivage',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Action buttons on right side
          Positioned(
            right: 20,
            bottom: 40,
            child: Column(
              children: [
                _ActionIcon(
                  icon: Icons.storefront,
                  label: 'Boutique',
                  onTap: () {
                    context
                        .read<ShopRepository>()
                        .getShopById(currentStory.shopId)
                        .then((shop) {
                          if (context.mounted && shop != null) {
                            Navigator.push(
                              context,
                              SlideUpRoute(page: ShopProfileScreen(shop: shop)),
                            );
                          }
                        });
                  },
                ),
                const SizedBox(height: 20),
                _ActionIcon(
                  icon: Icons.arrow_upward,
                  label: 'Suivant',
                  onTap: _goToNextImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action icon button for arrivage overlay
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
