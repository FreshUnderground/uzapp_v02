import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/location_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/product_card.dart';
import 'product_detail_screen.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../components/responsive_layout.dart';
import '../components/shop_video_player.dart';

class ShopProfileScreen extends StatefulWidget {
  final Shop shop;

  const ShopProfileScreen({super.key, required this.shop});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _shopLocationText(Shop shop) {
    final fullAddress = shop.address?.trim();
    if (fullAddress != null && fullAddress.isNotEmpty) {
      return fullAddress;
    }

    final city = shop.city?.trim();
    final commune = shop.commune?.trim();
    if (city != null &&
        city.isNotEmpty &&
        commune != null &&
        commune.isNotEmpty) {
      return '$commune, $city';
    }
    if (city != null && city.isNotEmpty) {
      return city;
    }
    if (commune != null && commune.isNotEmpty) {
      return commune;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isShopVerified(BuildContext context) {
    return widget.shop.isVerified;
  }

  bool _isShopOwner(BuildContext context) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return widget.shop.phone == userPhone || widget.shop.ownerId == userPhone;
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final contactService = context.read<ContactService>();
    final shop = widget.shop;

    return Title(
      title: '${shop.name.toUpperCase()} | UZAAPP',
      color: Colors.white,
      child: ResponsiveLayout(
        mobile: Scaffold(
          appBar: AppBar(
            title: Text(shop.name.toUpperCase()),
            actions: [
              StreamBuilder<bool>(
                stream: context.read<ShopRepository>().watchIsFollowingShop(
                  shop.id,
                  userPhone:
                      context.read<AuthService>().user?.phoneNumber ?? '',
                ),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isFollowing
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: isFollowing ? UzaColors.primary : null,
                    ),
                    onPressed: () =>
                        context.read<ShopRepository>().toggleFollowShop(
                          shop.id,
                          userPhone:
                              context.read<AuthService>().user?.phoneNumber ??
                              '',
                        ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => contactService.shareShop(shop),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(productRepo, contactService),
        ),
        desktop: Scaffold(
          appBar: AppBar(
            title: Text(shop.name.toUpperCase()),
            actions: [
              StreamBuilder<bool>(
                stream: context.read<ShopRepository>().watchIsFollowingShop(
                  shop.id,
                  userPhone:
                      context.read<AuthService>().user?.phoneNumber ?? '',
                ),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isFollowing
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: isFollowing ? UzaColors.primary : null,
                    ),
                    onPressed: () =>
                        context.read<ShopRepository>().toggleFollowShop(
                          shop.id,
                          userPhone:
                              context.read<AuthService>().user?.phoneNumber ??
                              '',
                        ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => contactService.shareShop(shop),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(productRepo, contactService),
        ),
      ),
    );
  }

  Widget _buildBody(
    ProductRepository productRepo,
    ContactService contactService,
  ) {
    final shop = widget.shop;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final contentWidth = isWide ? 1000.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImageUtils.getLogoWidget(shop.logoUrl, size: 120),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          shop.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_isShopVerified(context)) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (_) {
                                        final locationText =
                                            _shopLocationText(shop);
                                        final hasLocation =
                                            locationText != null &&
                                            locationText.isNotEmpty;
                                        return Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 18,
                                              color: hasLocation
                                                  ? Colors.grey
                                                  : Colors.orange,
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                hasLocation
                                                    ? locationText
                                                    : 'Localisation non renseignée',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: hasLocation
                                                      ? Colors.grey
                                                      : Colors.orange[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    // Itinerary button - compact single line
                                    _buildUpdateLocationButton(context, shop),
                                    const SizedBox(height: 12),
                                    Text(
                                      shop.description ?? 'Aucune description',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Centered row with Follow and Social buttons
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildFollowButton(context),
                                        if (shop.whatsapp != null ||
                                            shop.phone != null)
                                          _buildSocialButton(
                                            icon: FontAwesomeIcons.whatsapp,
                                            color: Colors.green,
                                            onTap: () =>
                                                contactService.launchWhatsApp(
                                                  phone:
                                                      shop.whatsapp ??
                                                      shop.phone!,
                                                  entityType: 'shop',
                                                  entityId: shop.id,
                                                  name: shop.name,
                                                  productUrl:
                                                      'https://uzaapp.com/shop/${shop.id}',
                                                ),
                                          ),
                                        if (shop.facebookUrl != null)
                                          _buildSocialButton(
                                            icon: FontAwesomeIcons.facebook,
                                            color: const Color(0xFF1877F2),
                                            onTap: () =>
                                                contactService.launchSocial(
                                                  urlString: shop.facebookUrl!,
                                                  entityType: 'shop',
                                                  entityId: shop.id,
                                                ),
                                          ),
                                        if (shop.tiktokUrl != null)
                                          _buildSocialButton(
                                            icon: FontAwesomeIcons.tiktok,
                                            color: Colors.black,
                                            onTap: () =>
                                                contactService.launchSocial(
                                                  urlString: shop.tiktokUrl!,
                                                  entityType: 'shop',
                                                  entityId: shop.id,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              ImageUtils.getLogoWidget(shop.logoUrl, size: 100),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    shop.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_isShopVerified(context)) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (_) {
                                  final locationText = _shopLocationText(shop);
                                  final hasLocation =
                                      locationText != null &&
                                      locationText.isNotEmpty;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: hasLocation
                                            ? Colors.grey
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          hasLocation
                                              ? locationText
                                              : 'Localisation non renseignée',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: hasLocation
                                                ? Colors.grey
                                                : Colors.orange[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // Itinerary button - compact single line
                              _buildUpdateLocationButton(context, shop),
                              const SizedBox(height: 8),
                              Text(
                                shop.description ?? 'Aucune description',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Centered row with Follow and Social buttons
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFollowButton(context),
                                  if (shop.whatsapp != null ||
                                      shop.phone != null)
                                    _buildSocialButton(
                                      icon: FontAwesomeIcons.whatsapp,
                                      color: Colors.green,
                                      onTap: () => contactService.launchWhatsApp(
                                        phone: shop.whatsapp ?? shop.phone!,
                                        entityType: 'shop',
                                        entityId: shop.id,
                                        name: shop.name,
                                        productUrl:
                                            'https://uzaapp.com/shop/${shop.id}',
                                      ),
                                    ),
                                  if (shop.facebookUrl != null)
                                    _buildSocialButton(
                                      icon: FontAwesomeIcons.facebook,
                                      color: const Color(0xFF1877F2),
                                      onTap: () => contactService.launchSocial(
                                        urlString: shop.facebookUrl!,
                                        entityType: 'shop',
                                        entityId: shop.id,
                                      ),
                                    ),
                                  if (shop.tiktokUrl != null)
                                    _buildSocialButton(
                                      icon: FontAwesomeIcons.tiktok,
                                      color: Colors.black,
                                      onTap: () => contactService.launchSocial(
                                        urlString: shop.tiktokUrl!,
                                        entityType: 'shop',
                                        entityId: shop.id,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),

                _buildVideo(context),
                _buildBanner(),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(),
                  ),
                ),

                // Tab Bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: UzaColors.primary,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: UzaColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[700],
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag, size: 14),
                              SizedBox(width: 4),
                              Text('Produits'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.new_releases, size: 14),
                              SizedBox(width: 4),
                              Text('Arrivages'),
                            ],
                          ),
                        ),
                      ],
                      tabAlignment: TabAlignment.fill,
                      padding: EdgeInsets.zero,
                      indicatorPadding: const EdgeInsets.all(3),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                    ),
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Produits Tab
                      _buildProductsTab(context, productRepo, constraints),
                      // Arrivages Tab
                      _buildArrivagesTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    ProductRepository productRepo,
    BoxConstraints constraints,
  ) {
    final shop = widget.shop;
    return StreamBuilder<List<Product>>(
      stream: productRepo.watchProductsByShop(shop.id),
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
                  Icons.shopping_bag_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun produit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les produits de cette boutique\napparaîtront ici',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: constraints.maxWidth > 700 ? 0.75 : 0.86,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            return ProductCard(
              product: product,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArrivagesTab(BuildContext context) {
    final shop = widget.shop;
    return StreamBuilder<List<Story>>(
      stream: context.read<StoryRepository>().watchArrivagesByShop(shop.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.new_releases, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucun arrivage',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les nouveaux arrivages de cette boutique\napparaîtront ici',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final arrivages = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: arrivages.length,
          itemBuilder: (context, index) {
            final story = arrivages[index];
            final decryptedUrl = CryptoUtils.decrypt(story.mediaUrl);
            return GestureDetector(
              onTap: () {
                // Navigate to story view
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Media content
                      story.mediaType == 'video'
                          ? Container(
                              color: Colors.black,
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 48,
                              ),
                            )
                          : ImageUtils.buildCachedImage(
                              decryptedUrl,
                              fit: BoxFit.contain,
                            ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: UzaColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_new,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Nouveau',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Timestamp
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              story.mediaType == 'video'
                                  ? '🎥 Vidéo'
                                  : '📷 Photo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTimeAgo(story.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete button for shop owner
                      if (_isShopOwner(context))
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _confirmDeleteStory(context, story),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  void _confirmDeleteStory(BuildContext context, Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
          story.isArrivage
              ? 'Voulez-vous vraiment supprimer cet arrivage ?'
              : 'Voulez-vous vraiment supprimer cette story ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Use deleteStoryWithSync to propagate deletion to all users
              await context.read<StoryRepository>().deleteStoryWithSync(
                story.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supprimé avec succès'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    final shop = widget.shop;
    final videoUrl = CryptoUtils.decrypt(shop.videoUrl ?? '');
    if (videoUrl.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Présentation Vidéo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ShopVideoPlayer(videoUrl: videoUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final shop = widget.shop;
    final bannerUrl = CryptoUtils.decrypt(shop.bannerUrl ?? '');
    if (shop.bannerStatus != 2 || bannerUrl.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ImageUtils.buildCachedImage(
            bannerUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    final shop = widget.shop;
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return StreamBuilder<bool>(
      stream: context.read<ShopRepository>().watchIsFollowingShop(
        shop.id,
        userPhone: userPhone,
      ),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        return StreamBuilder<int>(
          stream: context.read<ShopRepository>().watchFollowerCount(shop.id),
          builder: (context, countSnapshot) {
            final followerCount = countSnapshot.data ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<ShopRepository>()
                      .toggleFollowShop(shop.id, userPhone: userPhone),
                  icon: Icon(isFollowing ? Icons.check : Icons.add, size: 14),
                  label: Text(
                    isFollowing ? 'Suivi' : 'Suivre',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.grey[200]
                        : UzaColors.primary,
                    foregroundColor: isFollowing
                        ? Colors.black87
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                ),
                if (followerCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$followerCount',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      child: FaIcon(icon, size: 14),
    );
  }

  Widget _buildSocialActions(ContactService contactService) {
    final shop = widget.shop;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (shop.whatsapp != null || shop.phone != null)
            _SocialIcon(
              icon: FontAwesomeIcons.whatsapp,
              color: Colors.green,
              onTap: () => contactService.launchWhatsApp(
                phone: shop.whatsapp ?? shop.phone!,
                entityType: 'shop',
                entityId: shop.id,
                name: shop.name,
                productUrl: 'https://uzaapp.com/shop/${shop.id}',
              ),
            ),
          const SizedBox(width: 3),
          if (shop.facebookUrl != null)
            _SocialIcon(
              icon: FontAwesomeIcons.facebook,
              color: const Color(0xFF1877F2),
              onTap: () => contactService.launchSocial(
                urlString: shop.facebookUrl!,
                entityType: 'shop',
                entityId: shop.id,
              ),
            ),
          const SizedBox(width: 3),
          if (shop.tiktokUrl != null)
            _SocialIcon(
              icon: FontAwesomeIcons.tiktok,
              color: Colors.black,
              onTap: () => contactService.launchSocial(
                urlString: shop.tiktokUrl!,
                entityType: 'shop',
                entityId: shop.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: UzaColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// Build itinerary button (only visible to shop owner)
  Widget _buildUpdateLocationButton(BuildContext context, Shop shop) {
    // Only show button if shop has coordinates
    if (shop.latitude == null || shop.longitude == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          LocationService.getDirections(
            latitude: shop.latitude!,
            longitude: shop.longitude!,
            destinationName: shop.name,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UzaColors.secondary.withValues(alpha: 0.1),
                UzaColors.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: UzaColors.secondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.navigation, color: UzaColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Aller à la Boutique',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: UzaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 14),
        onPressed: onTap,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
