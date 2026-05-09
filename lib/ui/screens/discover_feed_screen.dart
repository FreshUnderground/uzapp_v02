import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/story_repository.dart'
    show StoryRepository, ArrivageMediaItem;
import '../components/shop_video_player.dart';
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
  int _lastProductCount = -1;
  int _lastArrivageMediaCount = -1;
  final Random _rng = Random();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Synchronous — JOIN stream already expands media items, just shuffle.
  void _buildFeed(List<Product> products, List<ArrivageMediaItem> mediaItems) {
    final mixed = <dynamic>[...products, ...mediaItems];
    for (var i = mixed.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = mixed[i];
      mixed[i] = mixed[j];
      mixed[j] = tmp;
    }
    setState(() {
      _feed = mixed;
      _lastProductCount = products.length;
      _lastArrivageMediaCount = mediaItems.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final storyRepo = context.watch<StoryRepository>();

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: StreamBuilder<List<Product>>(
          stream: productRepo.watchAllProducts(),
          builder: (context, productSnap) {
            return StreamBuilder<List<ArrivageMediaItem>>(
              stream: storyRepo.watchArrivageMediaFeed(),
              builder: (context, mediaSnap) {
                final products = productSnap.data ?? [];
                final mediaItems = mediaSnap.data ?? [];

                final loading =
                    productSnap.connectionState == ConnectionState.waiting &&
                    mediaSnap.connectionState == ConnectionState.waiting &&
                    _feed.isEmpty;

                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (_lastProductCount != products.length ||
                    _lastArrivageMediaCount != mediaItems.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _buildFeed(products, mediaItems);
                  });
                }

                if (_feed.isEmpty && products.isEmpty && mediaItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun contenu disponible',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final items = _feed.isNotEmpty
                    ? _feed
                    : <dynamic>[...products, ...mediaItems];

                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  pageSnapping: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is Product) {
                      return _ProductPage(product: item);
                    } else if (item is ArrivageMediaItem) {
                      return _ArrivagePage(entry: item);
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            );
          },
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
  const _ProductPage({required this.product});

  @override
  State<_ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<_ProductPage> {
  Shop? _shop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final shop = await context.read<ShopRepository>().getShopById(
      widget.product.shopId,
    );
    if (mounted) setState(() => _shop = shop);
  }

  String get _firstImage {
    final imgs = ImageUtils.getDecryptedList(widget.product.imageUrls);
    return imgs.isNotEmpty ? imgs.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    String? videoUrl;
    if (_shop?.videoUrl != null && _shop!.videoUrl!.isNotEmpty) {
      videoUrl = CryptoUtils.decrypt(_shop!.videoUrl!);
    }

    final bg = videoUrl != null
        ? ShopVideoPlayer(videoUrl: videoUrl, isBackground: true)
        : ImageUtils.buildCachedImage(_firstImage, fit: BoxFit.cover);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred backdrop (wide screens only)
        if (isWide) ...[
          bg,
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

                // Bottom-left info
                Positioned(
                  left: 16,
                  right: 80,
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

                // Right-side action buttons
                Positioned(
                  right: 12,
                  bottom: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LikeButton(product: widget.product),
                      const SizedBox(height: 14),
                      _ActionBtn(
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
                      const SizedBox(height: 14),
                      _ActionBtn(
                        icon: Icons.share,
                        label: 'Partager',
                        onTap: () => context
                            .read<ContactService>()
                            .shareProduct(widget.product, null),
                      ),
                      const SizedBox(height: 14),
                      _ActionBtn(
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
}

// ──────────────────────────────────────────────────────────────────────────────
// Full-screen arrivage (story) page
// ──────────────────────────────────────────────────────────────────────────────

class _ArrivagePage extends StatefulWidget {
  final ArrivageMediaItem entry;
  const _ArrivagePage({required this.entry});

  @override
  State<_ArrivagePage> createState() => _ArrivagePageState();
}

class _ArrivagePageState extends State<_ArrivagePage> {
  Shop? _shop;

  ArrivageMediaItem get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final shop = await context.read<ShopRepository>().getShopById(
      widget.entry.shopId,
    );
    if (mounted) setState(() => _shop = shop);
  }

  @override
  Widget build(BuildContext context) {
    final decryptedUrl = entry.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(entry.mediaUrl)
        : '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    Widget media;
    if (entry.mediaType == 'video' && decryptedUrl.isNotEmpty) {
      media = ShopVideoPlayer(videoUrl: decryptedUrl, isBackground: true);
    } else {
      media = ImageUtils.buildCachedImage(decryptedUrl, fit: BoxFit.cover);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred backdrop (wide screens)
        if (isWide) ...[
          media,
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
                media,

                // Gradient
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

                // Bottom-left: shop info
                Positioned(
                  left: 16,
                  right: 80,
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

                // Right: go-to-shop button
                Positioned(
                  right: 12,
                  bottom: 40,
                  child: _ActionBtn(
                    icon: Icons.storefront,
                    label: 'Boutique',
                    onTap: () {
                      if (_shop != null) {
                        Navigator.push(
                          context,
                          SlideUpRoute(page: ShopProfileScreen(shop: _shop!)),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Like button (reactive)
// ──────────────────────────────────────────────────────────────────────────────

class _LikeButton extends StatelessWidget {
  final Product product;
  const _LikeButton({required this.product});

  @override
  Widget build(BuildContext context) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    final repo = context.read<ProductRepository>();

    return StreamBuilder<bool>(
      stream: userPhone.isNotEmpty
          ? repo.watchIsProductLiked(product.id, userPhone)
          : Stream.value(false),
      builder: (context, likeSnap) {
        final isLiked = likeSnap.data ?? false;
        return StreamBuilder<int>(
          stream: repo.watchProductLikeCount(product.id),
          builder: (context, countSnap) {
            final count = countSnap.data ?? 0;
            return _ActionBtn(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: '$count',
              color: isLiked ? Colors.red : Colors.white,
              onTap: () {
                if (userPhone.isNotEmpty) {
                  repo.toggleLike(product.id, userPhone);
                }
              },
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Generic circular action button
// ──────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.45),
          radius: 24,
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                icon,
                key: ValueKey(icon.codePoint),
                color: color,
                size: 22,
              ),
            ),
            onPressed: onTap,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
