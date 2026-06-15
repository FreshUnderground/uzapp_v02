import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import 'package:provider/provider.dart';

enum SortBy { relevance, priceAsc, priceDesc, newest, nearest }

class SearchFilterState {
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final int? categoryId;
  final String? subcategory;
  final int? subcategoryId;
  final String? condition;
  final SortBy sortBy;

  const SearchFilterState({
    this.minPrice,
    this.maxPrice,
    this.category,
    this.categoryId,
    this.subcategory,
    this.subcategoryId,
    this.condition,
    this.sortBy = SortBy.relevance,
  });

  SearchFilterState copyWith({
    double? minPrice,
    double? maxPrice,
    String? category,
    int? categoryId,
    String? subcategory,
    int? subcategoryId,
    String? condition,
    SortBy? sortBy,
  }) {
    return SearchFilterState(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      condition: condition ?? this.condition,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      category != null ||
      subcategory != null ||
      condition != null ||
      sortBy != SortBy.relevance;
}

class SearchFilters extends StatefulWidget {
  final List<String> categories;
  final Function(SearchFilterState) onFiltersChanged;
  final SearchFilterState initialState;

  const SearchFilters({
    super.key,
    required this.categories,
    required this.onFiltersChanged,
    this.initialState = const SearchFilterState(),
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late SearchFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  void _apply() {
    widget.onFiltersChanged(_state);
  }

  void _reset() {
    setState(() {
      _state = const SearchFilterState();
    });
    widget.onFiltersChanged(_state);
  }

  void _showPriceSheet() {
    final minController = TextEditingController(
      text: _state.minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _state.maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Prix',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        prefixText: '\$',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        prefixText: '\$',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _state = _state.copyWith(
                            minPrice: null,
                            maxPrice: null,
                          );
                        });
                        minController.clear();
                        maxController.clear();
                        _apply();
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final min = double.tryParse(minController.text);
                        final max = double.tryParse(maxController.text);
                        setState(() {
                          _state = _state.copyWith(
                            minPrice: min,
                            maxPrice: max,
                          );
                        });
                        _apply();
                        Navigator.pop(context);
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CategorySelectionSheet(
          initialState: _state,
          onApply: ({
            required int? categoryId,
            required String? category,
            required int? subcategoryId,
            required String? subcategory,
          }) {
            setState(() {
              _state = SearchFilterState(
                minPrice: _state.minPrice,
                maxPrice: _state.maxPrice,
                category: category,
                categoryId: categoryId,
                subcategory: subcategory,
                subcategoryId: subcategoryId,
                condition: _state.condition,
                sortBy: _state.sortBy,
              );
            });
            _apply();
          },
        );
      },
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trier par',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildSortOption('Plus récent', SortBy.newest),
                _buildSortOption('Plus Proche', SortBy.nearest),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _state = _state.copyWith(sortBy: SortBy.relevance);
                      });
                      _apply();
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, SortBy sortBy) {
    return ListTile(
      title: Text(label),
      leading: Icon(
        _state.sortBy == sortBy
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: _state.sortBy == sortBy ? UzaColors.primary : Colors.grey,
      ),
      onTap: () {
        setState(() {
          _state = _state.copyWith(sortBy: sortBy);
        });
        _apply();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
        selectedColor: UzaColors.primary.withValues(alpha: 0.15),
        checkmarkColor: UzaColors.primary,
        labelStyle: TextStyle(
          color: isActive ? UzaColors.primary : Colors.black87,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? UzaColors.primary : Colors.grey[300]!,
          ),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCategoryActive =
        _state.category != null || _state.subcategory != null;
    final isSortActive = _state.sortBy != SortBy.relevance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Catégorie',
                    isCategoryActive,
                    _showCategorySheet,
                  ),
                  _buildFilterChip('Trier', isSortActive, _showSortSheet),
                  _buildFilterChip(
                    'Près de Moi',
                    _state.sortBy == SortBy.nearest,
                    () {
                      setState(() {
                        _state = _state.copyWith(
                          sortBy: _state.sortBy == SortBy.nearest
                              ? SortBy.relevance
                              : SortBy.nearest,
                        );
                      });
                      _apply();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_state.hasActiveFilters)
            TextButton(onPressed: _reset, child: const Text('Tout effacer')),
        ],
      ),
    );
  }
}

typedef _CategoryFilterApply =
    void Function({
      required int? categoryId,
      required String? category,
      required int? subcategoryId,
      required String? subcategory,
    });

/// Category selection sheet with cascading subcategory support
class _CategorySelectionSheet extends StatefulWidget {
  final SearchFilterState initialState;
  final _CategoryFilterApply onApply;

  const _CategorySelectionSheet({
    required this.initialState,
    required this.onApply,
  });

  @override
  State<_CategorySelectionSheet> createState() =>
      _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<_CategorySelectionSheet> {
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubcategoryId;
  String? _selectedSubcategoryName;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialState.categoryId;
    _selectedCategoryName = widget.initialState.category;
    _selectedSubcategoryId = widget.initialState.subcategoryId;
    _selectedSubcategoryName = widget.initialState.subcategory;
  }

  void _applySelection() {
    widget.onApply(
      categoryId: _selectedCategoryId,
      category: _selectedCategoryName,
      subcategoryId: _selectedSubcategoryId,
      subcategory: _selectedSubcategoryName,
    );
    Navigator.pop(context);
  }

  void _resetSelection() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedSubcategoryId = null;
      _selectedSubcategoryName = null;
    });
    widget.onApply(
      categoryId: null,
      category: null,
      subcategoryId: null,
      subcategory: null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;
    final isAutreCategory =
        _selectedCategoryName?.toLowerCase().contains('autre') ?? false;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catégorie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Category>>(
                  stream: productRepo.watchRootCategories(),
                  builder: (context, rootSnapshot) {
                    if (rootSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final categories = rootSnapshot.data ?? [];
                    if (categories.isEmpty) {
                      return const Center(child: Text('Aucune catégorie'));
                    }

                    return StreamBuilder<List<Category>>(
                      stream: _selectedCategoryId != null
                          ? productRepo.watchCategoriesByParent(
                              _selectedCategoryId,
                            )
                          : Stream.value(const []),
                      builder: (context, subSnapshot) {
                        final subcategories = subSnapshot.data ?? [];

                        return ListView(
                          children: [
                            ...categories.map((cat) {
                              final isSelected = _selectedCategoryId == cat.id;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(cat.name),
                                leading: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? UzaColors.primary
                                      : Colors.grey,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = cat.id;
                                    _selectedCategoryName = cat.name;
                                    _selectedSubcategoryId = null;
                                    _selectedSubcategoryName = null;
                                  });
                                },
                              );
                            }),
                            if (_selectedCategoryId != null) ...[
                              const Divider(height: 24),
                              Text(
                                isAutreCategory
                                    ? 'Catégories personnalisées'
                                    : 'Sous-catégorie',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (subSnapshot.connectionState ==
                                  ConnectionState.waiting)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else if (subcategories.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    isAutreCategory
                                        ? 'Aucune catégorie personnalisée pour l\'instant'
                                        : 'Aucune sous-catégorie',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else
                                ...subcategories.map((sub) {
                                  final isSelected =
                                      _selectedSubcategoryId == sub.id;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(sub.name),
                                    leading: Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? UzaColors.primary
                                          : Colors.grey,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedSubcategoryId = sub.id;
                                        _selectedSubcategoryName = sub.name;
                                      });
                                    },
                                  );
                                }),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetSelection,
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applySelection,
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
