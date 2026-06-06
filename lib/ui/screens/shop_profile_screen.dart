import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_nav_utils.dart';
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
import '../../core/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/picker_utils.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/profile_shop_sync.dart';
import '../components/responsive_layout.dart';
import '../components/animated_bottom_nav.dart';
import '../components/shop_video_player.dart';
import 'story_view_screen.dart';
import 'edit_shop_screen.dart';

class ShopProfileScreen extends StatefulWidget {
  final Shop shop;

  const ShopProfileScreen({super.key, required this.shop});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  static const double _actionButtonHeight = 36;

  late TabController _tabController;
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  Uint8List? _logoBytes;

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
      return '$city, $commune';
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
    _nameController = TextEditingController(text: widget.shop.name);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(Shop shop) {
    setState(() {
      _isEditing = true;
      _nameController.text = shop.name;
      _logoBytes = null;
    });
  }

  void _cancelEditing(Shop shop) {
    setState(() {
      _isEditing = false;
      _nameController.text = shop.name;
      _logoBytes = null;
    });
  }

  Future<void> _showLogoSourceSheet() async {
    final source = await showModalBottomSheet<PickerImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, PickerImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, PickerImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final bytes = await PickerUtils.pickImage(context, source: source);
    if (bytes == null || !mounted) return;
    setState(() => _logoBytes = bytes);
  }

