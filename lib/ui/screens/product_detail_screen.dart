import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/sync_service.dart';
import 'package:provider/provider.dart';
import '../../core/res/uza_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/repositories/cart_repository.dart';
import '../../core/router/app_nav_utils.dart';
import '../../core/utils/product_share_messages.dart';
import '../components/uza_back_button.dart';
import '../components/uza_toolbar_row.dart';
import 'shop_profile_screen.dart';
import 'cart_screen.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/product_price_utils.dart';
import '../components/tap_animator.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../components/product_metadata_display.dart';
import '../components/product_extras_section.dart';
import '../components/request_delivery_sheet.dart';
import '../components/contact_seller_sheet.dart';
import '../components/marketing_share_sheet.dart';
import '../../core/utils/category_helper.dart';
import '../../core/l10n/tr.dart';
import '../../core/services/api_service.dart';
import '../components/report_dialog.dart';
import 'edit_product_screen.dart';

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
  Future<Shop?>? _shopFuture;

  ProductRepository get productRepo => context.read<ProductRepository>();

  @override
  void initState() {
    super.initState();
    _images = ImageUtils.getDecryptedList(widget.product.imageUrls);
    _pageController = PageController();
    // Log view using post-frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductRepository>().logProductView(widget.product.id);
        context.read<SyncService>().reportProductStatByLocalId(
          widget.product.id,
          'view',
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shopFuture ??= _resolveShop(context.read<ShopRepository>());
  }

  Future<Shop?> _cachedShopFuture(ShopRepository shopRepo) {
    return _shopFuture ??= _resolveShop(shopRepo);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Shop?> _resolveShop(ShopRepository shopRepo) async {
    final resolved = await productRepo.resolveShopForProduct(widget.product);
    if (resolved != null) return resolved;
    return shopRepo.getShopById(widget.product.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.read<ShopRepository>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        AppNavUtils.popRoute(context);
      },
      child: Title(
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
          bottomNavigationBar: MediaQuery.sizeOf(context).width < 1100
              ? _buildBottomActions(context, shopRepo)
              : null,
        ),
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
                        child: FutureBuilder<Shop?>(
                          future: _cachedShopFuture(shopRepo),
                          builder: (context, snapshot) =>
                              _buildImageSection(shop: snapshot.data),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildThumbnailSelector(),
                  ],
                ),
              ),
            ),
            // Right: Details (sticky actions)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductHeader(),
                          const SizedBox(height: 16),
                          _buildPriceSection(),
                          const SizedBox(height: 12),
                          ProductExtrasSection(product: widget.product),
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
                          const SizedBox(height: 32),
                          _buildSameSellerSection(),
                          const SizedBox(height: 32),
                          _buildSuggestionsSection(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildBottomActions(
                      context,
                      shopRepo,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isShopOwner(Shop shop) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return shop.phone == userPhone || shop.ownerId == userPhone;
  }

  AppBar _buildAppBar(ShopRepository shopRepo) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: UzaToolbarRow(
        leading: const UzaBackButton(),
        trailing: [
        FutureBuilder<Shop?>(
          future: _cachedShopFuture(shopRepo),
          builder: (context, snapshot) {
            final shop = snapshot.data;
            if (shop != null && _isShopOwner(shop)) {
              return IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Modifier le produit',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(
                      shopId: widget.product.shopId,
                      product: widget.product,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          onPressed: () {
            MarketingShareSheet.showProduct(
              context,
              product: widget.product,
              shop: null,
              onShared: () {
                context.read<SyncService>().reportProductStatByLocalId(
                  widget.product.id,
                  'share',
                );
              },
            );
          },
        ),
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
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'report') _showReportDialog();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text(tr(context, 'report_action')),
                ],
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final userPhone = context.read<AuthService>().user?.phoneNumber;
    if (userPhone == null || userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'report_login_required'))),
      );
      return;
    }
    final serverId = int.tryParse(widget.product.remoteId ?? '') ?? widget.product.id;
    ReportDialog.show(
      context,
      productId: serverId.toString(),
      productName: widget.product.name,
      onReport: (reason, details) async {
        final ok = await context.read<ApiService>().reportProduct(
          productId: serverId,
          reason: reason,
          details: details,
          reporterPhone: userPhone,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Signalement envoyé. Merci.' : 'Échec du signalement. Réessayez.',
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileBody(ShopRepository shopRepo) {
    return FutureBuilder<Shop?>(
      future: _cachedShopFuture(shopRepo),
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 360,
                width: double.infinity,
                child: _buildImageSection(shop: snapshot.data),
              ),
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
                      const SizedBox(height: 12),
                      ProductExtrasSection(product: widget.product),
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
                      _buildSameSellerSection(),
                      const SizedBox(height: 32),
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

  Widget _buildImageSection({Shop? shop}) {
    if (_images.isEmpty) {
      return ImageUtils.buildErrorWidget();
    }

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
        // Floating actions: livraison + ajout au panier
        Positioned(
          bottom: _images.length > 1 ? 56 : 16,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImageFloatingButton(
                icon: Icons.local_shipping_outlined,
                label: tr(context, 'request_delivery'),
                tooltip: tr(context, 'request_delivery'),
                color: Colors.white,
                iconColor: UzaColors.primary,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final shopRepo = context.read<ShopRepository>();
                  final resolved =
                      shop ?? await _cachedShopFuture(shopRepo);
                  if (!context.mounted) return;
                  if (resolved == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(context, 'shop_not_found'))),
                    );
                    return;
                  }
                  RequestDeliverySheet.show(
                    context,
                    shop: resolved,
                    product: widget.product,
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildImageFloatingButton(
                icon: Icons.playlist_add_rounded,
                label: 'Panier',
                tooltip: 'Ajouter à ma sélection',
                color: UzaColors.primary,
                iconColor: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<CartRepository>().addToCart(widget.product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr(context, 'product_added_selection')),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageFloatingButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    String? label,
  }) {
    final hasLabel = label != null && label.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: hasLabel ? 14 : 0),
        constraints: BoxConstraints(minWidth: hasLabel ? 0 : 44),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Tooltip(
          message: tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (hasLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _shopLocationQuery(Shop shop) {
    final fullAddress = shop.address?.trim();
    if (fullAddress != null && fullAddress.isNotEmpty) return fullAddress;

    final city = shop.city?.trim();
    final commune = shop.commune?.trim();
    if (city != null &&
        city.isNotEmpty &&
        commune != null &&
        commune.isNotEmpty) {
      return '$city, $commune';
    }
    if (city != null && city.isNotEmpty) return city;
    if (commune != null && commune.isNotEmpty) return commune;
    return null;
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
              child: ImageUtils.buildCachedImage(
                entry.value,
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

    return FutureBuilder<Map<String, dynamic>>(
      future: _getCategoryFormContext(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        try {
          final metadata =
              jsonDecode(widget.product.metadata!) as Map<String, dynamic>;
          final category = snapshot.data?['category'] as Category?;
          final allCategories =
              snapshot.data?['all'] as List<Category>? ?? const [];
          final formType = CategoryHelper.getFormType(
            category,
            allCategories: allCategories,
          );

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

  Future<Map<String, dynamic>> _getCategoryFormContext() async {
    try {
      final db = context.read<UzaDatabase>();
      final categories = await db.select(db.categories).get();
      final categoryId = widget.product.categoryId;
      Category? category;
      if (categoryId != null) {
        category = categories.where((c) => c.id == categoryId).firstOrNull ??
            categories
                .where(
                  (c) => int.tryParse(c.remoteId ?? '') == categoryId,
                )
                .firstOrNull;
      }
      return {'category': category, 'all': categories};
    } catch (e) {
      return {'category': null, 'all': <Category>[]};
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: UzaColors.onSurface(context),
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
            Text(
              ProductPriceUtils.displayLabel(widget.product),
              style: const TextStyle(
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
      future: _cachedShopFuture(shopRepo),
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
                      backgroundImage: ImageUtils.getImageProvider(shop.logoUrl),
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
              child: Text(tr(context, 'give_review')),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: UzaColors.onSurface(context),
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
                          SnackBar(
                            content: Text(tr(context, 'thanks_review')),
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
                  child: Text(tr(context, 'publish_review')),
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
      future: _cachedShopFuture(shopRepo),
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
                        MarketingShareSheet.showProduct(
                          context,
                          product: widget.product,
                          shop: snapshot.data,
                          onShared: () {
                            context.read<SyncService>().reportProductStatByLocalId(
                              widget.product.id,
                              'share',
                            );
                          },
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
                            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(ProductShareMessages.publicUrl(widget.product))}',
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
                            text: ProductShareMessages.publicUrl(widget.product),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(tr(context, 'link_copied')),
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
                      onTap: () => MarketingShareSheet.showProduct(
                        context,
                        product: widget.product,
                        shop: snapshot.data,
                        onShared: () {
                          context.read<SyncService>().reportProductStatByLocalId(
                            widget.product.id,
                            'share',
                          );
                        },
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

  Widget _buildSameSellerSection() {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductRepository>().watchProductsByShop(
        widget.product.shopId,
      ),
      builder: (context, snapshot) {
        final products = (snapshot.data ?? [])
            .where((p) => p.id != widget.product.id)
            .toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return _buildProductsDiscoverySection(
          icon: Icons.storefront_rounded,
          iconColor: UzaColors.secondary,
          title: 'Même Vendeur',
          subtitle: 'Découvrez d\'autres articles de cette boutique',
          products: products,
        );
      },
    );
  }

  Widget _buildSuggestionsSection() {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductRepository>().suggestedProducts(
        widget.product.id,
      ),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        return _buildProductsDiscoverySection(
          icon: Icons.favorite_rounded,
          iconColor: UzaColors.primary,
          title: tr(context, 'similar_products'),
          subtitle: 'Sélectionnés selon vos goûts et tendances',
          products: products,
          emptyMessage: tr(context, 'similar_products_empty'),
        );
      },
    );
  }

  Widget _buildProductsDiscoverySection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Product> products,
    String? emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductSectionHeader(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          count: products.length,
        ),
        const SizedBox(height: 14),
        if (products.isEmpty && emptyMessage != null)
          _buildSuggestionsEmptyState(emptyMessage, iconColor)
        else if (products.isNotEmpty)
          _buildVerticalProductGrid(products, accentColor: iconColor),
      ],
    );
  }

  Widget _buildProductSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor, iconColor.withValues(alpha: 0.45)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withValues(alpha: 0.14),
                iconColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: UzaColors.onSurface(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: iconColor.withValues(alpha: 0.15)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsEmptyState(String message, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.06),
            Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: accentColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalProductGrid(
    List<Product> products, {
    required Color accentColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : (screenWidth > 600 ? 3 : 2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: screenWidth < 360 ? 0.68 : 0.72,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildRelatedProductTile(products[index], accentColor);
        },
      ),
    );
  }

  Widget _buildRelatedProductTile(Product product, Color accentColor) {
    final images = ImageUtils.getDecryptedList(product.imageUrls);
    final firstImage = images.isNotEmpty ? images.first : '';
    final priceLabel = ProductPriceUtils.displayLabel(product);

    return TapAnimator(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: firstImage.isEmpty
                        ? ImageUtils.buildPlaceholder()
                        : ImageUtils.buildCachedImage(
                            firstImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 12,
                        color: accentColor,
                      ),
                    ),
                  ),
                  if (product.condition.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.2,
                      height: 1.2,
                      color: UzaColors.onSurface(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          priceLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.viewsCount > 0) ...[
                        Icon(
                          Icons.visibility_outlined,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.viewsCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    ShopRepository shopRepo, {
    bool isDesktop = false,
  }) {
    return Container(
      padding: isDesktop
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: isDesktop
          ? null
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
              onPressed: () => _handleContactTap(context, shopRepo),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
              label: Text(
                tr(context, 'contact_seller'),
                style: const TextStyle(fontWeight: FontWeight.bold),
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
              onPressed: () => _handleAddressTap(context, shopRepo),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text(
                tr(context, 'address'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UzaColors.secondary,
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
  }

  Future<void> _handleContactTap(
    BuildContext context,
    ShopRepository shopRepo,
  ) async {
    HapticFeedback.lightImpact();
    final shop = await _cachedShopFuture(shopRepo);
    if (!context.mounted) return;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'shop_not_found'))),
      );
      return;
    }
    final hasWhatsApp = shop.whatsapp?.trim().isNotEmpty == true;
    final hasPhone = shop.phone?.trim().isNotEmpty == true;
    if (!hasWhatsApp && !hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'whatsapp_unavailable'))),
      );
      return;
    }
    _showContactOptions(context, shop);
  }

  Future<void> _handleAddressTap(
    BuildContext context,
    ShopRepository shopRepo,
  ) async {
    HapticFeedback.lightImpact();
    final shop = await _cachedShopFuture(shopRepo);
    if (!context.mounted) return;
    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'shop_not_found'))),
      );
      return;
    }
    final hasCoords = shop.latitude != null && shop.longitude != null;
    final addressQuery = _shopLocationQuery(shop);
    if (!hasCoords && (addressQuery == null || addressQuery.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'location_error'))),
      );
      return;
    }
    await LocationService.openShopLocation(
      latitude: shop.latitude,
      longitude: shop.longitude,
      destinationName: shop.name,
      addressQuery: addressQuery,
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
    _onContactClicked('whatsapp');
    ContactSellerSheet.show(
      context,
      shop: shop,
      product: widget.product,
    );
  }
}
