import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/services/contact_service.dart';
import 'product_detail_screen.dart';
import 'dart:ui';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../components/shop_video_player.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Product>>(
        stream: productRepo.watchTrendingProducts(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Aucune découverte pour le moment',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _DiscoverItem(product: products[index]);
                },
              ),
            ],
          );
        },
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
