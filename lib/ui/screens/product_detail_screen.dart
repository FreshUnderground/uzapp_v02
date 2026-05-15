import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/res/uza_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/repositories/cart_repository.dart';
import 'shop_profile_screen.dart';
import 'cart_screen.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../components/product_card.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../components/product_metadata_display.dart';
import '../../core/utils/category_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  late final List<String> _images;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _images = ImageUtils.getDecryptedList(widget.product.imageUrls);
    _pageController = PageController();
    // Log view using post-frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductRepository>().logProductView(widget.product.id);
        context.read<SyncService>().reportInteraction(
          widget.product.id,
          'view',
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.read<ShopRepository>();

    return Title(
      title: '${widget.product.name.toUpperCase()} | UZAAPP',
      color: Colors.white,
      child: Scaffold(
        appBar: _buildAppBar(shopRepo),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1100) {
              return _buildDesktopBody(shopRepo);
            }
            return _buildMobileBody(shopRepo);
          },
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width < 1100
            ? _buildBottomActions(context, shopRepo)
            : null,
      ),
    );
  }

  Widget _buildDesktopBody(ShopRepository shopRepo) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Images
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImageSection(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildThumbnailSelector(),
                  ],
                ),
              ),
            ),
            // Right: Details
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(),
                    const SizedBox(height: 16),
                    _buildPriceSection(),
                    const SizedBox(height: 32),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildCategoryMetadata(),
                    const SizedBox(height: 24),
                    _buildProductStats(),
                    const SizedBox(height: 32),
                    _buildSellerSection(shopRepo),
                    const SizedBox(height: 48),
                    _buildBottomActions(context, shopRepo, isDesktop: true),
                    const SizedBox(height: 40),
                    const Text(
                      'Même Vendeur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSuggestionsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ShopRepository shopRepo) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return AppBar(
      actions: [
        FutureBuilder<Shop?>(
          future: shopRepo.getShopById(widget.product.shopId),
          builder: (context, snapshot) {
            final isLoaded = snapshot.connectionState == ConnectionState.done;
            return IconButton(
              icon: Icon(
                isLoaded ? Icons.share_outlined : Icons.sync,
                size: 20,
              ),
              onPressed: isLoaded
                  ? () {
                      context.read<ContactService>().shareProduct(
                        widget.product,
                        snapshot.data,
                      );
                      context.read<SyncService>().reportInteraction(
                        widget.product.id,
                        'share',
                      );
                    }
                  : null,
            );
          },
        ),
        // Like button
        StreamBuilder<bool>(
          stream: userPhone.isNotEmpty
              ? context.read<ProductRepository>().watchIsProductLiked(
                  widget.product.id,
                  userPhone,
                )
              : Stream.value(false),
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
              ),
              onPressed: () {
                if (userPhone.isNotEmpty) {
                  context.read<ProductRepository>().toggleLike(
                    widget.product.id,
                    userPhone,
                  );
                }
              },
            );
          },
        ),
        // Wishlist button
        StreamBuilder<bool>(
          stream: context.read<ProductRepository>().watchIsInWishlist(
            widget.product.id,
          ),
          builder: (context, snapshot) {
            final isInWishlist = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                color: isInWishlist ? UzaColors.primary : null,
              ),
              onPressed: () => context.read<ProductRepository>().toggleWishlist(
                widget.product.id,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody(ShopRepository shopRepo) {
    return FutureBuilder<Shop?>(
      future: shopRepo.getShopById(widget.product.shopId),
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(background: _buildImageSection()),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHeader(),
                      const SizedBox(height: 16),
                      _buildPriceSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),
                      _buildCategoryMetadata(),
                      const SizedBox(height: 16),
                      _buildProductStats(),
                      const SizedBox(height: 24),
                      _buildSellerSection(shopRepo),
                      const SizedBox(height: 32),
                      _buildRatingSection(),
                      const SizedBox(height: 32),
                      _buildShareSection(shopRepo),
                      const SizedBox(height: 48),
                      const Text(
                        'Même Vendeur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionsSection(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: 'product_detail_${widget.product.id}',
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return ImageUtils.buildCachedImage(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        if (_images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _images
                  .asMap()
                  .entries
                  .map((entry) => _buildIndicator(entry.key))
                  .toList(),
            ),
          ),
        // Floating "Ajouter au panier" button
        Positioned(
          bottom: _images.length > 1 ? 56 : 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<CartRepository>().addToCart(widget.product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Produit ajouté à votre sélection'),
                  action: SnackBarAction(
                    label: 'VOIR',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: UzaColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Tooltip(
                message: 'Ajouter à ma sélection',
                child: Icon(
                  Icons.playlist_add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha: _currentImageIndex == index ? 0.9 : 0.4,
        ),
      ),
    );
  }

  Widget _buildThumbnailSelector() {
    if (_images.length <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _images.asMap().entries.map((entry) {
        final isSelected = _currentImageIndex == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _currentImageIndex = entry.key),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? UzaColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: entry.value,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.product.name.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (widget.product.isArrival)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: UzaColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NOUVEAU',
              style: TextStyle(
                color: UzaColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryMetadata() {
    if (widget.product.metadata == null || widget.product.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Category?>(
      future: _getProductCategory(),
      builder: (context, snapshot) {
        // Still waiting — keep blank to avoid layout jumps
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // Category may be null (unknown/generic) — still show metadata
        try {
          final metadata =
              jsonDecode(widget.product.metadata!) as Map<String, dynamic>;
          // getFormType returns 'generic' when category is null
          final formType = CategoryHelper.getFormType(snapshot.data);

          return ProductMetadataDisplay(
            metadata: metadata,
            categoryType: formType,
          );
        } catch (e) {
          debugPrint('Error parsing metadata: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<Category?> _getProductCategory() async {
    try {
      final db = context.read<UzaDatabase>();
      final categories = await db.select(db.categories).get();
      return categories.firstWhere(
        (c) => c.id == widget.product.categoryId,
        orElse: () => throw Exception('Category not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildProductStats() {
    final hasViews = widget.product.viewsCount > 0;
    final hasShares = widget.product.sharesCount > 0;
    final hasRatings = widget.product.ratingsCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like count
          StreamBuilder<int>(
            stream: context.read<ProductRepository>().watchProductLikeCount(
              widget.product.id,
            ),
            builder: (context, snapshot) {
              final likeCount = snapshot.data ?? 0;
              if (likeCount == 0 && !hasViews && !hasShares && !hasRatings) {
                return const SizedBox.shrink();
              }
              return _buildStatItem(
                Icons.favorite_outlined,
                '$likeCount',
                'LIKES',
              );
            },
          ),
          if (hasViews)
            _buildStatItem(
              Icons.visibility_outlined,
              '${widget.product.viewsCount}',
              'VUES',
            ),
          if (hasShares)
            _buildStatItem(
              Icons.share_outlined,
              '${widget.product.sharesCount}',
              'PARTAGES',
            ),
          if (hasRatings)
            _buildStatItem(
              Icons.star_outline,
              widget.product.ratingAvg.toStringAsFixed(1),
              'RATING',
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: UzaColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final showStock = widget.product.showStock;
    final isBoosted = widget.product.boostStatus == 2;
    final promoMsg = widget.product.promotionMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prix sur demande',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: UzaColors.primary,
              ),
            ),
            if (showStock && widget.product.stockCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.product.stockCount! > 0
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.product.stockCount} en stock',
                  style: TextStyle(
                    color: widget.product.stockCount! > 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (isBoosted && promoMsg != null && promoMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UzaColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: UzaColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: UzaColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    promoMsg,
                    style: const TextStyle(
                      color: UzaColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionCard() {
    final desc = widget.product.description;
    if (desc == null || desc.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with accent bar
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [UzaColors.primary, UzaColors.secondary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: UzaColors.primary.withValues(alpha: 0.4),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0xFF3D3D3D),
                        height: 1.75,
                        fontSize: 15,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.product.condition.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.product.condition == 'new'
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.product.condition == 'new'
                              ? Colors.green[300]!
                              : Colors.orange[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.product.condition == 'new'
                                ? Icons.new_releases_outlined
                                : Icons.history_toggle_off,
                            size: 13,
                            color: widget.product.condition == 'new'
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.condition == 'new'
                                ? 'Neuf'
                                : 'Occasion',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.product.condition == 'new'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.product.description ?? 'Pas de description disponible.',
      style: TextStyle(color: Colors.grey[800], height: 1.5, fontSize: 16),
    );
  }

  Widget _buildSellerSection(ShopRepository shopRepo) {
    return FutureBuilder<Shop?>(
      future: shopRepo.getShopById(widget.product.shopId),
      builder: (context, snapshot) {
        final shop = snapshot.data;
        if (shop == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendu par',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopProfileScreen(shop: shop),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: UzaColors.primary,
                      backgroundImage: () {
                        if (shop.logoUrl == null || shop.logoUrl!.isEmpty) {
                          return null;
                        }
                        final decrypted = CryptoUtils.decrypt(shop.logoUrl!);
                        if (decrypted.isEmpty ||
                            (!decrypted.startsWith('http://') &&
                                !decrypted.startsWith('https://'))) {
                          return null;
                        }
                        return CachedNetworkImageProvider(decrypted)
                            as ImageProvider;
                      }(),
                      child: shop.logoUrl == null
                          ? Text(
                              shop.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            shop.type.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            // Location / directions — now promoted to the bottom action bar
          ],
        );
      },
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Avis des clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _showAddReviewSheet(context),
              child: const Text('Donner mon avis'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ProductReview>>(
          stream: context.read<ProductRepository>().watchProductReviews(
            widget.product.id,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Aucun avis pour le moment. Soyez le premier !',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              );
            }

            final reviews = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 3 ? 3 : reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review.userName ?? 'Utilisateur anonyme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: i < review.rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.comment,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre avis nous intéresse',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () =>
                        setModalState(() => selectedRating = index + 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Que pensez-vous de ce produit ?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (commentController.text.isNotEmpty) {
                      await context.read<ProductRepository>().addReview(
                        widget.product.id,
                        selectedRating,
                        commentController.text,
                      );
                      if (context.mounted) {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        navigator.pop(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Merci pour votre avis !'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UzaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Publier mon avis'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareSection(ShopRepository shopRepo) {
    return FutureBuilder<Shop?>(
      future: shopRepo.getShopById(widget.product.shopId),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UzaColors.primary.withValues(alpha: 0.06),
                UzaColors.secondary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: UzaColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: UzaColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: UzaColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partager ce produit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Faites connaître ce produit à vos proches',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      icon: FontAwesomeIcons.whatsapp,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        context.read<SyncService>().reportInteraction(
                          widget.product.id,
                          'share',
                        );
                        context.read<ContactService>().shareProduct(
                          widget.product,
                          snapshot.data,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      icon: FontAwesomeIcons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () => context.read<ContactService>().launchSocial(
                        urlString:
                            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://uzaapp.com/#/product/${widget.product.id}')}',
                        entityType: 'product',
                        entityId: widget.product.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      icon: Icons.link_rounded,
                      label: 'Copier lien',
                      color: Colors.grey[700]!,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://uzaapp.com/#/product/${widget.product.id}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('Lien copié !'),
                              ],
                            ),
                            backgroundColor: Colors.grey[800],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      icon: Icons.more_horiz_rounded,
                      label: 'Plus',
                      color: UzaColors.primary,
                      onTap: () => context.read<ContactService>().shareProduct(
                        widget.product,
                        snapshot.data,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            (icon == FontAwesomeIcons.whatsapp ||
                    icon == FontAwesomeIcons.facebook)
                ? FaIcon(icon, color: color, size: 22)
                : Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Les clients qui ont vu ceci ont aussi aimé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: StreamBuilder<List<Product>>(
            stream: context.read<ProductRepository>().suggestedProducts(
              widget.product.id,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'D\'autres pépites arrivent bientôt !',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final suggestions = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    child: HeroMode(
                      enabled: false,
                      child: ProductCard(
                        product: suggestion,
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: suggestion),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    ShopRepository shopRepo, {
    bool isDesktop = false,
  }) {
    return FutureBuilder<Shop?>(
      future: shopRepo.getShopById(widget.product.shopId),
      builder: (context, snapshot) {
        final shop = snapshot.data;
        return Container(
          padding: isDesktop
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isDesktop
              ? null
              : BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: shop != null
                      ? () {
                          final hasWhatsApp =
                              shop.whatsapp?.trim().isNotEmpty == true;
                          final hasPhone =
                              shop.phone?.trim().isNotEmpty == true;
                          if (!hasWhatsApp && !hasPhone) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ce vendeur n\'a pas de numéro WhatsApp',
                                ),
                              ),
                            );
                            return;
                          }
                          HapticFeedback.lightImpact();
                          _showContactOptions(context, shop);
                        }
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  label: const Text(
                    'Contacter le vendeur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isDesktop ? 0 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: shop != null
                      ? () {
                          HapticFeedback.lightImpact();
                          if (shop.latitude != null && shop.longitude != null) {
                            LocationService.getDirections(
                              latitude: shop.latitude!,
                              longitude: shop.longitude!,
                              destinationName: shop.name,
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopProfileScreen(shop: shop),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: const Text(
                    'Adresse',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    iconSize: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isDesktop ? 0 : 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onContactClicked(String type) {
    context.read<ShopRepository>().recordContact(
      widget.product.shopId,
      'Client', // Placeholder or get from user profile if available
      type,
      productId: widget.product.id,
    );
  }

  void _showContactOptions(BuildContext context, Shop shop) {
    final hasWhatsApp = shop.whatsapp?.trim().isNotEmpty == true;
    final hasPhone = shop.phone?.trim().isNotEmpty == true;
    final effectivePhone = hasWhatsApp
        ? shop.whatsapp!
        : (hasPhone ? shop.phone! : null);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contacter le vendeur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (effectivePhone != null)
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  title: const Text('WhatsApp'),
                  onTap: () {
                    _onContactClicked('whatsapp');
                    Navigator.pop(context);
                    context.read<ContactService>().launchWhatsApp(
                      phone: effectivePhone,
                      entityType: 'product',
                      entityId: widget.product.id,
                      name: widget.product.name.toUpperCase(),
                      imageUrl:
                          ImageUtils.getDecryptedList(
                            widget.product.imageUrls,
                          ).firstOrNull ??
                          '',
                      productUrl:
                          "https://uzaapp.com/product/${widget.product.id}",
                      price: widget.product.price,
                      condition: widget.product.condition,
                    );
                  },
                ),
              if (hasPhone)
                ListTile(
                  leading: const Icon(Icons.phone, color: UzaColors.primary),
                  title: const Text('Appel Direct'),
                  onTap: () {
                    _onContactClicked('call');
                    Navigator.pop(context);
                    context.read<ContactService>().makeCall(
                      phone: shop.phone!,
                      entityType: 'product',
                      entityId: widget.product.id,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.orange),
                title: const Text('Envoyer un SMS'),
                onTap: () {
                  _onContactClicked('sms');
                  Navigator.pop(context);
                  if (hasPhone) {
                    context.read<ContactService>().sendSMS(
                      phone: shop.phone!,
                      entityType: 'product',
                      entityId: widget.product.id,
                      message:
                          "Est-ce que le produit ${widget.product.name.toUpperCase()} est toujours disponible ?",
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ce vendeur n\'a pas de numéro de téléphone',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
