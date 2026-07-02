import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import '../components/product_card.dart';
import '../components/search_delegate.dart';
import '../components/search_filters.dart';
import '../components/staggered_list.dart';
import '../components/custom_refresh_indicator.dart';
import '../../core/l10n/tr.dart';
import '../components/home_discovery_sections.dart';
import '../components/animated_bottom_nav.dart';
import '../components/uza_search_bar.dart';
import '../components/responsive_layout.dart';
import '../components/uza_secondary_app_bar.dart';
import '../../core/router/app_nav_utils.dart';
import 'product_detail_screen.dart';
import 'product_scanner_screen.dart';
import '../../core/res/uza_colors.dart';

class SearchScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;
  final int? initialCategoryId;
  final String? initialCategoryName;
  const SearchScreen({
    super.key,
    this.showAppBar = false,
    this.showBottomNav = true,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late int? _selectedCategoryId;
  late String? _selectedCategoryName;
  late int? _selectedSubcategoryId;
  late String? _selectedSubcategoryName;
  int _refreshKey = 0;
  Position? _userPosition;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _selectedCategoryName = widget.initialCategoryName;
    _selectedSubcategoryId = null;
    _selectedSubcategoryName = null;

    // Initialize filter state with initial category if provided
    if (widget.initialCategoryId != null && widget.initialCategoryId! > 0) {
      _filterState = SearchFilterState(
        categoryId: widget.initialCategoryId,
        category: widget.initialCategoryName,
      );
      _refreshKey++;
    }
  }

  // Filter state from SearchFilters widget
  SearchFilterState _filterState = const SearchFilterState();

  void _onFiltersChanged(SearchFilterState state) {
    setState(() {
      _filterState = state;
      // Sync category from filter if set
      if (state.categoryId != null && state.categoryId! > 0) {
        _selectedCategoryId = state.categoryId;
        _selectedCategoryName = state.category;
        _selectedSubcategoryId = state.subcategoryId;
        _selectedSubcategoryName = state.subcategory;
      } else if (state.category != null) {
        _selectedCategoryName = state.category;
        _selectedCategoryId = null;
        _selectedSubcategoryId = state.subcategoryId;
        _selectedSubcategoryName = state.subcategory;
      }
      // Check if nearest sort is selected
      if (state.sortBy == SortBy.nearest && _userPosition == null) {
        _requestLocation();
      }
      _refreshKey++;
    });
  }

  Future<void> _requestLocation() async {
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(context, 'location_enable'))),
          );
        }
        setState(() {
          _locationLoading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(context, 'location_denied'))),
          );
        }
        setState(() {
          _locationLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'location_error'))),
        );
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  String _sortByToString(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.priceAsc:
        return 'priceAsc';
      case SortBy.priceDesc:
        return 'priceDesc';
      case SortBy.newest:
        return 'newest';
      case SortBy.nearest:
        return 'nearest';
      case SortBy.relevance:
        return 'relevance';
    }
  }

  int _searchGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (ResponsiveLayout.isDesktop(context)) {
      return width >= 1400 ? 5 : 4;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    final content = UzaRefreshIndicator(
      onRefresh: () async {
        await context.read<SyncService>().syncNow();
        if (mounted) {
          setState(() => _refreshKey++);
        }
      },
      child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Search Bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: UzaSearchBar(
                        onTap: () async {
                          showSearch(
                            context: context,
                            delegate: ProductSearchDelegate(productRepo),
                          );
                        },
                        variant: UzaSearchBarVariant.hero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: UzaColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.center_focus_weak,
                          color: UzaColors.primary,
                        ),
                        onPressed: () async {
                          final code = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProductScannerScreen(),
                            ),
                          );
                          if (code != null && context.mounted) {
                            final delegate =
                                ProductSearchDelegate(productRepo);
                            delegate.query = code;
                            await showSearch(
                              context: context,
                              delegate: delegate,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Tes vendeurs & zone (masqué par défaut) ─────────
            const SliverToBoxAdapter(
              child: HomeDiscoverySections(),
            ),

            // ─── Category Chips (scrollable) ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Explorez par catégorie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: StreamBuilder<List<Category>>(
                  stream: productRepo.watchCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildCategorySkeleton();
                    }
                    final categories = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryChip(categories[index]);
                      },
                    );
                  },
                ),
              ),
            ),

            // ─── Search Filters ─────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<Category>>(
                stream: productRepo.watchCategories(),
                builder: (context, snapshot) {
                  final categoryNames =
                      snapshot.data?.map((c) => c.name).toList() ?? [];
                  return SearchFilters(
                    key: ValueKey('filters_$_refreshKey'),
                    categories: categoryNames,
                    onFiltersChanged: _onFiltersChanged,
                    initialState: _filterState,
                  );
                },
              ),
            ),

            // ─── Results ─────────────────────────────────────────
            if (_filterState.sortBy == SortBy.nearest)
              _buildNearbyResultsSliver(productRepo)
            else
              StreamBuilder<List<Product>>(
                key: ValueKey(
                  'search_grid_${_selectedCategoryId}_${_selectedSubcategoryId}_${_filterState.hashCode}_$_refreshKey',
                ),
                stream: productRepo.watchProductsFiltered(
                  categoryId: _selectedSubcategoryId ?? _selectedCategoryId,
                  category: _filterState.category,
                  minPrice: _filterState.minPrice,
                  maxPrice: _filterState.maxPrice,
                  condition: _filterState.condition,
                  sortBy: _sortByToString(_filterState.sortBy),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonSliver();
                  }

                  final hasFilters =
                      _selectedCategoryId != null ||
                      _filterState.hasActiveFilters;

                  // Header
                  final headerSliver = SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hasFilters
                                  ? _selectedCategoryId != null
                                        ? 'En : $_selectedCategoryName'
                                        : 'Resultats filtres'
                                  : 'Suggestions pour vous',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (snapshot.hasData && snapshot.data!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: UzaColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${snapshot.data!.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: UzaColors.primary,
                                ),
                              ),
                            ),
                          if (hasFilters)
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedCategoryId = null;
                                _selectedCategoryName = null;
                                _filterState = const SearchFilterState();
                                _refreshKey++;
                              }),
                              child: Text(tr(context, 'reset_filters')),
                            ),
                        ],
                      ),
                    ),
                  );

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return MultiSliver(
                      slivers: [
                        headerSliver,
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun produit ne correspond a vos criteres.',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final displayItems = snapshot.data!;

                  return MultiSliver(
                    slivers: [
                      headerSliver,
                      _buildProductsGridSliver(displayItems),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
      ),
    );

    return UzaBackScope(
      child: Scaffold(
        extendBody: true,
        appBar: widget.showAppBar
            ? UzaSecondaryAppBar(title: tr(context, 'search_title'))
            : null,
        body: content,
        bottomNavigationBar: widget.showBottomNav
            ? AnimatedBottomNav(
                currentIndex: 0,
                onTap: (index) => AppNavUtils.navigateToTab(context, index),
              )
            : null,
      ),
    );
  }

  // ─── Category Chips ──────────────────────────────────────────────

  Widget _buildCategoryChip(Category category) {
    final isSelected = _selectedCategoryId == category.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category.name),
        selected: isSelected,
        avatar: Icon(
          _getCategoryIcon(category.icon, category.name),
          size: 16,
          color: isSelected ? Colors.white : UzaColors.primary,
        ),
        selectedColor: UzaColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : UzaColors.onSurface(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? UzaColors.primary : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() {
            if (_selectedCategoryId == category.id) {
              _selectedCategoryId = null;
              _selectedCategoryName = null;
            } else {
              _selectedCategoryId = category.id;
              _selectedCategoryName = category.name;
            }
            _refreshKey++;
          });
        },
      ),
    );
  }

  // ─── Products Grid (vertical, like Populaires on home) ───────────

  Widget _buildProductsGridSliver(List<Product> products) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 10 : 16,
        vertical: 8,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1200
              ? 5
              : screenWidth > 700
              ? 4
              : 2,
          childAspectRatio: screenWidth < 360
              ? 0.78
              : (screenWidth > 700 ? 0.75 : 0.86),
          crossAxisSpacing: screenWidth > 700 ? 12 : 16,
          mainAxisSpacing: screenWidth > 700 ? 12 : 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return StaggeredListItem(
            index: index,
            child: ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
            ),
          );
        }, childCount: products.length),
      ),
    );
  }

  // ─── Skeleton Loaders ────────────────────────────────────────────

  Widget _buildCategorySkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 100,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.86,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSkeletonCard(),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Image placeholder
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Text placeholders
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
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

  // ─── Nearby Results Sliver ───────────────────────────────────────

  Widget _buildNearbyResultsSliver(ProductRepository productRepo) {
    if (_locationLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: UzaColors.primary),
              const SizedBox(height: 12),
              Text(
                'Obtention de votre position...',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    if (_userPosition == null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Localisation non disponible',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _requestLocation,
                child: Text(tr(context, 'allow_location')),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: FutureBuilder<List<(Product, double)>>(
        future: productRepo.searchProductsNearbyWithDistance(
          userLat: _userPosition!.latitude,
          userLng: _userPosition!.longitude,
          categoryId: _selectedCategoryId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: UzaColors.primary),
              ),
            );
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucun produit trouve a proximite',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = results.map((r) => r.$1).toList();
          final distances = {for (final r in results) r.$1.id: r.$2};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'A proximite',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: UzaColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${results.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: UzaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _searchGridColumns(context),
                    childAspectRatio:
                        ResponsiveLayout.isDesktop(context) ? 0.72 : 0.76,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return StaggeredListItem(
                      index: index,
                      child: ProductCard(
                        product: product,
                        distanceKm: distances[product.id],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Category Icon Mapping ───────────────────────────────────────

  IconData _getCategoryIcon(String? iconName, String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('électronique') ||
        name.contains('phone') ||
        name.contains('tv')) {
      return Icons.phone_iphone;
    }
    if (name.contains('vêtement') ||
        name.contains('fashion') ||
        name.contains('habit')) {
      return Icons.checkroom;
    }
    if (name.contains('accessoire') ||
        name.contains('sac') ||
        name.contains('bijou')) {
      return Icons.shopping_bag;
    }
    if (name.contains('maison') ||
        name.contains('home') ||
        name.contains('déco')) {
      return Icons.home;
    }
    if (name.contains('aliment') ||
        name.contains('food') ||
        name.contains('resto')) {
      return Icons.fastfood;
    }
    if (name.contains('beauté') || name.contains('cosmétique')) {
      return Icons.face;
    }
    if (name.contains('sport')) {
      return Icons.sports_soccer;
    }

    return Icons.category;
  }
}

// ─── MultiSliver Helper ────────────────────────────────────────────
// Allows returning multiple slivers from a single builder

class MultiSliver extends StatelessWidget {
  final List<Widget> slivers;
  const MultiSliver({super.key, required this.slivers});

  @override
  Widget build(BuildContext context) {
    // We use a SliverMainAxisGroup to group multiple slivers
    // This is available in Flutter 3.7+
    return SliverMainAxisGroup(slivers: slivers);
  }
}
