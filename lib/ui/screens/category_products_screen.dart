import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../components/product_card.dart';
import '../../core/res/uza_colors.dart';
import 'product_detail_screen.dart';
import '../utils/page_transitions.dart';

enum _SortOption { newest, priceAsc, priceDesc, nearest }

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  int? _selectedSubcategoryId;
  int? _selectedSubSubcategoryId;
  _SortOption _sortBy = _SortOption.nearest; // Default to nearest
  Position? _userPosition;
  bool _locationLoading = false;
  List<Category> _subcategories = [];

  @override
  void initState() {
    super.initState();
    // Request location on init since nearest is default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocation();
    });
  }

  int get _activeCategoryId =>
      _selectedSubSubcategoryId ?? _selectedSubcategoryId ?? widget.categoryId;

  // Get all category IDs to include (parent + all subcategories)
  List<int> _getAllCategoryIds() {
    final List<int> ids = [widget.categoryId];
    // Add direct subcategories
    ids.addAll(_subcategories.map((c) => c.id));
    // Sub-subcategories will be added when subcategory is selected
    return ids;
  }

  String _sortLabel(_SortOption sort) {
    switch (sort) {
      case _SortOption.newest:
        return 'Plus recent';
      case _SortOption.priceAsc:
        return 'Prix croissant';
      case _SortOption.priceDesc:
        return 'Prix decroissant';
      case _SortOption.nearest:
        return 'Plus proche';
    }
  }

  String _sortStringForRepo(_SortOption sort) {
    switch (sort) {
      case _SortOption.newest:
        return 'newest';
      case _SortOption.priceAsc:
        return 'priceAsc';
      case _SortOption.priceDesc:
        return 'priceDesc';
      case _SortOption.nearest:
        return 'relevance';
    }
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
                'Activez la localisation pour trier par proximite.',
              ),
            ),
          );
        }
        setState(() {
          _sortBy = _SortOption.newest;
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
          _sortBy = _SortOption.newest;
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
          _sortBy = _SortOption.newest;
          _locationLoading = false;
        });
      }
    }
  }

  void _onSortChanged(_SortOption sort) {
    setState(() => _sortBy = sort);
    if (sort == _SortOption.nearest && _userPosition == null) {
      _requestLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: UzaColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort options
          _buildSortBar(),

          // Subcategory chips
          _buildSubcategoryChips(productRepo),

          // Sub-subcategory chips
          if (_selectedSubcategoryId != null)
            _buildSubSubcategoryChips(productRepo),

          const Divider(height: 1),

          // Product grid
          Expanded(
            child: _sortBy == _SortOption.nearest
                ? _buildNearestResults(productRepo)
                : _buildStreamResults(productRepo),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Trier par',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UzaColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SortOption.values.map((sort) {
                  final isSelected = _sortBy == sort;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_sortLabel(sort)),
                      selected: isSelected,
                      selectedColor: UzaColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: UzaColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? UzaColors.primary : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? UzaColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onSelected: (_) => _onSortChanged(sort),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryChips(ProductRepository productRepo) {
    return StreamBuilder<List<Category>>(
      stream: productRepo.watchCategoriesByParent(widget.categoryId),
      builder: (context, snapshot) {
        final subcategories = snapshot.data ?? [];

        // Store subcategories for later use
        if (_subcategories != subcategories) {
          _subcategories = subcategories;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Filtrer par sous-catégorie:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "Tout" chip to show all products
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Tout'),
                      selected: _selectedSubcategoryId == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSubcategoryId = null;
                            _selectedSubSubcategoryId = null;
                          });
                        }
                      },
                      selectedColor: UzaColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: UzaColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedSubcategoryId == null
                            ? UzaColors.primary
                            : Colors.black87,
                        fontWeight: _selectedSubcategoryId == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedSubcategoryId == null
                              ? UzaColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final cat = subcategories[index];
                  final isSelected = _selectedSubcategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubcategoryId = cat.id;
                            _selectedSubSubcategoryId = null;
                          } else {
                            _selectedSubcategoryId = null;
                            _selectedSubSubcategoryId = null;
                          }
                        });
                      },
                      selectedColor: UzaColors.secondary.withValues(
                        alpha: 0.15,
                      ),
                      checkmarkColor: UzaColors.secondary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? UzaColors.secondary
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? UzaColors.secondary
                              : Colors.grey[300]!,
                        ),
                      ),
                      backgroundColor: Colors.white,
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

  Widget _buildSubSubcategoryChips(ProductRepository productRepo) {
    return StreamBuilder<List<Category>>(
      stream: productRepo.watchCategoriesByParent(_selectedSubcategoryId),
      builder: (context, snapshot) {
        final subSubcategories = snapshot.data ?? [];
        if (subSubcategories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'Sous-catégories:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subSubcategories.length,
                itemBuilder: (context, index) {
                  final cat = subSubcategories[index];
                  final isSelected = _selectedSubSubcategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubSubcategoryId = selected ? cat.id : null;
                        });
                      },
                      selectedColor: UzaColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: UzaColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? UzaColors.primary : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? UzaColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      backgroundColor: Colors.white,
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

  Widget _buildStreamResults(ProductRepository productRepo) {
    // When viewing a parent category with no subcategory selected,
    // show products from the parent AND all its subcategories
    return StreamBuilder<List<Product>>(
      stream: _buildCategoryProductStream(productRepo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: UzaColors.primary),
          );
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return _buildProductGrid(products);
      },
    );
  }

  Stream<List<Product>> _buildCategoryProductStream(
    ProductRepository productRepo,
  ) {
    // If a specific subcategory or sub-subcategory is selected, only show its products
    if (_selectedSubcategoryId != null || _selectedSubSubcategoryId != null) {
      return productRepo.watchProductsFiltered(
        categoryId: _activeCategoryId,
        sortBy: _sortStringForRepo(_sortBy),
      );
    }

    // Otherwise, show products from parent category AND all its subcategories
    // For simplicity, we'll use a Future-based approach
    // This will rebuild when subcategories change
    return _watchProductsFromCategoryAndSubcategories(
      productRepo,
      widget.categoryId,
      _subcategories,
    );
  }

  Stream<List<Product>> _watchProductsFromCategoryAndSubcategories(
    ProductRepository productRepo,
    int parentCategoryId,
    List<Category> subcategories,
  ) {
    // Create a stream controller that will emit merged results
    final controller = StreamController<List<Product>>();

    // Get all streams
    final streams = <Stream<List<Product>>>[
      productRepo.watchProductsFiltered(
        categoryId: parentCategoryId,
        sortBy: _sortStringForRepo(_sortBy),
      ),
      ...subcategories.map(
        (cat) => productRepo.watchProductsFiltered(
          categoryId: cat.id,
          sortBy: _sortStringForRepo(_sortBy),
        ),
      ),
    ];

    // Subscribe to all streams and merge results
    final subscriptions = <StreamSubscription<List<Product>>>[];
    final allProductsMap = <int, Product>{};

    for (var i = 0; i < streams.length; i++) {
      subscriptions.add(
        streams[i].listen((products) {
          // Update products map
          for (final product in products) {
            allProductsMap[product.id] = product;
          }

          // Emit merged results
          if (!controller.isClosed) {
            controller.add(allProductsMap.values.toList());
          }
        }),
      );
    }

    // Clean up on done
    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  Widget _buildNearestResults(ProductRepository productRepo) {
    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: UzaColors.primary),
            SizedBox(height: 12),
            Text(
              'Obtention de votre position...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_userPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Localisation non disponible',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _requestLocation,
              child: const Text('Autoriser la localisation'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<(Product, double)>>(
      future: productRepo.searchProductsNearbyWithDistance(
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
        categoryId: _activeCategoryId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: UzaColors.primary),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return _buildEmptyState();
        }

        final products = results.map((r) => r.$1).toList();
        final distances = {for (final r in results) r.$1.id: r.$2};

        return _buildProductGrid(products, distances: distances);
      },
    );
  }

  Widget _buildProductGrid(
    List<Product> products, {
    Map<int, double>? distances,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: screenWidth < 360 ? 0.78 : 0.86,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final distance = distances?[product.id];
        return ProductCard(
          product: product,
          distanceKm: distance,
          onTap: () => Navigator.push(
            context,
            SlideUpRoute(page: ProductDetailScreen(product: product)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Aucun produit trouve',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Essayez une autre categorie ou sous-categorie',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
