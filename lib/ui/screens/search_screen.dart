import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../components/product_card.dart';
import '../components/search_delegate.dart';
import '../components/search_filters.dart';
import '../components/staggered_list.dart';
import '../../core/res/uza_colors.dart';
import 'product_detail_screen.dart';
import 'product_scanner_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool showAppBar;
  final int? initialCategoryId;
  final String? initialCategoryName;
  const SearchScreen({
    super.key,
    this.showAppBar = false,
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
            const SnackBar(
              content: Text(
                'Activez la localisation pour utiliser cette fonction.',
              ),
            ),
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
            const SnackBar(
              content: Text('Permission de localisation refusee.'),
            ),
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
          const SnackBar(content: Text('Erreur de localisation.')),
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

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: CustomScrollView(
          slivers: [
            // ─── Search Bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          showSearch(
                            context: context,
                            delegate: ProductSearchDelegate(productRepo),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: UzaColors.textSecondary,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Rechercher...',
                                style: TextStyle(
                                  color: UzaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductScannerScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                              child: const Text('Reinitialiser'),
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

                  // When no filters active, show trending + recently added sections
                  if (!hasFilters) {
                    return MultiSliver(
                      slivers: [
                        headerSliver,
                        _buildTrendingSection(productRepo),
                        _buildRecentlyAddedSection(displayItems),
                      ],
                    );
                  }

                  // Filtered results grid with staggered animation
                  return MultiSliver(
                    slivers: [
                      headerSliver,
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 1200
                                    ? 5
                                    : MediaQuery.of(context).size.width > 800
                                    ? 3
                                    : 2,
                                childAspectRatio:
                                    MediaQuery.of(context).size.width > 700
                                    ? 0.75
                                    : 0.86,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = displayItems[index];
                            return StaggeredListItem(
                              index: index,
                              child: ProductCard(
                                product: product,
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
                          }, childCount: displayItems.length),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('RECHERCHE')),
        body: content,
      );
    }
    return content;
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
          color: isSelected ? Colors.white : UzaColors.textPrimary,
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

  // ─── Trending Section ────────────────────────────────────────────

  Widget _buildTrendingSection(ProductRepository productRepo) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: UzaColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: UzaColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tendances',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<Product>>(
              stream: productRepo.watchTrendingProducts(limit: 8),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildHorizontalSkeleton();
                }
                final products = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: StaggeredListItem(
                        index: index,
                        child: ProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
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
      ),
    );
  }

  // ─── Recently Added Section ──────────────────────────────────────

  Widget _buildRecentlyAddedSection(List<Product> products) {
    // Take up to 8 recently added
    final recent = products.take(8).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: UzaColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: UzaColors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Récemment ajoutés',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final product = recent[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: StaggeredListItem(
                    index: index,
                    child: ProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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

  Widget _buildHorizontalSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
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
                child: const Text('Autoriser la localisation'),
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
          final screenWidth = MediaQuery.of(context).size.width;

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
                    crossAxisCount: screenWidth > 1200
                        ? 5
                        : screenWidth > 800
                        ? 3
                        : 2,
                    childAspectRatio: screenWidth > 700 ? 0.75 : 0.86,
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
