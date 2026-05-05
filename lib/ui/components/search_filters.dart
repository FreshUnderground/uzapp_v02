import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';

enum SortBy { relevance, priceAsc, priceDesc, newest }

class SearchFilterState {
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final String? condition;
  final SortBy sortBy;

  const SearchFilterState({
    this.minPrice,
    this.maxPrice,
    this.category,
    this.condition,
    this.sortBy = SortBy.relevance,
  });

  SearchFilterState copyWith({
    double? minPrice,
    double? maxPrice,
    String? category,
    String? condition,
    SortBy? sortBy,
  }) {
    return SearchFilterState(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      category != null ||
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
                  'Catégorie',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...widget.categories.map((cat) {
                  return ListTile(
                    title: Text(cat),
                    leading: Icon(
                      _state.category == cat
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _state.category == cat
                          ? UzaColors.primary
                          : Colors.grey,
                    ),
                    onTap: () {
                      setState(() {
                        _state = _state.copyWith(category: cat);
                      });
                      _apply();
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _state = _state.copyWith(category: null);
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
                _buildSortOption('Pertinence', SortBy.relevance),
                _buildSortOption('Prix croissant', SortBy.priceAsc),
                _buildSortOption('Prix décroissant', SortBy.priceDesc),
                _buildSortOption('Plus récent', SortBy.newest),
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
    final isPriceActive = _state.minPrice != null || _state.maxPrice != null;
    final isCategoryActive = _state.category != null;
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
                  _buildFilterChip('Prix', isPriceActive, _showPriceSheet),
                  _buildFilterChip(
                    'Catégorie',
                    isCategoryActive,
                    _showCategorySheet,
                  ),
                  _buildFilterChip('Trier', isSortActive, _showSortSheet),
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
