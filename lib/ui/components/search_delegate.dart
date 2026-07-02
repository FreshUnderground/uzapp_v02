import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/product_price_utils.dart';
import '../screens/product_detail_screen.dart';
import '../components/product_card.dart';

// ─── Search History ────────────────────────────────────────────────

class SearchHistory {
  static const String _key = 'search_history';
  static const int _maxItems = 10;

  static Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        return []; // Gracefully degrade on web
      }
      rethrow;
    }
  }

  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      history.remove(query); // Remove duplicate
      history.insert(0, query); // Add to top
      if (history.length > _maxItems) history.removeLast();
      await prefs.setStringList(_key, history);
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        return; // Gracefully degrade on web
      }
      rethrow;
    }
  }

  static Future<void> removeSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      history.remove(query);
      await prefs.setStringList(_key, history);
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        return; // Gracefully degrade on web
      }
      rethrow;
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      if (kIsWeb || e.toString().contains('MissingPluginException')) {
        return; // Gracefully degrade on web
      }
      rethrow;
    }
  }
}

// ─── Product Search Delegate ───────────────────────────────────────

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final ProductRepository productRepo;
  List<String> _popularCategories = [];

  ProductSearchDelegate(this.productRepo);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = UzaColors.onSurface(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: UzaColors.surfaceOf(context),
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: UzaColors.onSurfaceSecondary(context)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      IconButton(
        icon: const Icon(Icons.mic_none_outlined),
        onPressed: () {
          // Placeholder for future voice search
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildEmptyQueryContent();
    }

    // Add to search history
    SearchHistory.addSearch(query.trim());

    return FutureBuilder<List<Product>>(
      future: productRepo.searchProducts(query: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonGrid(context);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoResults(context);
        }

        final results = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${results.length} résultat${results.length > 1 ? 's' : ''} pour « ${query.trim()} »',
                style: TextStyle(
                  fontSize: 14,
                  color: UzaColors.onSurfaceSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800
                      ? 3
                      : 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final product = results[index];
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyQueryContent();
    }

    return FutureBuilder<List<Product>>(
      future: productRepo.getSearchSuggestionProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Aucune suggestion pour « $query »',
                style: TextStyle(color: UzaColors.onSurfaceSecondary(context)),
              ),
            ),
          );
        }

        final suggestions = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final product = suggestions[index];
            final images = ImageUtils.getDecryptedList(product.imageUrls);
            final thumbnail = images.isNotEmpty ? images.first : '';

            return InkWell(
              onTap: () {
                query = product.name;
                showResults(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Product thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumbnail.isNotEmpty
                          ? ImageUtils.buildCachedImage(
                              thumbnail,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              memCacheWidth: 96,
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHighlightedText(
                            product.name,
                            query,
                            TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: UzaColors.onSurface(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FutureBuilder<Shop?>(
                            future: context
                                .read<ProductRepository>()
                                .resolveShopForProduct(product),
                            builder: (context, shopSnapshot) {
                              final shop = shopSnapshot.data;
                              final address = shop?.address?.trim();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (shop != null && shop.name.isNotEmpty)
                                    Text(
                                      shop.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: UzaColors.onSurfaceSecondary(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (address != null && address.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: UzaColors.onSurfaceSecondary(context),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              address,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: UzaColors.onSurfaceSecondary(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (product.category != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: UzaColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.category!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: UzaColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                ProductPriceUtils.displayLabel(product),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ProductPriceUtils.hasVisiblePrice(
                                    product,
                                  )
                                      ? UzaColors.secondary
                                      : UzaColors.onSurfaceSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.north_west,
                      size: 16,
                      color: UzaColors.onSurfaceSecondary(context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Empty Query Content ─────────────────────────────────────────

  Widget _buildEmptyQueryContent() {
    return FutureBuilder<List<String>>(
      future: _loadPopularCategories(),
      builder: (context, popularSnapshot) {
        return FutureBuilder<List<String>>(
          future: SearchHistory.getHistory(),
          builder: (context, historySnapshot) {
            final history = historySnapshot.data ?? [];
            final popular = popularSnapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent searches
                  if (history.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recherches récentes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: UzaColors.onSurface(context),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await SearchHistory.clearHistory();
                              // Force rebuild
                              query = '';
                              query = query; // triggers rebuild
                            },
                            child: const Text(
                              'Effacer',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...history.map((item) => _buildHistoryItem(item, context)),
                    const SizedBox(height: 16),
                  ],

                  // Popular categories
                  if (popular.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Populaires',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: UzaColors.onSurface(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: popular.map((cat) {
                          return ActionChip(
                            label: Text(cat),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: UzaColors.secondary.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: UzaColors.secondary.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () {
                              query = cat;
                              showResults(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(String item, BuildContext context) {
    return Dismissible(
      key: Key('history_$item'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => SearchHistory.removeSearch(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.history,
          size: 20,
          color: UzaColors.onSurfaceSecondary(context),
        ),
        title: Text(item, style: const TextStyle(fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () async {
            await SearchHistory.removeSearch(item);
            query = '';
            query = query; // trigger rebuild
          },
        ),
        onTap: () {
          query = item;
          showResults(context);
        },
      ),
    );
  }

  // ─── No Results ──────────────────────────────────────────────────

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: UzaColors.onSurface(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec des mots-clés différents pour « ${query.trim()} »',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UzaColors.onSurfaceSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton Loading ────────────────────────────────────────────

  Widget _buildSkeletonGrid(BuildContext context) {
    final shimmer = UzaColors.shimmerOf(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: shimmer.base,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // ─── Highlighted Text ────────────────────────────────────────────

  Widget _buildHighlightedText(String text, String highlight, TextStyle base) {
    if (highlight.isEmpty) return Text(text, style: base);

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    final matchIndex = lowerText.indexOf(lowerHighlight);
    if (matchIndex == -1) return Text(text, style: base);

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + highlight.length);
    final after = text.substring(matchIndex + highlight.length);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ─── Load Popular Categories ─────────────────────────────────────

  Future<List<String>> _loadPopularCategories() async {
    if (_popularCategories.isEmpty) {
      _popularCategories = await productRepo.getPopularCategories();
    }
    return _popularCategories;
  }
}
