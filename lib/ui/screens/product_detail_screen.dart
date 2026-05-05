import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../core/services/contact_service.dart';
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
import '../components/product_card.dart';
import 'package:flutter/services.dart';

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
        StreamBuilder<bool>(
          stream: context.read<ProductRepository>().watchIsInWishlist(
            widget.product.id,
          ),
          builder: (context, snapshot) {
            final isInWishlist = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? Colors.red : null,
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
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDescription(),
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
            tag: 'product_image_${widget.product.id}',
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

  Widget _buildProductStats() {
    final hasViews = widget.product.viewsCount > 0;
    final hasShares = widget.product.sharesCount > 0;
    final hasRatings = widget.product.ratingsCount > 0;

    if (!hasViews && !hasShares && !hasRatings) return const SizedBox.shrink();

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
                      backgroundImage: shop.logoUrl != null
                          ? CachedNetworkImageProvider(shop.logoUrl!)
                          : null,
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
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partager ce produit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShareIcon(
                    icon: FontAwesomeIcons.whatsapp,
                    color: const Color(0xFF25D366),
                    onTap: () => context.read<SyncService>().reportInteraction(
                      widget.product.id,
                      'share',
                    ),
                    label: 'WhatsApp',
                    action: () => context.read<ContactService>().shareProduct(
                      widget.product,
                      snapshot.data,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildShareIcon(
                    icon: FontAwesomeIcons.facebook,
                    color: const Color(0xFF1877F2),
                    label: 'Facebook',
                    action: () => context.read<ContactService>().launchSocial(
                      urlString:
                          "https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://uzaapp.com/#/product/${widget.product.id}')}",
                      entityType: 'product',
                      entityId: widget.product.id,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildShareIcon(
                    icon: Icons.link,
                    color: Colors.grey[700]!,
                    label: 'Lien',
                    action: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'https://uzaapp.com/#/product/${widget.product.id}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lien copié dans le presse-papier'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildShareIcon(
                    icon: Icons.more_horiz,
                    color: Colors.grey[600]!,
                    label: 'Plus',
                    action: () => context.read<ContactService>().shareProduct(
                      widget.product,
                      snapshot.data,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareIcon({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback action,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            action();
            if (onTap != null) onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
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
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<CartRepository>().addToCart(widget.product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Produit ajouté à votre sélection'),
                        action: SnackBarAction(
                          label: 'VOIR',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UzaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isDesktop ? 0 : 2,
                  ),
                  child: const Tooltip(
                    message: 'Ajouter à ma sélection',
                    child: Icon(Icons.playlist_add_rounded),
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
