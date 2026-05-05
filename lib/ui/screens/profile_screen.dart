import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/res/uza_colors.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import 'shop_dashboard_screen.dart';
import 'create_shop_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'auth/login_screen.dart';
import 'admin_validation_screen.dart';
import '../components/responsive_layout.dart';
import '../components/modern_card.dart';
import '../components/tap_animator.dart';
import '../utils/page_transitions.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/recently_viewed_repository.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'create_story_screen.dart';
import 'shop_profile_screen.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/l10n/tr.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasReconnectedShops = false;
  Uint8List? _avatarBytes;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  late RecentlyViewedRepository _recentlyViewed;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _recentlyViewed = RecentlyViewedRepository();
    _recentlyViewed.load();
    _authService = context.read<AuthService>();
    _authService.addListener(_onAuthChanged);
    _loadUserData();
  }

  void _onAuthChanged() {
    final user = _authService.user;
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      });
    }
  }

  Future<void> _loadUserData() async {
    // Prefer AuthService (reactive source of truth)
    final authService = _authService;
    if (authService.user != null) {
      _nameController.text = authService.user!.displayName ?? '';
      _phoneController.text = authService.user!.phoneNumber ?? '';
    }

    // Always load latest avatar (and fallback name/phone) from repository
    final profile = await context.read<AuthRepository>().getCurrentUser();
    if (profile != null && mounted) {
      setState(() {
        if (authService.user == null) {
          _nameController.text = profile.name ?? '';
          _phoneController.text = profile.phone;
        }
        _avatarUrl = profile.avatarUrl;
      });
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _recentlyViewed.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await context.read<AuthRepository>().updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
    );
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(tr(context, 'profile_updated')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(authService),
        desktop: _buildDesktopLayout(authService),
      ),
    );
  }

  // ─── Desktop Layout ──────────────────────────────────────────────

  Widget _buildDesktopLayout(AuthService authService) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildGradientHeader(authService),
                const SizedBox(height: 24),
                _buildContentForUser(authService),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mobile Layout ───────────────────────────────────────────────

  Widget _buildMobileLayout(AuthService authService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradientHeader(authService),
          Transform.translate(
            offset: const Offset(0, -24),
            child: _buildContentForUser(authService),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Gradient Header ─────────────────────────────────────────────

  Widget _buildGradientHeader(AuthService authService) {
    final user = authService.user;
    final displayName = user?.displayName ?? _nameController.text;
    final phoneNumber = user?.phoneNumber ?? _phoneController.text;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UzaColors.primary, Color(0xFFD84315)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 48,
      ),
      child: Column(
        children: [
          // Top row: back + edit/save
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.showAppBar
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                    )
                  : const SizedBox(width: 48),
              if (_isEditing && user != null)
                TextButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text(
                    _isSaving ? tr(context, 'saving') : tr(context, 'save'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (user != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          // Avatar with camera overlay
          GestureDetector(
            onTap: (_isEditing && user != null && !_isUploadingAvatar)
                ? _showImageSourceSheet
                : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: _isUploadingAvatar
                      ? null
                      : (_avatarBytes != null
                            ? MemoryImage(_avatarBytes!)
                            : (_avatarUrl != null
                                  ? CachedNetworkImageProvider(_avatarUrl!)
                                  : (user?.photoURL != null
                                        ? CachedNetworkImageProvider(
                                            user!.photoURL!,
                                          )
                                        : null))),
                  child: _isUploadingAvatar
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : (_avatarBytes == null &&
                                _avatarUrl == null &&
                                user?.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              )
                            : null),
                ),
                if (_isEditing && user != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: UzaColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Name (editable or display)
          if (_isEditing && user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _nameController,
                enabled: !_isSaving,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: tr(context, 'full_name'),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Text(
              displayName.isEmpty
                  ? (user == null
                        ? tr(context, 'not_connected')
                        : tr(context, 'user'))
                  : displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          // Phone (editable or display)
          if (_isEditing && user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _phoneController,
                enabled: false,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: tr(context, 'phone_number'),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              phoneNumber,
              style: TextStyle(
                color: phoneNumber.isEmpty
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Content Sections ────────────────────────────────────────────

  Widget _buildContentForUser(AuthService authService) {
    final user = authService.firebaseUser;
    if (user == null) return _buildLoggedOutContent();

    if (!_hasReconnectedShops) {
      _hasReconnectedShops = true;
      context.read<ShopRepository>().reconnectShopsForUser(user.uid);
    }

    return StreamBuilder<Shop?>(
      stream: context.read<ShopRepository>().watchUserShop(user.uid),
      builder: (context, snapshot) {
        final hasShop = snapshot.hasData && snapshot.data != null;
        final shop = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(shop),
            const SizedBox(height: 20),
            if (hasShop) ...[
              _buildSectionTitle(tr(context, 'my_shops')),
              _buildShopCard(shop!),
              const SizedBox(height: 12),
              _buildSellerQuickActions(shop),
              const SizedBox(height: 12),
              _buildSectionTitle(tr(context, 'my_products')),
              _buildMyProducts(shop),
              const SizedBox(height: 16),
            ] else ...[
              _buildCreateShopCTA(),
              const SizedBox(height: 16),
              _buildFollowedShops(),
              const SizedBox(height: 16),
              _buildRecentlyViewed(),
              const SizedBox(height: 16),
              _buildWishlist(),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle(tr(context, 'settings')),
            _buildSettingsSection(authService),
            const SizedBox(height: 16),
            _buildSectionTitle(tr(context, 'account')),
            _buildAccountSection(authService),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ─── Stats Row ───────────────────────────────────────────────────

  Widget _buildStatsRow(Shop? shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCardWidget(
              icon: Icons.inventory_2_outlined,
              label: tr(context, 'products'),
              valueWidget: shop != null
                  ? StreamBuilder<List<Product>>(
                      stream: context
                          .read<ProductRepository>()
                          .watchProductsByShop(shop.id),
                      builder: (context, snap) => Text(
                        '${snap.data?.length ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : const Text(
                      '0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCardWidget(
              icon: Icons.store_outlined,
              label: tr(context, 'shops'),
              valueWidget: Text(
                shop != null ? '1' : '0',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCardWidget(
              icon: Icons.visibility_outlined,
              label: tr(context, 'views'),
              valueWidget: shop != null
                  ? FutureBuilder<Map<String, int>>(
                      future: context.read<ShopRepository>().getShopStats(
                        shop.id,
                      ),
                      builder: (context, snap) => Text(
                        '${snap.data?['product_view_global'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCardWidget({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
      child: Column(
        children: [
          Icon(icon, color: UzaColors.primary, size: 20),
          const SizedBox(height: 6),
          valueWidget,
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ─── Section Title ───────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: UzaColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Shop Card (Mes Boutiques) ──────────────────────────────────

  Widget _buildShopCard(Shop shop) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () => Navigator.push(
        context,
        SlideUpRoute(page: const ShopDashboardScreen()),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: UzaColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.store, color: UzaColors.primary),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                shop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (shop.isVerified) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 16, color: UzaColors.secondary),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // ─── Seller Quick Actions ────────────────────────────────────────

  Widget _buildSellerQuickActions(Shop shop) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: TapAnimator(
              onTap: () => Navigator.push(
                context,
                SlideUpRoute(page: EditProductScreen(shopId: shop.id)),
              ),
              child: _quickActionChip(
                icon: Icons.add_circle_outline,
                label: tr(context, 'add_product'),
                color: UzaColors.primary,
              ),
            ),
          ),
          Expanded(
            child: TapAnimator(
              onTap: () => Navigator.push(
                context,
                SlideUpRoute(page: CreateStoryScreen(shopId: shop.id)),
              ),
              child: _quickActionChip(
                icon: Icons.auto_awesome,
                label: tr(context, 'create_story'),
                color: Colors.purple,
              ),
            ),
          ),
          Expanded(
            child: TapAnimator(
              onTap: () => Navigator.push(
                context,
                SlideUpRoute(page: const ShopDashboardScreen()),
              ),
              child: _quickActionChip(
                icon: Icons.storefront_outlined,
                label: tr(context, 'view_my_shop'),
                color: UzaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ─── My Products (Seller) ───────────────────────────────────────

  Widget _buildMyProducts(Shop shop) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: StreamBuilder<List<Product>>(
        stream: context.read<ProductRepository>().watchProductsByShop(shop.id),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  tr(context, 'no_products_yet'),
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            );
          }
          final display = products.take(4).toList();
          return SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: display.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = display[index];
                return TapAnimator(
                  onTap: () => Navigator.push(
                    context,
                    SlideUpRoute(page: ProductDetailScreen(product: p)),
                  ),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                              size: 28,
                            ),
                          ),
                        ),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${p.viewsCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ─── Create Shop CTA (Buyer) ────────────────────────────────────

  Widget _buildCreateShopCTA() {
    return ModernCard(
      backgroundColor: UzaColors.secondary.withValues(alpha: 0.08),
      hasBorder: true,
      padding: const EdgeInsets.all(20),
      onTap: () =>
          Navigator.push(context, SlideUpRoute(page: const CreateShopScreen())),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: UzaColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront,
              color: UzaColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'create_shop'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: UzaColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'sell_on_uzaapp'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: UzaColors.secondary),
        ],
      ),
    );
  }

  // ─── Followed Shops ─────────────────────────────────────────────

  Widget _buildFollowedShops() {
    return StreamBuilder<List<Shop>>(
      stream: context.read<ShopRepository>().watchFollowedShops(),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, 'followed_sellers'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return TapAnimator(
                    onTap: () => Navigator.push(
                      context,
                      SlideUpRoute(page: ShopProfileScreen(shop: shop)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: UzaColors.secondary.withValues(alpha: 0.1),
                            border: shop.isVerified
                                ? Border.all(
                                    color: UzaColors.secondary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.store,
                            color: UzaColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            shop.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Recently Viewed (Buyer) ────────────────────────────────────

  Widget _buildRecentlyViewed() {
    return AnimatedBuilder(
      animation: _recentlyViewed,
      builder: (context, _) {
        final items = _recentlyViewed.items;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, 'history'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return TapAnimator(
                    onTap: () {
                      if (item.type == 'product') {
                        context
                            .read<ProductRepository>()
                            .getProductById(int.parse(item.id))
                            .then((product) {
                              if (product != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  SlideUpRoute(
                                    page: ProductDetailScreen(product: product),
                                  ),
                                );
                              }
                            });
                      }
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (item.price != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.price!,
                              style: TextStyle(
                                fontSize: 11,
                                color: UzaColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Wishlist (Buyer) ───────────────────────────────────────────

  Widget _buildWishlist() {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductRepository>().watchWishlistProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'my_list'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${products.length} produit${products.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: UzaColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return TapAnimator(
                    onTap: () => Navigator.push(
                      context,
                      SlideUpRoute(page: ProductDetailScreen(product: p)),
                    ),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.price ?? ''} CDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: UzaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Settings Section (Paramètres) ──────────────────────────────

  Widget _buildSettingsSection(AuthService authService) {
    final settings = context.watch<SettingsService>();
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Dark mode
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: Colors.indigo),
            title: Text(
              tr(context, 'dark_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(val),
            activeThumbColor: UzaColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Lite mode
          SwitchListTile(
            secondary: Icon(Icons.bolt_outlined, color: UzaColors.primary),
            title: Text(
              tr(context, 'lite_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              settings.isLiteMode
                  ? tr(context, 'enabled')
                  : tr(context, 'disabled'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: settings.isLiteMode,
            onChanged: (val) => settings.toggleLiteMode(val),
            activeThumbColor: UzaColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Language
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: Colors.grey[700]),
              title: Text(
                tr(context, 'language'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.currentLanguage.toUpperCase(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Notifications
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: Colors.amber[700],
            ),
            title: Text(
              tr(context, 'notifications'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: settings.notificationsEnabled,
            onChanged: (val) => settings.toggleNotifications(val),
            activeThumbColor: UzaColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Biometric
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            child: ListTile(
              leading: Icon(Icons.fingerprint, color: Colors.grey[700]),
              title: Text(
                tr(context, 'biometric_lock'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.biometricEnabled
                        ? tr(context, 'enabled_f')
                        : tr(context, 'disabled_f'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          // Admin section (conditional)
          if (authService.firebaseUser != null) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            TapAnimator(
              onTap: () => Navigator.push(
                context,
                SlideUpRoute(page: const AdminValidationScreen()),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                title: Text(
                  tr(context, 'promo_validation'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Account Section (Compte) ───────────────────────────────────

  Widget _buildAccountSection(AuthService authService) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          TapAnimator(
            onTap: () =>
                Navigator.push(context, SlideUpRoute(page: const HelpScreen())),
            child: ListTile(
              leading: Icon(
                Icons.help_outline_rounded,
                color: Colors.blue[700],
              ),
              title: Text(
                tr(context, 'help'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () {
              const message =
                  "Découvrez UzaApp - Le catalogue de produits #1 en RDC!\n\n"
                  "Téléchargez l'application: https://uzaapp.com\n\n"
                  "Envoyé depuis UzaApp";
              Share.share(message, subject: 'Téléchargez UzaApp');
            },
            child: ListTile(
              leading: Icon(Icons.share, color: Colors.green[700]),
              title: Text(
                tr(context, 'invite_friends'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(
                tr(context, 'logout'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.red[300],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar Image Picker ───────────────────────────────────────

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr(context, 'gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr(context, 'camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) {
      await _pickAvatarImage(source);
    }
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null || !mounted) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _avatarBytes = bytes;
      _isUploadingAvatar = true;
    });

    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final apiService = context.read<ApiService>();
      final uploadedUrl = await apiService.uploadFile(bytes, fileName);

      if (uploadedUrl != null && mounted) {
        await context.read<AuthRepository>().updateProfile(
          avatarUrl: uploadedUrl,
        );
        setState(() {
          _avatarUrl = uploadedUrl;
          _avatarBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'upload_error')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  // ─── Logged Out Content ─────────────────────────────────────────

  Widget _buildLoggedOutContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            tr(context, 'login_prompt'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UzaColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(tr(context, 'login')),
            ),
          ),
        ],
      ),
    );
  }
}
