import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/image_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/responsive_layout.dart';
import '../components/seller_activity.dart';
import '../components/tap_animator.dart';
import '../components/verification_badge.dart';
import '../utils/page_transitions.dart';
import 'shop_profile_screen.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  double? _userLat;
  double? _userLng;
  bool _loadingLocation = true;
  String? _locationError;
  List<({Shop shop, double? distanceKm})> _shops = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    final coords = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (coords == null) {
      setState(() {
        _loadingLocation = false;
        _locationError =
            'Activez la localisation pour voir les boutiques à proximité.';
      });
    } else {
      _userLat = coords['latitude'];
      _userLng = coords['longitude'];
      setState(() => _loadingLocation = false);
    }
    await _loadShops();
  }

  Future<void> _loadShops() async {
    final repo = context.read<ShopRepository>();
    final ranked = await repo.getShopsByDistance(
      userLat: _userLat,
      userLng: _userLng,
    );
    if (!mounted) return;
    setState(() => _shops = ranked);
  }

  String _formatDistance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  void _openShop(Shop shop) {
    Navigator.push(
      context,
      SlideUpRoute(page: ShopProfileScreen(shop: shop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: UzaColors.primary,
        onRefresh: _initLocation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeader(context),
            if (_loadingLocation && _shops.isEmpty)
              _buildLoadingSliver(context)
            else if (_locationError != null && _userLat == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LocationPrompt(
                  message: _locationError!,
                  onRetry: _initLocation,
                ),
              )
            else if (_shops.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const _EmptyNearbyState(),
              )
            else ...[
              SliverToBoxAdapter(child: _buildStatsBar(context)),
              _buildShopsSliver(context),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: UzaColors.secondary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.my_location_rounded),
          tooltip: 'Actualiser position',
          onPressed: _loadingLocation ? null : _initLocation,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
        title: const Text(
          'Près de moi',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UzaColors.secondary,
                UzaColors.secondary.withValues(alpha: 0.9),
                UzaColors.primary.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -30,
                top: -10,
                child: Icon(
                  Icons.near_me_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 20,
                child: Icon(
                  Icons.storefront_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final theme = Theme.of(context);
    final count = _shops.length;
    final withDistance = _shops.where((e) => e.distanceKm != null).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: UzaColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: UzaColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: UzaColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: UzaColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count boutique${count > 1 ? 's' : ''} trouvée${count > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    withDistance > 0
                        ? 'Triées par distance'
                        : 'Position non disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
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

  Widget _buildLoadingSliver(BuildContext context) {
    final isGrid = !ResponsiveLayout.isMobile(context);
    final crossAxisCount = ResponsiveLayout.isDesktop(context)
        ? 3
        : (ResponsiveLayout.isTablet(context) ? 2 : 1);

    if (isGrid) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.82,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, _) => const _NearbyShopSkeleton(isGrid: true),
            childCount: 6,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList.separated(
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => const _NearbyShopSkeleton(isGrid: false),
      ),
    );
  }

  Widget _buildShopsSliver(BuildContext context) {
    final isGrid = !ResponsiveLayout.isMobile(context);
    final crossAxisCount = ResponsiveLayout.isDesktop(context)
        ? 3
        : (ResponsiveLayout.isTablet(context) ? 2 : 1);

    if (isGrid) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.82,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = _shops[index];
              return _StaggeredEntrance(
                index: index,
                child: _NearbyShopGridCard(
                  shop: entry.shop,
                  distanceKm: entry.distanceKm,
                  rank: index,
                  formatDistance: _formatDistance,
                  onTap: () => _openShop(entry.shop),
                ),
              );
            },
            childCount: _shops.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: _shops.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _shops[index];
          return _StaggeredEntrance(
            index: index,
            child: _NearbyShopListCard(
              shop: entry.shop,
              distanceKm: entry.distanceKm,
              rank: index,
              formatDistance: _formatDistance,
              onTap: () => _openShop(entry.shop),
            ),
          );
        },
      ),
    );
  }
}

// ── Staggered entrance animation ─────────────────────────────────────────────

class _StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredEntrance({required this.index, required this.child});

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index.clamp(0, 12) * 55), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── List card (mobile) ───────────────────────────────────────────────────────

class _NearbyShopListCard extends StatelessWidget {
  final Shop shop;
  final double? distanceKm;
  final int rank;
  final String Function(double?) formatDistance;
  final VoidCallback onTap;

