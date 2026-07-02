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
import '../../core/utils/phone_utils.dart';
import '../../core/utils/shop_qr_utils.dart';
import '../../core/utils/picker_utils.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/profile_shop_sync.dart';
import '../components/contact_seller_sheet.dart';
import '../components/responsive_layout.dart';
import '../components/animated_bottom_nav.dart';
import '../components/uza_back_button.dart';
import '../components/shop_share_sheet.dart';
import '../components/arrivage_thumbnail.dart';
import '../components/async_content.dart';
import '../components/empty_state.dart';
import '../../core/l10n/tr.dart';
import '../components/shop_video_player.dart';
import '../components/modern_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShopRepository>().logShopInteraction(widget.shop.id, 'view');
    });
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
              title: Text(tr(context, 'gallery')),
              onTap: () => Navigator.pop(context, PickerImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr(context, 'camera')),
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
        SnackBar(content: Text(tr(context, 'shop_name_required'))),
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
            SnackBar(content: Text(tr(context, 'logo_upload_failed'))),
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
        SnackBar(content: Text(tr(context, 'profile_updated'))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(context, 'error_with_message', {'message': '$e'})),
          ),
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
    final user = context.read<AuthService>().user;
    if (user == null) return false;
    final keys = PhoneUtils.lookupKeys(user.uid);
    for (final field in [shop.ownerId, shop.phone, shop.whatsapp]) {
      if (field == null || field.trim().isEmpty) continue;
      if (PhoneUtils.lookupKeys(field).any(keys.contains)) return true;
    }
    return false;
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
            child: Text(tr(context, 'cancel')),
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
          onPressed: () => ShopShareSheet.show(context, shop),
        ),
      );
    }

    actions.add(const SizedBox(width: 8));
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productRepo = context.watch<ProductRepository>();
    final contactService = context.read<ContactService>();

    return StreamBuilder<Shop?>(
      stream: context.read<ShopRepository>().watchShop(widget.shop),
      initialData: widget.shop,
      builder: (context, snapshot) {
        final shop = snapshot.data ?? widget.shop;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            AppNavUtils.popRoute(context, fallback: '/shops');
          },
          child: Title(
            title: '${shop.name} | UZAAPP',
            color: Colors.white,
            child: ResponsiveLayout(
              mobile: Scaffold(
                backgroundColor: theme.colorScheme.surface,
                appBar: AppBar(
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  centerTitle: true,
                  leading: const UzaBackButton(fallbackLocation: '/shops'),
                  automaticallyImplyLeading: false,
                  title: Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: _buildAppBarActions(shop, contactService),
                ),
                body: _buildBody(shop, productRepo, contactService),
                bottomNavigationBar: AnimatedBottomNav(
                  currentIndex: AppNavUtils.overlayTabIndex,
                  onTap: (index) => AppNavUtils.navigateToTab(context, index),
                ),
              ),
              desktop: Scaffold(
                backgroundColor: theme.colorScheme.surface,
                appBar: AppBar(
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  centerTitle: false,
                  leading: const UzaBackButton(fallbackLocation: '/shops'),
                  automaticallyImplyLeading: false,
                  title: Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  actions: _buildAppBarActions(shop, contactService),
                ),
                body: _buildBody(shop, productRepo, contactService),
              ),
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
          colors: [
            Color(0xFFFE3E00),
            Color(0xFFFF6B35),
            Color(0xFF019C94),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildLogoWithBorder(Shop shop, {required double size}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildShopLogo(shop, size: size),
        ),
        if (_isShopVerified(shop))
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: UzaColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildShopInfoSection(
    Shop shop,
    ContactService contactService, {
    required bool isWide,
    required Color mutedText,
  }) {
    final theme = Theme.of(context);
    final nameStyle = TextStyle(
      fontSize: isWide ? 28 : 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: theme.colorScheme.onSurface,
    );

    final description = shop.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _buildShopName(
            shop,
            textAlign: TextAlign.center,
            style: nameStyle,
          ),
        ),
        if (_isShopVerified(shop) && !_isEditing) ...[
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: UzaColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: UzaColors.secondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    tr(context, 'verified_shop'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: UzaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (hasDescription || _isEditing) ...[
          Text(
            hasDescription ? description! : 'Aucune description',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasDescription
                  ? mutedText
                  : mutedText.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildAddressDirectionRow(shop, mutedText),
        const SizedBox(height: 14),
        _buildSocialAndFollowRow(shop, contactService),
      ],
    );
  }

  Widget _buildAddressDirectionRow(Shop shop, Color mutedText) {
    final locationText = _shopLocationText(shop);
    final hasLocation = locationText != null && locationText.isNotEmpty;
    final hasCoords = shop.latitude != null && shop.longitude != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: hasLocation ? mutedText : UzaColors.warning,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hasLocation ? locationText! : 'Localisation non renseignée',
            style: TextStyle(
              fontSize: 13,
              color: hasLocation ? mutedText : UzaColors.warning,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: _actionButtonHeight,
          child: OutlinedButton.icon(
            onPressed: hasCoords || hasLocation
                ? () => LocationService.openShopLocation(
                      latitude: shop.latitude,
                      longitude: shop.longitude,
                      destinationName: shop.name,
                      addressQuery: locationText,
                    )
                : null,
            icon: const Icon(Icons.map_outlined, size: 16),
            label: Text(
              tr(context, 'address'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              foregroundColor: UzaColors.secondary,
              side: BorderSide(
                color: (hasCoords || hasLocation)
                    ? UzaColors.secondary.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialActionsRow(Shop shop, ContactService contactService) {
    final contactPhone = PhoneUtils.shopWhatsAppNumber(
      whatsapp: shop.whatsapp,
      phone: shop.phone,
    );
    final hasWhatsApp = contactPhone != null;
    final hasFacebook = shop.facebookUrl?.trim().isNotEmpty == true;
    final hasTiktok = shop.tiktokUrl?.trim().isNotEmpty == true;

    if (!hasWhatsApp && !hasFacebook && !hasTiktok) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    void addSocial({
      required bool visible,
      required String label,
      required Widget icon,
      required Color color,
      required VoidCallback onTap,
      bool filled = false,
    }) {
      if (!visible) return;
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: _QuickActionButton(
            label: label,
            icon: icon,
            color: color,
            filled: filled,
            onTap: onTap,
          ),
        ),
      );
    }

    addSocial(
      visible: hasWhatsApp,
      label: 'WhatsApp',
      icon: const FaIcon(FontAwesomeIcons.whatsapp),
      color: const Color(0xFF25D366),
      filled: true,
      onTap: () => ContactSellerSheet.show(context, shop: shop),
    );
    addSocial(
      visible: hasFacebook,
      label: 'Facebook',
      icon: const FaIcon(FontAwesomeIcons.facebook),
      color: const Color(0xFF1877F2),
      onTap: () => contactService.launchSocial(
        urlString: shop.facebookUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );
    addSocial(
      visible: hasTiktok,
      label: 'TikTok',
      icon: const FaIcon(FontAwesomeIcons.tiktok),
      color: UzaColors.onSurface(context),
      onTap: () => contactService.launchSocial(
        urlString: shop.tiktokUrl!,
        entityType: 'shop',
        entityId: shop.id,
      ),
    );

    return Row(children: children);
  }

  Widget _buildSocialAndFollowRow(Shop shop, ContactService contactService) {
    final hasSocial = shop.whatsapp?.trim().isNotEmpty == true ||
        shop.phone?.trim().isNotEmpty == true ||
        shop.facebookUrl?.trim().isNotEmpty == true ||
        shop.tiktokUrl?.trim().isNotEmpty == true;
    final follow = _buildFollowButton(context, shop, compact: true);

    if (!hasSocial) {
      return Align(alignment: Alignment.center, child: follow);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildSocialActionsRow(shop, contactService)),
        const SizedBox(width: 8),
        follow,
      ],
    );
  }

  Widget _buildProfileHeader(
    Shop shop,
    ContactService contactService,
    ProductRepository productRepo, {
    required bool isWide,
    required Color mutedText,
  }) {
    final coverSource = _getCoverImageSource(shop);
    final coverHeight = isWide ? 200.0 : 160.0;
    final logoSize = isWide ? 108.0 : 92.0;
    final logoOverlap = logoSize / 2;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(UzaColors.radiusLg),
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
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.45),
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
        SizedBox(height: logoOverlap + (isWide ? 16 : 12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildShopInfoSection(
            shop,
            contactService,
            isWide: isWide,
            mutedText: mutedText,
          ),
        ),
        const SizedBox(height: 4),
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

    return Text(shop.name, style: style);
  }

  Widget _buildBody(
    Shop shop,
    ProductRepository productRepo,
    ContactService contactService,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final tabBarBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF0F2F5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final contentWidth = isWide ? 1000.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(
                    shop,
                    contactService,
                    productRepo,
                    isWide: isWide,
                    mutedText: mutedText,
                  ),
                ),
                _buildVideo(context, shop),
                _buildBanner(shop),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ShopTabBarDelegate(
                    backgroundColor: theme.colorScheme.surface,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: tabBarBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: UzaColors.primary,
                        unselectedLabelColor: mutedText,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            height: 42,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 16),
                                SizedBox(width: 6),
                                Text(tr(context, 'products')),
                              ],
                            ),
                          ),
                          Tab(
                            height: 42,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 16),
                                SizedBox(width: 6),
                                Text(tr(context, 'arrivages')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(context, shop, productRepo, constraints),
                  _buildArrivagesTab(context, shop),
                ],
              ),
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
      stream: productRepo.watchProductsForShop(shop),
      builder: (context, snapshot) {
        return AsyncContent<List<Product>>(
          snapshot: snapshot,
          loading: const Center(child: CircularProgressIndicator()),
          isEmpty: (products) => products.isEmpty,
          empty: () => EmptyState(
            icon: Icons.inventory_2_outlined,
            title: tr(context, 'shop_no_products'),
            subtitle: tr(context, 'shop_no_products_hint'),
          ),
          builder: (products) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: constraints.maxWidth > 700 ? 0.75 : 0.86,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
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
        return AsyncContent<List<Story>>(
          snapshot: snapshot,
          loading: const Center(child: CircularProgressIndicator()),
          isEmpty: (arrivages) => arrivages.isEmpty,
          empty: () => EmptyState(
            icon: Icons.auto_stories_outlined,
            title: tr(context, 'shop_no_arrivages'),
            subtitle: tr(context, 'shop_no_arrivages_hint'),
          ),
          builder: (arrivages) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
              key: ValueKey('shop_arrivage_${story.id}'),
              onTap: () => _openArrivage(context, shop, arrivages, index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Media content
                      story.mediaType == 'video' && story.mediaUrl.isNotEmpty
                          ? Container(
                              color: Colors.black,
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 48,
                              ),
                            )
                          : ArrivageThumbnail(
                              story: story,
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
        title: Text(tr(context, 'delete_confirm_title')),
        content: Text(
          story.isArrivage
              ? 'Voulez-vous vraiment supprimer cet arrivage ?'
              : 'Voulez-vous vraiment supprimer cette story ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
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
                  SnackBar(
                    content: Text(tr(context, 'deleted_success')),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(tr(context, 'delete'), style: TextStyle(color: Colors.red)),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: ModernCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          borderRadius: UzaColors.radiusMd,
          hasBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: UzaColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: UzaColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Présentation vidéo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ShopVideoPlayer(videoUrl: videoUrl),
              ),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UzaColors.radiusMd),
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
            final buttonStyle = ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : UzaColors.primary,
              foregroundColor: isFollowing
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
              elevation: isFollowing ? 0 : 2,
              shadowColor: UzaColors.primary.withValues(alpha: 0.35),
              minimumSize: Size(0, _actionButtonHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 0 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isFollowing
                    ? BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.2),
                      )
                    : BorderSide.none,
              ),
            );

            final followButton = ElevatedButton.icon(
              onPressed: () => context
                  .read<ShopRepository>()
                  .toggleFollowShop(shop.id, userPhone: userPhone),
              icon: Icon(
                isFollowing ? Icons.check_rounded : Icons.add_rounded,
                size: compact ? 16 : 14,
              ),
              label: Text(
                isFollowing ? 'Suivi' : 'Suivre',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: buttonStyle,
            );

            if (compact) {
              return followButton;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                followButton,
                if (!compact && followerCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: UzaColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$followerCount',
                      style: const TextStyle(
                        color: UzaColors.secondary,
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
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  final bool enabled;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && onTap != null;
    final fg = filled
        ? Colors.white
        : (isActive ? color : Colors.grey);
    final bg = filled
        ? (isActive ? color : color.withValues(alpha: 0.35))
        : (isActive
            ? color.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: isActive ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(size: 18, color: fg),
                child: icon,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _ShopTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _ShopTabBarDelegate({
    required this.child,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 66;

  @override
  double get maxExtent => 66;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ShopTabBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
