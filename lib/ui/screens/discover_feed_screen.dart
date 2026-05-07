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

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final storyRepo = context.watch<StoryRepository>();
    final shopRepo = context.watch<ShopRepository>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Product>>(
        stream: productRepo.watchTrendingProducts(limit: 20),
        builder: (context, productSnapshot) {
          return StreamBuilder<Map<int, List<Story>>>(
            stream: storyRepo.watchArrivagesGroupedByShop(),
            builder: (context, arrivageSnapshot) {
              return StreamBuilder<List<Shop>>(
                stream: shopRepo.watchFeaturedShops(),
                builder: (context, shopSnapshot) {
                  final products = productSnapshot.data ?? [];
                  final arrivageGroups = arrivageSnapshot.data ?? {};
                  final shops = shopSnapshot.data ?? [];
                  final showArrivages = arrivageGroups.isNotEmpty;
                  final showShops = shops.isNotEmpty;

                  if (productSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      products.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (products.isEmpty && !showArrivages && !showShops) {
                    return const Center(
                      child: Text(
                        'Aucune découverte pour le moment',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Arrivages section at the top
                      if (showArrivages) _buildArrivagesSection(arrivageGroups),
                      // Boutiques section
                      if (showShops) _buildBoutiquesSection(shops),
                      // Product feed fills remaining space
                      Expanded(
                        child: products.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucune découverte pour le moment',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : PageView.builder(
                                scrollDirection: Axis.vertical,
                                controller: _pageController,
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  return _DiscoverItem(
                                    product: products[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the Arrivages horizontal scroll section with header.
  Widget _buildArrivagesSection(Map<int, List<Story>> grouped) {
    final shopIds = grouped.keys.toList();

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
          // Horizontal scroll of arrivage cards
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shopIds.length,
              itemBuilder: (context, index) {
                final shopId = shopIds[index];
                final stories = grouped[shopId]!;
                final firstStory = stories.first;
                return _ArrivageCard(
                  shopId: shopId,
                  stories: stories,
                  firstStory: firstStory,
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
class _ArrivageCard extends StatelessWidget {
  final int shopId;
  final List<Story> stories;
  final Story firstStory;

  const _ArrivageCard({
    required this.shopId,
    required this.stories,
    required this.firstStory,
  });

  @override
  Widget build(BuildContext context) {
    final decryptedUrl = firstStory.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(firstStory.mediaUrl)
        : '';

    return GestureDetector(
      onTap: () {
        final storyRepo = context.read<StoryRepository>();
        storyRepo.logStoryView(stories.first.id);
        // Build shop lookup for StoryViewScreen
        final shopRepo = context.read<ShopRepository>();
        _openStoryWithShopLookup(context, shopRepo);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
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
              Image.network(
                decryptedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                    ),
                  );
                },
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
                          shopId,
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
                    if (stories.length > 1)
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
                          '${stories.length}',
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
    final shop = await shopRepo.getShopById(shopId);
    final shopLookup = <int, Shop>{};
    if (shop != null) {
      shopLookup[shopId] = shop;
    }
    if (context.mounted) {
      Navigator.push(
        context,
        SlideUpRoute(
          page: StoryViewScreen(
            stories: stories,
            initialIndex: 0,
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
