import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/services/location_service.dart';
import '../../core/l10n/tr.dart';
import '../components/verification_badge.dart';
import '../components/responsive_layout.dart';
import '../components/skeletons.dart';
import '../utils/page_transitions.dart';
import 'shop_profile_screen.dart';
import 'nearby_shops_screen.dart';

enum _ShopFilter { all, verified, unverified }

class ShopsDirectoryScreen extends StatefulWidget {
  const ShopsDirectoryScreen({super.key});

  @override
  State<ShopsDirectoryScreen> createState() => _ShopsDirectoryScreenState();
}

class _ShopsDirectoryScreenState extends State<ShopsDirectoryScreen> {
  _ShopFilter _filter = _ShopFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedCommune;
  bool _showFilters = false;
  bool _requestedGuestSync = false;

  bool get _hasActiveFilters =>
      _filter != _ShopFilter.all ||
      _selectedCity != null ||
      _selectedCommune != null;

  void _maybeBootstrapSync(List<Shop> shops, SyncService syncService) {
    if (_requestedGuestSync) return;
    if (shops.isNotEmpty) return;
    if (!syncService.isOnline || syncService.isSyncing) return;
    _requestedGuestSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncService.syncNow();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.watch<ShopRepository>();
    final syncService = context.watch<SyncService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final crossAxisCount = ResponsiveLayout.isDesktop(context)
        ? 4
        : (ResponsiveLayout.isTablet(context) ? 3 : 2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncNow();
        },
        child: Column(
          children: [
            // Search bar + filter toggle
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase().trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: tr(context, 'search_shop_hint'),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Près de moi',
                    onPressed: () => Navigator.push(
                      context,
                      SlideUpRoute(page: const NearbyShopsScreen()),
                    ),
                    icon: Icon(
                      Icons.near_me,
                      color: UzaColors.secondary,
                    ),
                  ),
                  _buildFilterToggleButton(theme, isDark),
                ],
              ),
            ),
            if (_showFilters) ...[
              // Filter chips (certification)
              Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      tr(context, 'all_shops'),
                      _ShopFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      tr(context, 'verified_shops'),
                      _ShopFilter.verified,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      tr(context, 'unverified_shops'),
                      _ShopFilter.unverified,
                    ),
                  ],
                ),
              ),
              // Geo filter chips (ville / commune)
              StreamBuilder<List<Shop>>(
                stream: shopRepo.watchAllShops(),
                builder: (context, snapshot) {
                  final allShops = snapshot.data ?? [];
                  final cities = allShops
                      .map((s) => s.city)
                      .where((c) => c != null && c!.isNotEmpty)
                      .map((c) => c!)
                      .toSet()
                      .toList()
                    ..sort();
                  final communes = allShops
                      .where((s) =>
                          _selectedCity == null ||
                          s.city == _selectedCity)
                      .map((s) => s.commune)
                      .where((c) => c != null && c!.isNotEmpty)
                      .map((c) => c!)
                      .toSet()
                      .toList()
                    ..sort();
                  if (cities.isEmpty && communes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cities.isNotEmpty)
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildGeoChip(
                                  'Toutes villes',
                                  _selectedCity == null,
                                  () {
                                    setState(() {
                                      _selectedCity = null;
                                      _selectedCommune = null;
                                    });
                                  },
                                ),
                                ...cities.map((city) => _buildGeoChip(
                                  city,
                                  _selectedCity == city,
                                  () => setState(() {
                                    _selectedCity = city;
                                    _selectedCommune = null;
                                  }),
                                )),
                              ],
                            ),
                          ),
                        if (communes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildGeoChip(
                                  'Toutes communes',
                                  _selectedCommune == null,
                                  () {
                                    setState(() => _selectedCommune = null);
                                  },
                                ),
                                ...communes.map((commune) => _buildGeoChip(
                                  commune,
                                  _selectedCommune == commune,
                                  () => setState(
                                    () => _selectedCommune = commune,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            const Divider(height: 1),
            // Shop grid
            Expanded(
              child: StreamBuilder<List<Shop>>(
                stream: shopRepo.watchAllShops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) => const ShopCardSkeleton(),
                    );
                  }

                  final allShops = snapshot.data ?? [];
                  _maybeBootstrapSync(allShops, syncService);
                  final filteredByType = _applyFilter(allShops);
                  final filteredByGeo = _applyGeoFilter(filteredByType);
                  final shops = _applySearch(filteredByGeo);

                  if (shops.isEmpty) {
                    return _buildEmptyState(
                      allShops.isEmpty,
                      _searchQuery.isNotEmpty,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      return _ShopDirectoryCard(shop: shops[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToggleButton(ThemeData theme, bool isDark) {
    final isActive = _showFilters || _hasActiveFilters;
    return Material(
      color: isActive
          ? UzaColors.primary.withValues(alpha: 0.12)
          : (isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.grey[100]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _showFilters = !_showFilters),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: isActive ? UzaColors.primary : theme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
              if (_hasActiveFilters && !_showFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: UzaColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeoChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: UzaColors.primary.withValues(alpha: 0.15),
        checkmarkColor: UzaColors.primary,
      ),
    );
  }

  List<Shop> _applyGeoFilter(List<Shop> shops) {
    return shops.where((shop) {
      if (_selectedCity != null &&
          (shop.city ?? '').toLowerCase() != _selectedCity!.toLowerCase()) {
        return false;
      }
      if (_selectedCommune != null &&
          (shop.commune ?? '').toLowerCase() != _selectedCommune!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    _ShopFilter filter,
  ) {
    final isSelected = _filter == filter;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? UzaColors.primary
                : (isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Shop> _applyFilter(List<Shop> shops) {
    switch (_filter) {
      case _ShopFilter.verified:
        return shops.where((s) => s.isVerified).toList();
      case _ShopFilter.unverified:
        return shops.where((s) => !s.isVerified).toList();
      case _ShopFilter.all:
        return shops;
    }
  }

  List<Shop> _applySearch(List<Shop> shops) {
    if (_searchQuery.isEmpty) {
      return shops;
    }

    return shops.where((shop) {
      final name = shop.name.toLowerCase();
      final description = (shop.description ?? '').toLowerCase();
      final location = _getSearchableLocation(shop).toLowerCase();

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }

  String _getSearchableLocation(Shop shop) {
    final parts = <String>[];
    if (shop.city != null && shop.city!.isNotEmpty) {
      parts.add(shop.city!);
    }
    if (shop.commune != null && shop.commune!.isNotEmpty) {
      parts.add(shop.commune!);
    }
    if (shop.address != null && shop.address!.isNotEmpty) {
      parts.add(shop.address!);
    }
    return parts.join(' ');
  }

  Widget _buildEmptyState(bool trulyEmpty, bool isSearch) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
        final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.45);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSearch ? Icons.search_off : Icons.storefront_outlined,
                      size: 64,
                      color: subtle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSearch
                          ? 'Aucune boutique trouvée'
                          : trulyEmpty
                          ? tr(context, 'no_shops_directory')
                          : tr(context, 'no_shops_filter'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSearch
                          ? 'Essayez avec d\'autres termes de recherche'
                          : trulyEmpty
                          ? tr(context, 'sync_shops_hint')
                          : tr(context, 'try_other_filter'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: subtle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShopDirectoryCard extends StatelessWidget {
  final Shop shop;

  const _ShopDirectoryCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final location = _formatLocation();
    final hasCoordinates = shop.latitude != null && shop.longitude != null;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SlideUpRoute(page: ShopProfileScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildShopCover(),
                    ),
                  ),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ImageUtils.getLogoWidget(shop.logoUrl, size: 52),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shop.type == ShopType.wholesale ? 'GROS' : 'DÉTAIL',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: UzaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Itinerary button (if coordinates exist)
                  if (hasCoordinates)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: UzaColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            LocationService.getDirections(
                              latitude: shop.latitude!,
                              longitude: shop.longitude!,
                              destinationName: shop.name,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Adresse',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
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
                              style: TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (location == null)
                      Text(
                        shop.description ?? 'Boutique locale',
                        style: TextStyle(fontSize: 11, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildShopCover() {
    final coverSource = ImageUtils.getShopCoverSource(
      shop.bannerUrl,
      shop.logoUrl,
    );
    if (coverSource != null) {
      return ImageUtils.buildCachedImage(
        coverSource,
        fit: BoxFit.cover,
        errorWidget: _shopCoverFallback(),
      );
    }
    return _shopCoverFallback();
  }

  Widget _shopCoverFallback() {
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
        child: Icon(Icons.storefront, size: 40, color: Colors.white70),
      ),
    );
  }

  String? _formatLocation() {
    final parts = <String>[];
    if (shop.city != null && shop.city!.isNotEmpty) {
      parts.add(shop.city!);
    }
    if (shop.commune != null && shop.commune!.isNotEmpty) {
      parts.add(shop.commune!);
    }
    if (shop.address != null && shop.address!.isNotEmpty && parts.isEmpty) {
      parts.add(shop.address!);
    }
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
