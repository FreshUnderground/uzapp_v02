import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/story_repository.dart'
    show StoryRepository, ArrivageMediaItem;
import '../../data/services/sync_service.dart';
import '../../data/repositories/cart_repository.dart';
import '../components/uza_media_top_bar.dart';
import '../components/contact_seller_sheet.dart';
import 'cart_screen.dart';
import '../components/marketing_share_sheet.dart';
import '../components/shop_video_player.dart';
import '../components/skeletons.dart';
import '../components/custom_refresh_indicator.dart';
import '../components/empty_state.dart';
import '../../core/l10n/tr.dart';
import '../utils/page_transitions.dart';
import 'product_detail_screen.dart';
import 'shop_profile_screen.dart';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  final PageController _pageController = PageController();
  List<dynamic> _feed = [];
  int _lastFeedSignature = -1;
  final Random _rng = Random();
  bool _requestedGuestSync = false;
  bool _showSwipeHint = false;

  static const _hintKey = 'discover_swipe_hint_seen';

  @override
  void initState() {
    super.initState();
    _loadSwipeHint();
  }

  Future<void> _loadSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_hintKey) ?? false;
    if (!seen && mounted) setState(() => _showSwipeHint = true);
  }

  Future<void> _dismissSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintKey, true);
    if (mounted) setState(() => _showSwipeHint = false);
  }

  void _maybeBootstrapSync(
    List<Product> products,
    List<ArrivageMediaItem> mediaItems,
    SyncService syncService,
  ) {
    if (_requestedGuestSync) return;
    if (products.isNotEmpty || mediaItems.isNotEmpty) return;
    if (!syncService.isOnline || syncService.isSyncing) return;
    _requestedGuestSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncService.syncNow();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _computeFeedSignature(
    List<Product> products,
    List<ArrivageMediaItem> mediaItems,
  ) {
    var signature = products.length ^ (mediaItems.length * 31);
    for (final product in products.take(12)) {
      signature ^= product.id;
      signature ^= product.updatedAt.millisecondsSinceEpoch;
    }
    for (final media in mediaItems.take(12)) {
      signature ^= media.storyId;
      signature ^= media.mediaUrl.hashCode;
    }
    return signature;
  }

  /// Synchronous — JOIN stream already expands media items, just shuffle.
  /// Prioritizes videos while maintaining randomness.
  void _buildFeed(List<Product> products, List<ArrivageMediaItem> mediaItems) {
    final productRepo = context.read<ProductRepository>();
    final availableProducts = productRepo
        .deduplicateForDisplay(
          products
              .where((p) => !p.isSold && _productHasDisplayableImage(p))
              .toList(),
        );

    // Separate videos from other media
    final videos = mediaItems.where((m) => m.mediaType == 'video').toList();
    final otherMedia = mediaItems.where((m) => m.mediaType != 'video').toList();

    // Shuffle each category independently
    for (var i = videos.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = videos[i];
      videos[i] = videos[j];
      videos[j] = tmp;
    }

    for (var i = otherMedia.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = otherMedia[i];
      otherMedia[i] = otherMedia[j];
      otherMedia[j] = tmp;
    }

    void shuffleList<T>(List<T> list) {
      for (var i = list.length - 1; i > 0; i--) {
        final j = _rng.nextInt(i + 1);
        final tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
      }
    }

    shuffleList(availableProducts);
    final shuffledProducts = availableProducts;

    // Build feed: interleave with video priority
    // Strategy: videos get ~40% of feed, other media ~30%, products ~30%
    final mixed = <dynamic>[];
    final totalItems =
        videos.length + otherMedia.length + shuffledProducts.length;

    if (totalItems == 0) {
      setState(() {
        _feed = [];
        _lastFeedSignature = _computeFeedSignature(products, mediaItems);
      });
      return;
    }

    // Calculate target ratios
    final videoTarget = (totalItems * 0.4).round();
    final mediaTarget = (totalItems * 0.3).round();
    final productTarget = totalItems - videoTarget - mediaTarget;

    int videoIdx = 0;
    int mediaIdx = 0;
    int productIdx = 0;

    // Distribute items maintaining ratios but with some randomness
    while (videoIdx < videos.length ||
        mediaIdx < otherMedia.length ||
        productIdx < shuffledProducts.length) {
      // Add video if we haven't reached target and have videos left
      if (videoIdx < videos.length &&
          (videoIdx < videoTarget || _rng.nextDouble() < 0.5)) {
        mixed.add(videos[videoIdx++]);
      }

      // Add product if we haven't reached target and have products left
      if (productIdx < shuffledProducts.length &&
          (productIdx < productTarget || _rng.nextDouble() < 0.4)) {
        mixed.add(shuffledProducts[productIdx++]);
      }

      // Add other media if we haven't reached target and have media left
      if (mediaIdx < otherMedia.length &&
          (mediaIdx < mediaTarget || _rng.nextDouble() < 0.3)) {
        mixed.add(otherMedia[mediaIdx++]);
      }
    }

    // Add any remaining items
    while (videoIdx < videos.length) mixed.add(videos[videoIdx++]);
    while (mediaIdx < otherMedia.length) mixed.add(otherMedia[mediaIdx++]);
    while (productIdx < shuffledProducts.length)
      mixed.add(shuffledProducts[productIdx++]);

    setState(() {
      _feed = mixed;
      _lastFeedSignature = _computeFeedSignature(products, mediaItems);
    });
  }

  bool _productHasDisplayableImage(Product product) {
    return ImageUtils.hasDisplayableImage(product.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final storyRepo = context.watch<StoryRepository>();
    final syncService = context.watch<SyncService>();

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: UzaRefreshIndicator(
          onRefresh: () async {
            await syncService.syncNow();
            if (mounted) {
              setState(() {
                _feed = [];
                _lastFeedSignature = -1;
              });
            }
          },
          child: StreamBuilder<List<Product>>(
          stream: productRepo.watchAllProducts(),
          builder: (context, productSnap) {
            return StreamBuilder<List<ArrivageMediaItem>>(
              stream: storyRepo.watchArrivageMediaFeed(),
              builder: (context, mediaSnap) {
                if (productSnap.hasError || mediaSnap.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: EmptyState(
                          icon: Icons.error_outline,
                          title: tr(context, 'load_error'),
                          actionLabel: tr(context, 'retry'),
                          onAction: () => syncService.syncNow(),
                        ),
                      ),
                    ],
                  );
                }

                final products = productSnap.data ?? [];
                final mediaItems = mediaSnap.data ?? [];
                _maybeBootstrapSync(products, mediaItems, syncService);

                // Show loading when: streams still loading, OR sync is running with no data
                final streamsLoading =
                    productSnap.connectionState == ConnectionState.waiting &&
                    mediaSnap.connectionState == ConnectionState.waiting;
                final syncRunningNoData =
                    (syncService.isSyncing || syncService.isFirstSync) &&
                    _feed.isEmpty &&
                    products.isEmpty &&
                    mediaItems.isEmpty;

                if (streamsLoading || syncRunningNoData) {
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: ProductCardSkeleton(),
                    ),
                  );
                }

                final signature = _computeFeedSignature(products, mediaItems);
                if (_lastFeedSignature != signature) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _buildFeed(products, mediaItems);
                  });
                }

                if (_feed.isEmpty && products.isEmpty && mediaItems.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Text(
                            tr(context, 'no_popular'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final items = _feed.isNotEmpty
                    ? _feed
                    : <dynamic>[...products, ...mediaItems];

                return Stack(
                  children: [
                    PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      onPageChanged: (_) {
                        if (_showSwipeHint) _dismissSwipeHint();
                      },
                      pageSnapping: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is Product) {
                          return _ProductPage(
                            product: item,
                            pageIndex: index,
                            pageCount: items.length,
                          );
                        } else if (item is ArrivageMediaItem) {
                          return _ArrivagePage(
                            entry: item,
                            singleSlide: true,
                            pageIndex: index,
                            pageCount: items.length,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (_showSwipeHint)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 120,
                        child: Center(
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: _dismissSwipeHint,
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.swipe_vertical,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      tr(context, 'discover_swipe_hint'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Full-screen product page
// ──────────────────────────────────────────────────────────────────────────────

class _ProductPage extends StatefulWidget {
  final Product product;
  final int pageIndex;
  final int pageCount;
  const _ProductPage({
    required this.product,
    this.pageIndex = 0,
    this.pageCount = 1,
  });

  @override
  State<_ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<_ProductPage> {
  Shop? _shop;
  List<String> _images = [];
  int _currentImageIndex = 0;
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _loadShop();
    _loadImages();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadShop() async {
    final productRepo = context.read<ProductRepository>();
    final shopRepo = context.read<ShopRepository>();
    var shop = await productRepo.resolveShopForProduct(widget.product);
    shop ??= await shopRepo.getShopById(widget.product.shopId);
    if (mounted) setState(() => _shop = shop);
  }

  Future<void> _handleWhatsAppTap() async {
    var shop = _shop;
    if (shop == null) {
      await _loadShop();
      shop = _shop;
    }
    if (!mounted) return;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'shop_not_found'))),
      );
      return;
    }
    ContactSellerSheet.show(
      context,
      shop: shop,
      product: widget.product,
    );
  }

  void _loadImages() {
    final imgs = ImageUtils.getDecryptedList(widget.product.imageUrls);
    if (mounted) {
      setState(() {
        _images = imgs;
      });
    }
  }

  List<Widget> _buildTopActions() {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    final repo = context.read<ProductRepository>();

    return [
      StreamBuilder<bool>(
        stream: userPhone.isNotEmpty
            ? repo.watchIsProductLiked(widget.product.id, userPhone)
            : Stream.value(false),
        builder: (context, likeSnap) {
          final isLiked = likeSnap.data ?? false;
          return IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white,
            ),
            onPressed: () {
              if (userPhone.isNotEmpty) {
                repo.toggleLike(widget.product.id, userPhone);
              }
            },
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined, color: Colors.white),
        onPressed: () => MarketingShareSheet.showProduct(
          context,
          product: widget.product,
          shop: _shop,
          onShared: () => context
              .read<SyncService>()
              .reportProductStatByLocalId(widget.product.id, 'share'),
        ),
      ),
      StreamBuilder<int>(
        stream: context.watch<CartRepository>().watchCartCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            label: Text('$count'),
            isLabelVisible: count > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const CartScreen()),
              ),
            ),
          );
        },
      ),
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 22),
        onPressed: _handleWhatsAppTap,
      ),
      IconButton(
        icon: const Icon(Icons.info_outline, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: widget.product),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    // Use loaded images or empty list
    final images = _images.isNotEmpty ? _images : [];
    final firstImage = images.isNotEmpty ? images.first : '';

    String? videoUrl;
    if (_shop?.videoUrl != null && _shop!.videoUrl!.isNotEmpty) {
      videoUrl = CryptoUtils.decrypt(_shop!.videoUrl!);
    }

    Widget bg;
    if (videoUrl != null) {
      bg = ShopVideoPlayer(videoUrl: videoUrl, isBackground: true);
    } else if (images.isNotEmpty) {
      bg = PageView.builder(
        controller: _imagePageController,
        onPageChanged: (index) {
          setState(() => _currentImageIndex = index);
        },
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ImageUtils.buildFullscreenContainedImage(images[index]);
        },
      );
    } else {
      bg = Container(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred backdrop (wide screens only)
        if (isWide) ...[
          videoUrl != null
              ? ShopVideoPlayer(videoUrl: videoUrl, isBackground: true)
              : (images.isNotEmpty
                    ? ImageUtils.buildCachedImage(firstImage, fit: BoxFit.cover)
                    : Container(color: Colors.black)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ],

        // Centred frame
        Center(
          child: Container(
            constraints: isWide ? const BoxConstraints(maxWidth: 450) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                bg,

                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.2, 0.65, 1.0],
                    ),
                  ),
                ),

                // Image indicators (if multiple images)
                if (images.length > 1)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images
                          .asMap()
                          .entries
                          .map((e) => _buildProductImageIndicator(e.key))
                          .toList(),
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: UzaMediaTopBar(
                    fallbackLocation: '/discover',
                    actions: _buildTopActions(),
                  ),
                ),

                // Bottom-left info
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
                      if (widget.product.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.product.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _shop?.name ?? '...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  Widget _buildProductImageIndicator(int index) {
    final isActive = index == _currentImageIndex;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Full-screen arrivage (story) page
// ──────────────────────────────────────────────────────────────────────────────

class _ArrivagePage extends StatefulWidget {
  final ArrivageMediaItem entry;
  final bool singleSlide;
  final int pageIndex;
  final int pageCount;

  const _ArrivagePage({
    required this.entry,
    this.singleSlide = false,
    this.pageIndex = 0,
    this.pageCount = 1,
  });

  @override
  State<_ArrivagePage> createState() => _ArrivagePageState();
}

class _ArrivagePageState extends State<_ArrivagePage> {
  Shop? _shop;
  List<ArrivageMediaItem> _mediaItems = [];
  int _currentMediaIndex = 0;
  late PageController _mediaPageController;

  ArrivageMediaItem get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
    _loadShop();
    _loadMediaItems();
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  Future<void> _loadShop() async {
    final shopRepo = context.read<ShopRepository>();
    var shop = await shopRepo.resolveShopForStoredId(widget.entry.shopId);
    shop ??= await shopRepo.getShopById(widget.entry.shopId);
    if (mounted) setState(() => _shop = shop);
  }

  Future<Shop?> _ensureShop() async {
    if (_shop != null) return _shop;
    await _loadShop();
    return _shop;
  }

  Future<void> _handleWhatsAppTap() async {
    final shop = await _ensureShop();
    if (!mounted) return;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'shop_not_found'))),
      );
      return;
    }
    final mediaItems = _mediaItems.isNotEmpty ? _mediaItems : [entry];
    final imageUrl = mediaItems[_currentMediaIndex].mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(mediaItems[_currentMediaIndex].mediaUrl)
        : null;
    ContactSellerSheet.show(
      context,
      shop: shop,
      storyId: entry.storyId,
      imageUrlOverride: imageUrl,
    );
  }

  Future<void> _loadMediaItems() async {
    if (widget.singleSlide) {
      if (!mounted) return;
      setState(() => _mediaItems = [entry]);
      return;
    }

    final storyRepo = context.read<StoryRepository>();
    final story = await storyRepo.getStoryById(entry.storyId);

    if (!mounted) return;

    if (story == null) {
      setState(() => _mediaItems = [entry]);
      return;
    }

    final slides = await storyRepo.getStoryMediaSlides(story);
    if (!mounted) return;

    setState(() {
      if (slides.isEmpty) {
        _mediaItems = [entry];
        return;
      }
      _mediaItems = slides
          .map(
            (slide) => ArrivageMediaItem(
              storyId: entry.storyId,
              shopId: entry.shopId,
              mediaUrl: slide.mediaUrl,
              mediaType: slide.mediaType,
            ),
          )
          .toList();
    });
  }

  Future<void> _shareArrivage(BuildContext context) async {
    final shop = await _ensureShop();
    if (!context.mounted) return;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'shop_not_found'))),
      );
      return;
    }

    final storyRepo = context.read<StoryRepository>();
    final story = await storyRepo.getStoryById(entry.storyId);
    if (!context.mounted) return;

    final mediaItems = _mediaItems.isNotEmpty ? _mediaItems : [entry];
    final rawUrl = mediaItems[_currentMediaIndex].mediaUrl;
    final imageUrl = rawUrl.isNotEmpty ? CryptoUtils.decrypt(rawUrl) : null;

    if (story != null) {
      await MarketingShareSheet.showStory(
        context,
        story: story,
        shop: shop,
        imageUrl: imageUrl,
      );
      return;
    }

    await MarketingShareSheet.showShopLink(context, shop: shop);
  }

  List<Widget> _buildTopActions() {
    return [
      IconButton(
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.green,
          size: 22,
        ),
        onPressed: _handleWhatsAppTap,
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined, color: Colors.white),
        onPressed: () => _shareArrivage(context),
      ),
      StreamBuilder<int>(
        stream: context.watch<CartRepository>().watchCartCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            label: Text('$count'),
            isLabelVisible: count > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const CartScreen()),
              ),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.storefront_outlined, color: Colors.white),
        onPressed: () async {
          final shop = await _ensureShop();
          if (!context.mounted || shop == null) return;
          Navigator.push(
            context,
            SlideUpRoute(page: ShopProfileScreen(shop: shop)),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    // Use loaded media items or fall back to single entry
    final mediaItems = _mediaItems.isNotEmpty ? _mediaItems : [entry];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred backdrop (wide screens)
        if (isWide) ...[
          _buildMediaContent(mediaItems[_currentMediaIndex]),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ],

        Center(
          child: Container(
            constraints: isWide ? const BoxConstraints(maxWidth: 450) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Horizontal PageView for media carousel
                PageView.builder(
                  controller: _mediaPageController,
                  onPageChanged: (index) {
                    setState(() => _currentMediaIndex = index);
                  },
                  itemCount: mediaItems.length,
                  itemBuilder: (context, index) {
                    return _buildMediaContent(mediaItems[index]);
                  },
                ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.80),
                      ],
                      stops: const [0.0, 0.2, 0.65, 1.0],
                    ),
                  ),
                ),

                // Media indicators (if multiple items)
                if (mediaItems.length > 1)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: mediaItems
                          .asMap()
                          .entries
                          .map((e) => _buildMediaIndicator(e.key))
                          .toList(),
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: UzaMediaTopBar(
                    fallbackLocation: '/discover',
                    actions: _buildTopActions(),
                  ),
                ),

                // Bottom-left: shop info
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _shop?.name ?? '...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
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

  Widget _buildMediaContent(ArrivageMediaItem item) {
    final mediaUrl = item.mediaUrl.isNotEmpty ? item.mediaUrl : null;
    final resolvedUrl = ImageUtils.resolveImageUrl(mediaUrl) ?? '';

    if (item.mediaType == 'video' && resolvedUrl.isNotEmpty) {
      return ShopVideoPlayer(videoUrl: resolvedUrl, isBackground: true);
    }
    return ImageUtils.buildFullscreenContainedImage(mediaUrl);
  }

  Widget _buildMediaIndicator(int index) {
    final isActive = index == _currentMediaIndex;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