  const _NearbyShopListCard({
    required this.shop,
    required this.distanceKm,
    required this.rank,
    required this.formatDistance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final hasCoords = shop.latitude != null && shop.longitude != null;
    final location = _formatLocation(shop);

    return TapAnimator(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShopCoverThumb(
                  shop: shop,
                  size: 108,
                  distanceLabel: distanceKm != null
                      ? formatDistance(distanceKm)
                      : null,
                  rank: rank,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            VerificationBadge(
                              isVerified: shop.isVerified,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (location != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (shop.responseTimeMinutes != null) ...[
                          const SizedBox(height: 6),
                          SellerActivityIndicator(
                            responseTimeMinutes: shop.responseTimeMinutes,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _ShopTypeChip(type: shop.type),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hasCoords)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavActionButton(
                        icon: Icons.map_rounded,
                        label: 'Itinéraire',
                        color: UzaColors.secondary,
                        onTap: () => LocationService.getDirections(
                          latitude: shop.latitude!,
                          longitude: shop.longitude!,
                          destinationName: shop.name,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                    Expanded(
                      child: _NavActionButton(
                        icon: Icons.navigation_rounded,
                        label: 'Waze',
                        color: UzaColors.primary,
                        onTap: () => LocationService.openInWaze(
                          latitude: shop.latitude!,
                          longitude: shop.longitude!,
                        ),
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
}

// ── Grid card (tablet / desktop) ─────────────────────────────────────────────

class _NearbyShopGridCard extends StatelessWidget {
  final Shop shop;
  final double? distanceKm;
  final int rank;
  final String Function(double?) formatDistance;
  final VoidCallback onTap;

  const _NearbyShopGridCard({
    required this.shop,
    required this.distanceKm,
    required this.rank,
    required this.formatDistance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final hasCoords = shop.latitude != null && shop.longitude != null;
    final location = _formatLocation(shop);

    return TapAnimator(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ShopCoverImage(shop: shop),
                  if (distanceKm != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _DistanceBadge(label: formatDistance(distanceKm)),
                    ),
                  if (rank < 3 && distanceKm != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _RankBadge(rank: rank + 1),
                    ),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ImageUtils.getLogoWidget(shop.logoUrl, size: 52),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: _ShopTypeChip(type: shop.type),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.2,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        VerificationBadge(
                          isVerified: shop.isVerified,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: muted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontSize: 11, color: muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (hasCoords)
                      Row(
                        children: [
                          Expanded(
                            child: _MiniNavButton(
                              icon: Icons.map_rounded,
                              label: 'Route',
                              onTap: () => LocationService.getDirections(
                                latitude: shop.latitude!,
                                longitude: shop.longitude!,
                                destinationName: shop.name,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MiniNavButton(
                              icon: Icons.navigation_rounded,
                              label: 'Waze',
                              onTap: () => LocationService.openInWaze(
                                latitude: shop.latitude!,
                                longitude: shop.longitude!,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _ShopCoverThumb extends StatelessWidget {
  final Shop shop;
  final double size;
  final String? distanceLabel;
  final int rank;
  final BorderRadius borderRadius;

  const _ShopCoverThumb({
    required this.shop,
    required this.size,
    required this.distanceLabel,
    required this.rank,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: _ShopCoverImage(shop: shop),
          ),
          if (distanceLabel != null)
            Positioned(
              top: 8,
              left: 8,
              child: _DistanceBadge(label: distanceLabel!),
            ),
          if (rank < 3 && distanceLabel != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: _RankBadge(rank: rank + 1),
            ),
        ],
      ),
    );
  }
}

class _ShopCoverImage extends StatelessWidget {
  final Shop shop;

  const _ShopCoverImage({required this.shop});

  @override
  Widget build(BuildContext context) {
    final coverSource = ImageUtils.getShopCoverSource(
      shop.bannerUrl,
      shop.logoUrl,
    );
    if (coverSource != null) {
      return ImageUtils.buildCachedImage(
        coverSource,
        fit: BoxFit.cover,
        errorWidget: _coverFallback(),
      );
    }
    return _coverFallback();
  }

  Widget _coverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UzaColors.primary.withValues(alpha: 0.85),
            UzaColors.secondary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, size: 36, color: Colors.white70),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final String label;

  const _DistanceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: UzaColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: UzaColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = colors[(rank - 1).clamp(0, 2)];

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ShopTypeChip extends StatelessWidget {
  final ShopType type;

  const _ShopTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type == ShopType.wholesale ? 'GROS' : 'DÉTAIL',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: UzaColors.primary,
        ),
      ),
    );
  }
}

class _NavActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapAnimator(
      scaleDown: 0.97,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapAnimator(
      scaleDown: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: UzaColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: UzaColors.secondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: UzaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty & error states ─────────────────────────────────────────────────────

class _LocationPrompt extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LocationPrompt({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UzaColors.secondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_disabled_rounded,
              size: 56,
              color: UzaColors.secondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Localisation requise',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          TapAnimator(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [UzaColors.secondary, UzaColors.primary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: UzaColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Autoriser la localisation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNearbyState extends StatelessWidget {
  const _EmptyNearbyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 52,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune boutique à proximité',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les boutiques géolocalisées apparaîtront ici dès qu\'elles seront disponibles dans votre zone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _NearbyShopSkeleton extends StatelessWidget {
  final bool isGrid;

  const _NearbyShopSkeleton({required this.isGrid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[200]!;
    final highlight = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: isGrid ? null : 108,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isGrid
            ? Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 80, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 120, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 60, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String? _formatLocation(Shop shop) {
  final parts = <String>[];
  if (shop.commune != null && shop.commune!.isNotEmpty) {
    parts.add(shop.commune!);
  }
  if (shop.city != null && shop.city!.isNotEmpty) {
    parts.add(shop.city!);
  }
  return parts.isNotEmpty ? parts.join(', ') : null;
}