  Future<void> _saveProfile(Shop shop) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la boutique est requis')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? logoUrl;
      if (_logoBytes != null) {
        setState(() => _isUploadingLogo = true);
        final prepared = await ImagePrepareUtils.prepareForUpload(
          _logoBytes!,
          prefix: 'shop_logo_${shop.id}',
        );
        logoUrl = await context.read<ApiService>().uploadFile(
          prepared.bytes,
          prepared.fileName,
        );
        setState(() => _isUploadingLogo = false);
        if (logoUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'upload du logo')),
          );
        }
      }

      await ProfileShopSync.syncToShop(
        context,
        shop: shop,
        name: name,
        logoUrl: logoUrl,
      );
      await ProfileShopSync.syncToProfile(
        context,
        name: name,
        avatarUrl: logoUrl,
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _logoBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingLogo = false;
        });
      }
    }
  }

  bool _isShopVerified(Shop shop) {
    return shop.isVerified;
  }

  bool _isShopOwner(BuildContext context, Shop shop) {
    final userPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    return shop.phone == userPhone || shop.ownerId == userPhone;
  }

  List<Widget> _buildAppBarActions(
    Shop shop,
    ContactService contactService,
  ) {
    final isOwner = _isShopOwner(context, shop);
    final actions = <Widget>[];

    if (isOwner) {
      if (_isEditing) {
        actions.add(
          TextButton(
            onPressed: _isSaving ? null : () => _cancelEditing(shop),
            child: const Text('Annuler'),
          ),
        );
        actions.add(
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveProfile(shop),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? '...' : 'Enregistrer'),
          ),
        );
      } else {
        actions.add(
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier le profil',
            onPressed: () => _startEditing(shop),
          ),
        );
        actions.add(
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres de la boutique',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditShopScreen(shop: shop),
              ),
            ),
          ),
        );
      }
    }

    if (!isOwner || !_isEditing) {
      actions.add(
        StreamBuilder<bool>(
          stream: context.read<ShopRepository>().watchIsFollowingShop(
            shop.id,
            userPhone: context.read<AuthService>().user?.phoneNumber ?? '',
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
              onPressed: () => context.read<ShopRepository>().toggleFollowShop(
                shop.id,
                userPhone:
                    context.read<AuthService>().user?.phoneNumber ?? '',
              ),
            );
          },
        ),
      );
      actions.add(
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => contactService.shareShop(shop),
        ),
      );
    }

    actions.add(const SizedBox(width: 8));
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final contactService = context.read<ContactService>();

    return StreamBuilder<Shop?>(
      stream: context.read<ShopRepository>().watchShopById(widget.shop.id),
      initialData: widget.shop,
      builder: (context, snapshot) {
        final shop = snapshot.data ?? widget.shop;

        return Title(
          title: '${shop.name.toUpperCase()} | UZAAPP',
          color: Colors.white,
          child: ResponsiveLayout(
            mobile: Scaffold(
              appBar: AppBar(
                title: Text(shop.name.toUpperCase()),
                actions: _buildAppBarActions(shop, contactService),
              ),
              body: _buildBody(shop, productRepo, contactService),
              bottomNavigationBar: AnimatedBottomNav(
                currentIndex: AppNavUtils.overlayTabIndex,
                onTap: (index) => AppNavUtils.navigateToTab(context, index),
              ),
            ),
            desktop: Scaffold(
              appBar: AppBar(
                title: Text(shop.name.toUpperCase()),
                actions: _buildAppBarActions(shop, contactService),
              ),
              body: _buildBody(shop, productRepo, contactService),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopLogo(Shop shop, {required double size}) {
    if (_isUploadingLogo) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_logoBytes != null) {
      return GestureDetector(
        onTap: _isEditing ? _showLogoSourceSheet : null,
        child: Stack(
          children: [
            ClipOval(
              child: Image.memory(
                _logoBytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
            if (_isEditing) _buildCameraOverlay(),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isEditing ? _showLogoSourceSheet : null,
      child: Stack(
        children: [
          ImageUtils.getLogoWidget(shop.logoUrl, size: size),
          if (_isEditing) _buildCameraOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: UzaColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
      ),
    );
  }

  String? _getCoverImageSource(Shop shop) {
    return ImageUtils.getShopCoverSource(shop.bannerUrl, shop.logoUrl);
  }

  bool _coverUsesBanner(Shop shop) {
    return shop.bannerUrl != null &&
        shop.bannerUrl!.isNotEmpty &&
        ImageUtils.resolveImageUrl(shop.bannerUrl) != null;
  }

  Widget _buildCoverBackground(String? coverSource) {
    if (coverSource != null) {
      return ImageUtils.buildCachedImage(
        coverSource,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: _buildCoverGradient(),
      );
    }
    return _buildCoverGradient();
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UzaColors.primary, Color(0xFFD84315)],
        ),
      ),
    );
  }

  Widget _buildLogoWithBorder(Shop shop, {required double size}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildShopLogo(shop, size: size),
    );
  }

  Widget _buildShopInfoSection(
    Shop shop,
    ContactService contactService, {
    required bool isWide,
    required Color mutedText,
  }) {
    final nameStyle = TextStyle(
      fontSize: isWide ? 32 : 24,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _buildShopName(
                shop,
                textAlign: TextAlign.center,
                style: nameStyle,
              ),
            ),
            if (_isShopVerified(shop)) ...[
              const SizedBox(width: 6),
              Icon(Icons.verified, color: Colors.blue, size: isWide ? 18 : 16),
            ],
          ],
        ),
        SizedBox(height: isWide ? 4 : 2),
        Builder(
          builder: (_) {
            final locationText = _shopLocationText(shop);
            final hasLocation =
                locationText != null && locationText.isNotEmpty;
            final socialLinks = _buildInlineSocialLinks(shop, contactService);
            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isWide ? 16 : 14,
                        color: hasLocation ? Colors.grey : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLocation
                            ? locationText
                            : 'Localisation non renseignée',
                        style: TextStyle(
                          fontSize: isWide ? 14 : 12,
                          color:
                              hasLocation ? Colors.grey : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  socialLinks,
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildGoToShopButton(context, shop)),
            const SizedBox(width: 8),
            _buildFollowButton(context, shop, compact: true),
          ],
        ),
        SizedBox(height: isWide ? 12 : 8),
        Text(
          shop.description ?? 'Aucune description',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedText, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    Shop shop,
    ContactService contactService, {
    required bool isWide,
    required Color mutedText,
  }) {
    final coverSource = _getCoverImageSource(shop);
    final coverHeight = isWide ? 180.0 : 140.0;
    final logoSize = isWide ? 110.0 : 96.0;
    final logoOverlap = logoSize / 2;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: SizedBox(
                height: coverHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverBackground(coverSource),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -logoOverlap,
              child: _buildLogoWithBorder(shop, size: logoSize),
            ),
          ],
        ),
        SizedBox(height: logoOverlap + (isWide ? 10 : 8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildShopInfoSection(
            shop,
            contactService,
            isWide: isWide,
            mutedText: mutedText,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildShopName(
    Shop shop, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (_isEditing) {
      return TextField(
        controller: _nameController,
        enabled: !_isSaving,
        style: style,
        textAlign: textAlign,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: style.color?.withValues(alpha: 0.5) ?? Colors.grey,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: style.color ?? Colors.black),
          ),
        ),
      );
    }

    return Text(shop.name.toUpperCase(), style: style);
  }

  Widget _buildBody(
    Shop shop,
    ProductRepository productRepo,
    ContactService contactService,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = theme.colorScheme.onSurface.withValues(alpha: 0.6);
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
                  child: _buildProfileHeader(
                    shop,
                    contactService,
                    isWide: isWide,
                    mutedText: mutedText,
                  ),
                ),

                _buildVideo(context, shop),
                _buildBanner(shop),
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
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey[100],
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
                      unselectedLabelColor: mutedText,
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
                      _buildProductsTab(
                        context,
                        shop,
                        productRepo,
                        constraints,
                      ),
                      // Arrivages Tab
                      _buildArrivagesTab(context, shop),
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
    Shop shop,
    ProductRepository productRepo,
    BoxConstraints constraints,
  ) {
    return StreamBuilder<List<Product>>(
      stream: productRepo.watchProductsByShop(shop.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
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

  Future<void> _openArrivage(
    BuildContext context,
    Shop shop,
    List<Story> arrivages,
    int index,
  ) async {
    final storyRepo = context.read<StoryRepository>();
    final story = arrivages[index];
    storyRepo.logStoryView(story.id);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewScreen(
          stories: arrivages,
          initialIndex: index,
          shopLookup: {shop.id: shop},
          getViewCount: storyRepo.getStoryViewCount,
        ),
      ),
    );
  }

  Widget _buildArrivagesTab(BuildContext context, Shop shop) {
    return StreamBuilder<List<Story>>(
      stream: context.read<StoryRepository>().watchArrivagesByShop(shop.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
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
            return GestureDetector(
              onTap: () => _openArrivage(context, shop, arrivages, index),
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
                              story.mediaUrl,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white54,
                                  size: 36,
                                ),
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
                      if (_isShopOwner(context, shop))
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

  Widget _buildVideo(BuildContext context, Shop shop) {
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

  Widget _buildBanner(Shop shop) {
    if (shop.bannerStatus != 2 ||
        shop.bannerUrl == null ||
        shop.bannerUrl!.isEmpty ||
        _coverUsesBanner(shop)) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ImageUtils.buildCachedImage(
            shop.bannerUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    Shop shop, {
    bool compact = false,
  }) {
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
            final followButton = ElevatedButton.icon(
              onPressed: () => context
                  .read<ShopRepository>()
                  .toggleFollowShop(shop.id, userPhone: userPhone),
              icon: Icon(
                isFollowing ? Icons.check : Icons.add,
                size: compact ? 16 : 14,
              ),
              label: Text(
                isFollowing ? 'Suivi' : 'Suivre',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : UzaColors.primary,
                foregroundColor: isFollowing
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 0 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 8 : 18),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: compact
                    ? const Size(0, _actionButtonHeight)
                    : Size.zero,
              ),
            );

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact)
                  SizedBox(
                    height: _actionButtonHeight,
                    child: followButton,
                  )
                else
                  followButton,
                if (!compact && followerCount > 0) ...[
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

  Widget _buildInlineSocialLinks(Shop shop, ContactService contactService) {
    final links = <Widget>[];

    void addLink({
      required bool visible,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) {
      if (!visible) return;
      if (links.isNotEmpty) links.add(const SizedBox(width: 3));
      links.add(_SocialIcon(icon: icon, color: color, onTap: onTap));
    }

    addLink(
      visible: shop.whatsapp?.trim().isNotEmpty == true ||
          shop.phone?.trim().isNotEmpty == true,
      icon: FontAwesomeIcons.whatsapp,
      color: Colors.green,
      onTap: () => contactService.launchWhatsApp(
        phone: shop.whatsapp ?? shop.phone!,
        entityType: 'shop',
        entityId: shop.id,
        name: shop.name,
        productUrl: 'https://uzaapp.com/shop/${shop.id}',
      ),
    );
    addLink(
      visible: shop.facebookUrl?.trim().isNotEmpty == true,
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      onTap: () => contactService.launchSocial(
        urlString: shop.facebookUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );
    addLink(
      visible: shop.instagramUrl?.trim().isNotEmpty == true,
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      onTap: () => contactService.launchSocial(
        urlString: shop.instagramUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );
    addLink(
      visible: shop.tiktokUrl?.trim().isNotEmpty == true,
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      onTap: () => contactService.launchSocial(
        urlString: shop.tiktokUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );
    addLink(
      visible: shop.youtubeUrl?.trim().isNotEmpty == true,
      icon: FontAwesomeIcons.youtube,
      color: Colors.red,
      onTap: () => contactService.launchSocial(
        urlString: shop.youtubeUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );

    if (links.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: links);
  }

  Widget _buildGoToShopButton(BuildContext context, Shop shop) {
    final hasCoords = shop.latitude != null && shop.longitude != null;

    return InkWell(
      onTap: hasCoords
          ? () => LocationService.getDirections(
                latitude: shop.latitude!,
                longitude: shop.longitude!,
                destinationName: shop.name,
              )
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: _actionButtonHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              UzaColors.secondary.withValues(alpha: hasCoords ? 0.1 : 0.05),
              UzaColors.secondary.withValues(alpha: hasCoords ? 0.05 : 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: UzaColors.secondary.withValues(
              alpha: hasCoords ? 0.3 : 0.15,
            ),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation,
              color: hasCoords ? UzaColors.secondary : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Aller à la Boutique',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: hasCoords ? UzaColors.secondary : Colors.grey,
              ),
            ),
          ],
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
        icon: FaIcon(icon, color: color, size: 11),
        onPressed: onTap,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
