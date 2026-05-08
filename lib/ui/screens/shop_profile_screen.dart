import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/location_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../components/product_card.dart';
import 'product_detail_screen.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../components/uza_bottom_nav.dart';
import 'home_screen.dart';
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

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  bool _isShopVerified(BuildContext context) {
    return widget.shop.isVerified;
  }

  /// Update shop location
  Future<void> _updateLocation() async {
    // Check if user is the shop owner
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;

    if (userId == null || widget.shop.ownerId != userId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seul le proprietaire peut modifier la localisation.',
            ),
          ),
        );
      }
      return;
    }

    // Show security notice
    LocationService.showSecurityNotice(context);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    LocationService.showLocationLoading(context);

    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (location != null) {
        final lat = location['latitude']!;
        final lng = location['longitude']!;

        // Update shop with location
        final shopRepo = context.read<ShopRepository>();
        await shopRepo.updateShop(
          ShopsCompanion(
            id: drift.Value(widget.shop.id),
            latitude: drift.Value(lat),
            longitude: drift.Value(lng),
          ),
        );

        // Also queue for server sync
        final syncService = context.read<SyncService>();
        await syncService.addToQueue('UPDATE', 'shops', {
          'id': widget.shop.id,
          'latitude': lat,
          'longitude': lng,
        });

        syncService.forcePush();

        if (mounted) {
          LocationService.showLocationSuccess(
            context,
            latitude: lat,
            longitude: lng,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de capturer la localisation. Verifiez les permissions.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
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
                    onPressed: () => context
                        .read<ShopRepository>()
                        .toggleFollowShop(shop.id),
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
          bottomNavigationBar: UzaBottomNav(
            currentIndex:
                0, // Profile always seen as part of home flow or a secondary level
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(initialIndex: index),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ),
        desktop: Scaffold(
          appBar: AppBar(
            title: Text(shop.name.toUpperCase()),
            actions: [
              StreamBuilder<bool>(
                stream: context.read<ShopRepository>().watchIsFollowingShop(
                  shop.id,
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
                    onPressed: () => context
                        .read<ShopRepository>()
                        .toggleFollowShop(shop.id),
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
                                    if (shop.address != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shop.address!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // Update location button for shop owner
                                    _buildUpdateLocationButton(context, shop),
                                    // Prominent location button if coordinates exist
                                    if (shop.latitude != null &&
                                        shop.longitude != null) ...[
                                      const SizedBox(height: 16),
                                      InkWell(
                                        onTap: () =>
                                            _showLocationOptions(context, shop),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.teal.withValues(
                                                  alpha: 0.1,
                                                ),
                                                Colors.teal.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.teal.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.navigation,
                                                  color: Colors.teal,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Obtenir l\'itineraire',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.teal,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Ouvrir dans Google Maps',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Colors.teal,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      shop.description ?? 'Aucune description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: _buildFollowButton(context),
                                        ),
                                        const SizedBox(width: 16),
                                        Flexible(
                                          child: _buildSocialActions(
                                            contactService,
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
                              const SizedBox(height: 16),
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
                              if (shop.address != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      shop.address!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Update location button for shop owner
                              _buildUpdateLocationButton(context, shop),
                              // Prominent location button if coordinates exist
                              if (shop.latitude != null &&
                                  shop.longitude != null) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () =>
                                      _showLocationOptions(context, shop),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.withValues(alpha: 0.1),
                                          Colors.teal.withValues(alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.teal.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.navigation,
                                            color: Colors.teal,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Obtenir l\'itineraire',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                shop.description ?? 'Aucune description',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                              const SizedBox(height: 24),
                              _buildFollowButton(context),
                              const SizedBox(height: 24),
                              _buildSocialActions(contactService),
                            ],
                          ),
                  ),
                ),
                _buildStatsSection(context),

                _buildVideo(context),
                _buildBanner(),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'Catalogue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                StreamBuilder<List<Product>>(
                  stream: productRepo.watchProductsByShop(shop.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text('Aucun produit disponible.'),
                            ],
                          ),
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

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: constraints.maxWidth > 700
                              ? 0.75
                              : 0.86,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = snapshot.data![index];
                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                          );
                        }, childCount: snapshot.data!.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideo(BuildContext context) {
    final shop = widget.shop;
    final videoUrl = CryptoUtils.decrypt(shop.videoUrl ?? '');
    if (videoUrl.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

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
    if (shop.bannerStatus != 2 || bannerUrl.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

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
    return StreamBuilder<bool>(
      stream: context.read<ShopRepository>().watchIsFollowingShop(shop.id),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        return ElevatedButton.icon(
          onPressed: () =>
              context.read<ShopRepository>().toggleFollowShop(shop.id),
          icon: Icon(isFollowing ? Icons.check : Icons.add, size: 18),
          label: Text(isFollowing ? 'SUIVI' : 'SUIVRE LA BOUTIQUE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[200] : UzaColors.primary,
            foregroundColor: isFollowing ? Colors.black87 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialActions(ContactService contactService) {
    final shop = widget.shop;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (shop.phone != null)
            _SocialIcon(
              icon: Icons.phone,
              color: UzaColors.primary,
              onTap: () => contactService.makeCall(
                phone: shop.phone!,
                entityType: 'shop',
                entityId: shop.id,
              ),
            ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
          if (shop.instagramUrl != null)
            _SocialIcon(
              icon: FontAwesomeIcons.instagram,
              color: const Color(0xFFE4405F),
              onTap: () => contactService.launchSocial(
                urlString: shop.instagramUrl!,
                entityType: 'shop',
                entityId: shop.id,
              ),
            ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
          if (shop.youtubeUrl != null)
            _SocialIcon(
              icon: FontAwesomeIcons.youtube,
              color: const Color(0xFFFF0000),
              onTap: () => contactService.launchSocial(
                urlString: shop.youtubeUrl!,
                entityType: 'shop',
                entityId: shop.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final shop = widget.shop;
    final isOwner = context.read<AuthService>().user?.uid == shop.ownerId;
    if (!isOwner) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final db = context.read<UzaDatabase>();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: StreamBuilder<List<Product>>(
          stream: context.read<ProductRepository>().watchProductsByShop(
            shop.id,
          ),
          builder: (context, productSnapshot) {
            final products = productSnapshot.data ?? [];
            final totalViews = products.fold<int>(
              0,
              (sum, p) => sum + p.viewsCount,
            );
            final totalProducts = products.length;

            return StreamBuilder(
              stream: (db.select(
                db.userContacts,
              )..where((t) => t.shopId.equals(shop.id))).watch(),
              builder: (context, contactSnapshot) {
                final totalContacts = contactSnapshot.data?.length ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.remove_red_eye_outlined,
                        value: totalViews,
                        label: 'Vues',
                      ),
                      _buildStatItem(
                        icon: Icons.phone_outlined,
                        value: totalContacts,
                        label: 'Contacts',
                      ),
                      _buildStatItem(
                        icon: Icons.shopping_bag_outlined,
                        value: totalProducts,
                        label: 'Produits',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
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

  /// Build update location button (only visible to shop owner)
  Widget _buildUpdateLocationButton(BuildContext context, Shop shop) {
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;

    // Only show button if user is the shop owner
    if (userId == null || shop.ownerId != userId) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: _updateLocation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UzaColors.primary.withValues(alpha: 0.1),
                UzaColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: UzaColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: UzaColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_location_alt,
                  color: UzaColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier la localisation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: UzaColors.primary,
                      ),
                    ),
                    Text(
                      'Mettre a jour la position GPS',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: UzaColors.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationOptions(BuildContext context, Shop shop) {
    if (shop.latitude == null || shop.longitude == null) return;

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
                'Localisation de la boutique',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                shop.name.toUpperCase(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions, color: Colors.teal),
                ),
                title: const Text('Obtenir l\'itineraire'),
                subtitle: const Text('Guidage vers la boutique'),
                onTap: () {
                  Navigator.pop(context);
                  LocationService.getDirections(
                    latitude: shop.latitude!,
                    longitude: shop.longitude!,
                    destinationName: shop.name,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
        icon: FaIcon(icon, color: color, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
