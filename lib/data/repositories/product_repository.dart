import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, sin, atan2, pi;
import 'package:flutter/foundation.dart' hide Category;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../local/uza_database.dart';
import '../services/sync_service.dart';
import 'shop_repository.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/utils/category_helper.dart';
import '../../core/utils/image_utils.dart';
import 'location_data.dart';
import 'paginated_result.dart';

class ProductRepository {
  final UzaDatabase db;
  final SyncService? syncService;
  final ShopRepository? shopRepository;

  /// Server shop id persisted in product metadata during sync.
  static const syncShopIdMetaKey = '_sync_shop_id';

  ProductRepository(
    this.db, {
    this.syncService,
    this.shopRepository,
  });

  /// Resolves the boutique that owns [product], even when [Product.shopId]
  /// accidentally stores a server shop id instead of the local row id.
  Future<Shop?> resolveShopForProduct(Product product) async {
    final shopRepo = shopRepository;
    if (shopRepo == null) return null;

    final serverShopId = readServerShopIdFromProduct(product);
    if (serverShopId != null) {
      final byServer = await shopRepo.resolveShopByServerId(serverShopId);
      if (byServer != null) return byServer;
    }

    return shopRepo.resolveShopForStoredId(product.shopId);
  }

  static int? readServerShopIdFromProduct(Product product) {
    final raw = product.metadata;
    if (raw == null || raw.isEmpty) return null;
    try {
      final meta = jsonDecode(raw) as Map<String, dynamic>;
      final value = meta[syncShopIdMetaKey];
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Stream<List<Product>> watchProductsByShop(int shopId) {
    return (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map(deduplicateForDisplay);
  }

  /// Products for a shop card/profile — follows canonical local row when [shop] has remoteId.
  Stream<List<Product>> watchProductsForShop(Shop shop) {
    final shopRepo = shopRepository;
    if (shopRepo == null) return watchProductsByShop(shop.id);
    return shopRepo.watchShop(shop).asyncExpand((resolved) {
      final localId = resolved?.id ?? shop.id;
      return watchProductsByShop(localId);
    });
  }

  Stream<List<Category>> watchCategories({int? parentId}) {
    return (db.select(db.categories)
          ..where((t) {
            if (parentId != null) {
              return t.parentId.equals(parentId);
            }
            return const Constant(true);
          })
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<Category>> watchCategoriesByParent(int? parentId) {
    return db.select(db.categories).watch().map((all) {
      if (parentId == null) {
        return all.where((c) => c.parentId == null).toList()
          ..sort(_compareCategories);
      }

      final parent = all.where((c) => c.id == parentId).firstOrNull;
      final serverParentId = parent != null
          ? CategoryHelper.serverIdFor(parent)
          : parentId;

      return all
          .where(
            (c) =>
                c.parentId == parentId || c.parentId == serverParentId,
          )
          .toList()
        ..sort(_compareCategories);
    });
  }

  int _compareCategories(Category a, Category b) {
    final sortCmp = a.sortOrder.compareTo(b.sortOrder);
    if (sortCmp != 0) return sortCmp;
    return a.name.compareTo(b.name);
  }

  Stream<List<Category>> watchRootCategories() {
    return (db.select(db.categories)
          ..where((t) => t.level.equals(0))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch()
        .map((categories) {
          debugPrint(
            'Categories stream emitted: ${categories.length} root categories',
          );
          return categories;
        });
  }

  Future<List<Category>> getCategoryChildren(int categoryId) async {
    final all = await db.select(db.categories).get();
    final parent = all.where((c) => c.id == categoryId).firstOrNull;
    final serverParentId = parent != null
        ? CategoryHelper.serverIdFor(parent)
        : categoryId;
    return all
        .where(
          (c) => c.parentId == categoryId || c.parentId == serverParentId,
        )
        .toList()
      ..sort(_compareCategories);
  }

  Future<List<Category>> getCategories() {
    return (db.select(
      db.categories,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<List<Product>> getProductsByShop(int shopId) {
    return (db.select(
      db.products,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// Products from wholesale (B2B) shops.
  Stream<List<Product>> watchWholesaleProducts() {
    return db.select(db.shops).watch().asyncExpand((wholesaleShops) {
      final ids = wholesaleShops
          .where((s) => s.type == ShopType.wholesale)
          .map((s) => s.id)
          .toList();
      if (ids.isEmpty) return Stream.value(<Product>[]);
      return (db.select(db.products)
            ..where((t) => t.shopId.isIn(ids))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
    });
  }

  Stream<List<Product>> watchArrivals() {
    return (db.select(
      db.products,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch().map(
      (items) => _shuffleBoostedWithImagesFirst(deduplicateForDisplay(items)),
    );
  }

  Stream<List<Product>> watchProductsByCategory(int categoryId) {
    return (db.select(
      db.products,
    )..where((t) => t.categoryId.equals(categoryId))).watch().map(
      (items) => _shuffleBoostedWithImagesFirst(deduplicateForDisplay(items)),
    );
  }

  Stream<List<Product>> watchProductsFiltered({
    int? categoryId,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String sortBy = 'relevance',
  }) {
    return (db.select(db.products)..where((t) {
          Expression<bool> predicate = const Constant(true);
          if (categoryId != null) {
            predicate &= t.categoryId.equals(categoryId);
          } else if (category != null) {
            predicate &= t.category.equals(category);
          }
          if (minPrice != null) {
            predicate &= t.price.isBiggerOrEqualValue(minPrice);
          }
          if (maxPrice != null) {
            predicate &= t.price.isSmallerOrEqualValue(maxPrice);
          }
          if (condition != null && condition.isNotEmpty) {
            predicate &= t.condition.equals(condition);
          }
          return predicate;
        }))
        .watch()
        .map((items) {
          final unique = deduplicateForDisplay(items);
          switch (sortBy) {
            case 'priceAsc':
              return _sortThenImagesLast(
                unique,
                (a, b) => (a.price ?? 0).compareTo(b.price ?? 0),
              );
            case 'priceDesc':
              return _sortThenImagesLast(
                unique,
                (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
              );
            case 'newest':
              return _sortThenImagesLast(
                unique,
                (a, b) => b.updatedAt.compareTo(a.updatedAt),
              );
            case 'relevance':
            default:
              return _shuffleBoostedWithImagesFirst(unique);
          }
        });
  }

  Stream<List<Product>> watchPromotions() {
    return (db.select(
      db.products,
    )..where((t) => t.isPromotion.equals(true)))
        .watch()
        .map(deduplicateForDisplay);
  }

  Stream<List<Product>> watchPendingBoosts() {
    return (db.select(
      db.products,
    )..where((t) => t.boostStatus.equals(1))).watch();
  }

  Future<Product?> getProductById(int id) {
    return (db.select(
      db.products,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Resolves a product for deep links: local DB first, then public API.
  Future<Product?> resolveProductById(int id) async {
    final local = await getProductById(id);
    if (local != null) return local;

    final byRemote = await (db.select(db.products)
          ..where((t) => t.remoteId.equals(id.toString())))
        .getSingleOrNull();
    if (byRemote != null) return byRemote;

    try {
      final uri = Uri.parse(
        'https://uzaapp.com/api/product_page.php?id=$id&format=json',
      );
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final data = body['product'] as Map<String, dynamic>?;
      if (data == null) return null;

      final serverShopId = _toInt(data['shop_id']);
      var localShopId = 0;
      if (serverShopId != null && serverShopId > 0) {
        final shop = await shopRepository?.resolveShopById(serverShopId);
        localShopId = shop?.id ?? 0;
        if (localShopId <= 0) {
          final localByServerId = await shopRepository?.getShopById(serverShopId);
          if (localByServerId != null) {
            localShopId = localByServerId.id;
          }
        }
      }
      if (localShopId <= 0 && serverShopId != null && serverShopId > 0) {
        // Deep link: keep server shop id so the product page can still open.
        localShopId = serverShopId;
      }
      if (localShopId <= 0) return null;

      final productRemoteId = data['remote_id']?.toString();
      final rId = productRemoteId != null && productRemoteId.isNotEmpty
          ? productRemoteId
          : (_toInt(data['id']) ?? id).toString();

      final existing = await (db.select(db.products)
            ..where((t) => t.remoteId.equals(rId)))
          .getSingleOrNull();

      final localId = await db.into(db.products).insert(
        ProductsCompanion(
          id: existing != null
              ? Value(existing.id)
              : const Value.absent(),
          remoteId: Value(rId),
          shopId: Value(localShopId),
          categoryId: Value(_toInt(data['category_id'])),
          name: Value((data['name'] as String? ?? 'Produit').trim()),
          description: Value(data['description'] as String?),
          price: Value((data['price'] as num?)?.toDouble()),
          category: Value(data['category'] as String?),
          imageUrls: Value(_coerceImageUrls(data['image_urls'])),
          isArrival: Value(_toBool(data['is_arrival'])),
          isPromotion: Value(_toBool(data['is_promotion'])),
          stockCount: Value(_toInt(data['stock_count'])),
          hidePrice: Value(_toBool(data['hide_price'])),
          showStock: Value(_toBool(data['show_stock'])),
          isBoosted: Value(_toBool(data['is_boosted'])),
          promotionMessage: Value(data['promotion_message'] as String?),
          updatedAt: Value(
            DateTime.tryParse(data['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
          viewsCount: Value(_toInt(data['views_count']) ?? 0),
          sharesCount: Value(_toInt(data['shares_count']) ?? 0),
          ratingsCount: Value(_toInt(data['ratings_count']) ?? 0),
          ratingAvg: Value((data['rating_avg'] as num? ?? 0).toDouble()),
          boostStatus: Value(_toInt(data['boost_status']) ?? 0),
          condition: Value(data['condition'] as String? ?? 'new'),
          reportCount: Value(_toInt(data['report_count']) ?? 0),
          isSold: Value(_toBool(data['is_sold'])),
          metadata: Value(data['metadata']?.toString()),
        ),
      );
      return getProductById(localId);
    } catch (e) {
      debugPrint('resolveProductById error: $e');
      return null;
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    final normalized = value?.toString().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }

  String _coerceImageUrls(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return jsonEncode(value);
  }

  Future<int> addProduct(ProductsCompanion product) async {
    final id = await db.into(db.products).insert(product);
    if (product.shopId.present) {
      unawaited(shopRepository?.recordShopActivity(product.shopId.value));
    }
    return id;
  }

  Future<bool> updateProduct(ProductsCompanion product) async {
    final updated = await (db.update(db.products)
          ..where((t) => t.id.equals(product.id.value)))
        .write(product)
        .then((rows) => rows > 0);
    if (updated && product.shopId.present) {
      unawaited(shopRepository?.recordShopActivity(product.shopId.value));
    } else if (updated && product.id.present) {
      final existing = await getProductById(product.id.value);
      if (existing != null) {
        unawaited(shopRepository?.recordShopActivity(existing.shopId));
      }
    }
    return updated;
  }

  Future<int> deleteProduct(int id) {
    return (db.delete(db.products)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes the product locally and queues a DELETE sync operation
  /// so the removal propagates to the server.
  Future<int> deleteProductWithSync(int id) async {
    final product = await getProductById(id);
    final rowsDeleted = await (db.delete(
      db.products,
    )..where((t) => t.id.equals(id))).go();

    if (rowsDeleted > 0 && syncService != null) {
      final remoteId = product?.remoteId != null && product!.remoteId!.isNotEmpty
          ? int.tryParse(product.remoteId!)
          : product?.id;
      if (remoteId != null) {
        await syncService!.addToQueue('DELETE', 'products', {
          'id': remoteId,
        });
        unawaited(syncService!.forcePush());
      }
    }

    return rowsDeleted;
  }

  /// Admin removal by local id and/or server product id (reports, dashboard).
  Future<bool> adminDeleteProduct({
    int? localId,
    int? serverProductId,
  }) async {
    Product? product;
    if (localId != null) {
      product = await getProductById(localId);
    }
    if (product == null && serverProductId != null) {
      product = await (db.select(db.products)
            ..where((t) => t.remoteId.equals('$serverProductId')))
          .getSingleOrNull();
    }

    if (product != null) {
      return (await deleteProductWithSync(product.id)) > 0;
    }

    if (serverProductId != null && syncService != null) {
      await syncService!.addToQueue('DELETE', 'products', {
        'id': serverProductId,
      });
      unawaited(syncService!.forcePush());
      return true;
    }

    return false;
  }

  Stream<List<Product>> watchAllProductsAdmin({String? query}) {
    final q = query?.trim().toLowerCase();
    return db.select(db.products).watch().map((items) {
      final sorted = List<Product>.from(items)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (q == null || q.isEmpty) return sorted;
      return sorted
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    });
  }

  Future<void> updateStock(int productId, int quantity) {
    return (db.update(db.products)..where((t) => t.id.equals(productId))).write(
      ProductsCompanion(stockCount: Value(quantity)),
    );
  }

  Future<void> markProductAsSold(int productId) async {
    await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
      ProductsCompanion(isSold: const Value(true)),
    );
  }

  Future<void> markProductAsAvailable(int productId) async {
    await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
      ProductsCompanion(isSold: const Value(false)),
    );
  }

  Future<void> logProductInteraction(int productId, String type) async {
    await db
        .into(db.analytics)
        .insert(
          AnalyticsCompanion.insert(
            entityType: 'product',
            entityId: productId,
            interactionType: type,
          ),
        );
  }

  Future<void> logProductView(int productId) async {
    await logProductInteraction(productId, 'view');
  }

  Stream<int> watchProductViewCount(int productId) {
    return (db.selectOnly(db.analytics)
          ..addColumns([db.analytics.id.count()])
          ..where(
            db.analytics.entityId.equals(productId) &
                db.analytics.entityType.equals('product') &
                db.analytics.interactionType.equals('view'),
          ))
        .watch()
        .map((rows) => rows.first.read(db.analytics.id.count()) ?? 0);
  }

  /// Watch all products ordered by newest first (no limit).
  Stream<List<Product>> watchAllProducts() {
    return (db.select(
      db.products,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map(deduplicateForDisplay);
  }

  /// Pool stable (ordre récent) pour l'accueil — sans mélange à chaque sync.
  Stream<List<Product>> watchHomeProductPool({int poolSize = 40}) {
    return (db.select(db.products)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((items) => deduplicateForDisplay(items).take(poolSize).toList());
  }

  /// Tirage aléatoire ponctuel parmi un pool (retour accueil, pull-to-refresh).
  List<Product> pickTrendingProducts(List<Product> pool, {int limit = 10}) {
    if (pool.isEmpty) return const [];
    final unique = deduplicateForDisplay(pool);
    return _shuffleBoostedWithImagesFirst(unique).take(limit).toList();
  }

  /// Produits populaires : tirage aléatoire parmi les plus récents.
  Stream<List<Product>> watchTrendingProducts({int limit = 10}) {
    final poolSize = (limit * 4).clamp(limit, 80);
    return watchHomeProductPool(poolSize: poolSize).map(
      (pool) => pickTrendingProducts(pool, limit: limit),
    );
  }

  /// Hide duplicate catalog rows in public feeds (sync/create bugs).
  /// Same [remoteId], or same shop + name + price → one card only.
  List<Product> deduplicateForDisplay(List<Product> items) {
    if (items.length <= 1) return items;

    final synced = <String, Product>{};
    final localOnly = <String, Product>{};
    final syncedLocalKeys = <String>{};

    for (final product in items) {
      final remote = product.remoteId?.trim();
      if (remote == null || remote.isEmpty) continue;

      final existing = synced[remote];
      synced[remote] = existing == null
          ? product
          : _pickPreferredDuplicate(existing, product);
      syncedLocalKeys.add(_localDedupKey(synced[remote]!));
    }

    for (final product in items) {
      final remote = product.remoteId?.trim();
      if (remote != null && remote.isNotEmpty) continue;

      final key = _localDedupKey(product);
      if (syncedLocalKeys.contains(key)) continue;

      final existing = localOnly[key];
      localOnly[key] = existing == null
          ? product
          : _pickPreferredDuplicate(existing, product);
    }

    final winners = <int, Product>{
      for (final p in synced.values) p.id: p,
      for (final p in localOnly.values) p.id: p,
    };

    return items.where((p) => winners.containsKey(p.id)).toList();
  }

  String _localDedupKey(Product product) {
    final name = product.name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final price = product.price?.toStringAsFixed(2) ?? '';
    return '${product.shopId}:$name:$price';
  }

  Product _pickPreferredDuplicate(Product a, Product b) {
    final aHasImages = ImageUtils.hasDisplayableImage(a.imageUrls);
    final bHasImages = ImageUtils.hasDisplayableImage(b.imageUrls);
    if (aHasImages != bHasImages) return aHasImages ? a : b;
    if (a.isSold != b.isSold) return a.isSold ? b : a;
    if (a.boostStatus != b.boostStatus) {
      return a.boostStatus > b.boostStatus ? a : b;
    }
    if (a.updatedAt != b.updatedAt) {
      return a.updatedAt.isAfter(b.updatedAt) ? a : b;
    }
    final aRemote = a.remoteId != null && a.remoteId!.isNotEmpty;
    final bRemote = b.remoteId != null && b.remoteId!.isNotEmpty;
    if (aRemote != bRemote) return aRemote ? a : b;
    return a.id <= b.id ? a : b;
  }

  /// Removes local duplicate rows left by sync/create bugs.
  Future<int> repairDisplayDuplicates() async {
    final all = await db.select(db.products).get();
    final keep = deduplicateForDisplay(all);
    final keepIds = keep.map((p) => p.id).toSet();
    var removed = 0;

    for (final product in all) {
      if (keepIds.contains(product.id)) continue;

      await (db.delete(db.products)..where((t) => t.id.equals(product.id))).go();
      removed++;
    }

    return removed;
  }

  /// Products with displayable images first, then those without or failed.
  List<Product> _shuffleBoostedWithImagesFirst(List<Product> items) {
    final boostedWith = <Product>[];
    final regularWith = <Product>[];
    final boostedWithout = <Product>[];
    final regularWithout = <Product>[];

    for (final product in items) {
      final hasImage = ImageUtils.hasDisplayableImage(product.imageUrls);
      if (product.boostStatus == 2) {
        (hasImage ? boostedWith : boostedWithout).add(product);
      } else {
        (hasImage ? regularWith : regularWithout).add(product);
      }
    }

    boostedWith.shuffle();
    regularWith.shuffle();
    boostedWithout.shuffle();
    regularWithout.shuffle();

    return [
      ...boostedWith,
      ...regularWith,
      ...boostedWithout,
      ...regularWithout,
    ];
  }

  List<Product> _sortThenImagesLast(
    List<Product> items,
    int Function(Product a, Product b) compare,
  ) {
    final withImages = items
        .where((p) => ImageUtils.hasDisplayableImage(p.imageUrls))
        .toList()
      ..sort(compare);
    final withoutImages = items
        .where((p) => !ImageUtils.hasDisplayableImage(p.imageUrls))
        .toList()
      ..sort(compare);
    return [...withImages, ...withoutImages];
  }

  /// Keep existing order within each group; images first, no-image at end.
  List<Product> _preserveOrderWithImagesFirst(List<Product> items) {
    final withImages = <Product>[];
    final withoutImages = <Product>[];
    for (final product in items) {
      if (ImageUtils.hasDisplayableImage(product.imageUrls)) {
        withImages.add(product);
      } else {
        withoutImages.add(product);
      }
    }
    return [...withImages, ...withoutImages];
  }

  Future<List<Product>> searchProductsByKeywords(List<String> keywords) {
    return (db.select(db.products)..where((t) {
          Expression<bool> predicate = const Constant(false);
          for (final kw in keywords) {
            final lowerKw = '%${kw.toLowerCase()}%';
            predicate |=
                t.name.lower().like(lowerKw) |
                t.description.lower().like(lowerKw) |
                t.category.lower().like(lowerKw);
          }
          return predicate;
        }))
        .get();
  }

  /// Advanced search with multiple filters and relevance scoring
  Future<List<Product>> searchProducts({
    String? query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String sortBy = 'relevance', // relevance, priceAsc, priceDesc, newest
    int limit = 50,
  }) async {
    final lowerQuery = query != null && query.isNotEmpty
        ? '%${query.toLowerCase()}%'
        : null;

    return (db.select(db.products)
          ..where((t) {
            Expression<bool> predicate = const Constant(true);

            // Text search across name, description, category
            if (lowerQuery != null) {
              predicate &=
                  t.name.lower().like(lowerQuery) |
                  t.description.lower().like(lowerQuery) |
                  t.category.lower().like(lowerQuery);
            }

            // Category filter (by ID or name)
            if (categoryId != null) {
              predicate &= t.categoryId.equals(categoryId);
            }

            // Price range
            if (minPrice != null) {
              predicate &= t.price.isBiggerOrEqualValue(minPrice);
            }
            if (maxPrice != null) {
              predicate &= t.price.isSmallerOrEqualValue(maxPrice);
            }

            // Condition filter
            if (condition != null && condition.isNotEmpty) {
              predicate &= t.condition.equals(condition);
            }

            return predicate;
          })
          ..orderBy([
            // Apply sort order
            (t) {
              switch (sortBy) {
                case 'priceAsc':
                  return OrderingTerm.asc(t.price);
                case 'priceDesc':
                  return OrderingTerm.desc(t.price);
                case 'newest':
                  return OrderingTerm.desc(t.updatedAt);
                case 'relevance':
                default:
                  // Relevance: boosted first, then by views
                  return OrderingTerm.desc(t.boostStatus);
              }
            },
            // Secondary sort for relevance
            if (sortBy == 'relevance') (t) => OrderingTerm.desc(t.viewsCount),
          ])
          ..limit(limit))
        .get()
        .then((items) {
          if (sortBy != 'relevance') {
            switch (sortBy) {
              case 'priceAsc':
                return _sortThenImagesLast(
                  items,
                  (a, b) => (a.price ?? 0).compareTo(b.price ?? 0),
                );
              case 'priceDesc':
                return _sortThenImagesLast(
                  items,
                  (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
                );
              case 'newest':
                return _sortThenImagesLast(
                  items,
                  (a, b) => b.updatedAt.compareTo(a.updatedAt),
                );
              default:
                return items;
            }
          }
          // Relevance scoring: prioritize name match > description match > category match
          if (lowerQuery == null) {
            return _shuffleBoostedWithImagesFirst(items);
          }
          final rawQuery = query!.toLowerCase();
          items.sort((a, b) {
            int scoreA = 0;
            int scoreB = 0;
            // Name exact match
            if (a.name.toLowerCase() == rawQuery) scoreA += 100;
            if (b.name.toLowerCase() == rawQuery) scoreB += 100;
            // Name starts with
            if (a.name.toLowerCase().startsWith(rawQuery)) scoreA += 50;
            if (b.name.toLowerCase().startsWith(rawQuery)) scoreB += 50;
            // Name contains
            if (a.name.toLowerCase().contains(rawQuery)) scoreA += 30;
            if (b.name.toLowerCase().contains(rawQuery)) scoreB += 30;
            // Description contains
            if ((a.description ?? '').toLowerCase().contains(rawQuery)) {
              scoreA += 10;
            }
            if ((b.description ?? '').toLowerCase().contains(rawQuery)) {
              scoreB += 10;
            }
            // Boost bonus
            if (a.boostStatus == 2) scoreA += 20;
            if (b.boostStatus == 2) scoreB += 20;
            // Views bonus (diminishing)
            scoreA += (a.viewsCount / 10).floor().clamp(0, 15);
            scoreB += (b.viewsCount / 10).floor().clamp(0, 15);
            return scoreB.compareTo(scoreA);
          });
          return _preserveOrderWithImagesFirst(items);
        });
  }

  /// Get popular/trending categories based on product count
  Future<List<String>> getPopularCategories({int limit = 6}) async {
    final countExpr = db.products.id.count();
    final results =
        await (db.selectOnly(db.products)
              ..addColumns([db.products.category, countExpr])
              ..where(db.products.category.isNotNull())
              ..groupBy([db.products.category])
              ..orderBy([OrderingTerm.desc(countExpr)])
              ..limit(limit))
            .get();
    return results
        .map((row) => row.read(db.products.category))
        .whereType<String>()
        .toList();
  }

  /// Get search suggestions as rich data (product name + price + category)
  Future<List<Product>> getSearchSuggestionProducts(
    String query, {
    int limit = 5,
  }) async {
    if (query.isEmpty) return [];
    final lowerQuery = '%${query.toLowerCase()}%';
    return (db.select(db.products)
          ..where(
            (t) =>
                t.name.lower().like(lowerQuery) |
                t.description.lower().like(lowerQuery),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.viewsCount)])
          ..limit(limit))
        .get();
  }

  /// Products + arrivages for catalog sharing (non vendus, avec photo si possible).
  Future<({List<Product> arrivals, List<Product> products})> getShareableCatalog(
    int shopId, {
    int maxArrivals = 12,
    int maxProducts = 15,
  }) async {
    final all = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId) & t.isSold.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    final withImage = all
        .where((p) => ImageUtils.hasDisplayableImage(p.imageUrls))
        .toList();
    final pool = withImage.isNotEmpty ? withImage : all;

    final arrivals = pool.where((p) => p.isArrival).take(maxArrivals).toList();
    final products = pool
        .where((p) => !p.isArrival)
        .take(maxProducts)
        .toList();

    return (arrivals: arrivals, products: products);
  }

  Future<List<String>> getSearchSuggestions(String query) {
    if (query.isEmpty) return Future.value([]);
    final lowerQuery = '%${query.toLowerCase()}%';
    return (db.selectOnly(db.products)
          ..addColumns([db.products.name])
          ..where(db.products.name.lower().like(lowerQuery))
          ..limit(5))
        .get()
        .then((rows) => rows.map((r) => r.read(db.products.name)!).toList());
  }

  // Wishlist Methods
  Future<void> toggleWishlist(int productId) async {
    final entry = await (db.select(
      db.wishlistProducts,
    )..where((t) => t.productId.equals(productId))).getSingleOrNull();

    if (entry != null) {
      await (db.delete(
        db.wishlistProducts,
      )..where((t) => t.id.equals(entry.id))).go();
    } else {
      await db
          .into(db.wishlistProducts)
          .insert(WishlistProductsCompanion.insert(productId: productId));
    }
  }

  Stream<bool> watchIsInWishlist(int productId) {
    return (db.select(db.wishlistProducts)
          ..where((t) => t.productId.equals(productId)))
        .watch()
        .map((list) => list.isNotEmpty);
  }

  Stream<List<Product>> watchWishlistProducts() {
    final query = db.select(db.products).join([
      innerJoin(
        db.wishlistProducts,
        db.wishlistProducts.productId.equalsExp(db.products.id),
      ),
    ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(db.products)).toList(),
    );
  }

  // Review Methods
  Future<void> addReview(
    int productId,
    double rating,
    String comment, {
    String? userName,
  }) async {
    await db
        .into(db.productReviews)
        .insert(
          ProductReviewsCompanion.insert(
            productId: productId,
            rating: rating,
            comment: comment,
            userName: Value(userName),
          ),
        );

    // Update product rating average
    final reviews = await (db.select(
      db.productReviews,
    )..where((t) => t.productId.equals(productId))).get();
    if (reviews.isNotEmpty) {
      final avg =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      await (db.update(
        db.products,
      )..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          ratingAvg: Value(avg),
          ratingsCount: Value(reviews.length),
        ),
      );
    }
  }

  // ── Product Like Methods ──────────────────────────────────────

  /// Like a product. Returns true if a new like was created.
  Future<bool> likeProduct(int productId, String userPhone) async {
    final existing =
        await (db.select(db.productLikes)..where(
              (t) =>
                  t.productId.equals(productId) & t.userPhone.equals(userPhone),
            ))
            .getSingleOrNull();
    if (existing != null) return false; // Already liked

    await db
        .into(db.productLikes)
        .insert(
          ProductLikesCompanion.insert(
            productId: productId,
            userPhone: userPhone,
          ),
        );

    // Queue sync to backend (server ids for cross-device stats).
    if (syncService != null) {
      final remoteProductId =
          await syncService!.resolveRemoteProductId(productId);
      if (remoteProductId != null) {
        await syncService!.addToQueue('CREATE', 'product_likes', {
          'product_id': remoteProductId,
          'user_phone': userPhone,
        });
      }
    }
    return true;
  }

  /// Unlike a product. Returns true if a like was removed.
  Future<bool> unlikeProduct(int productId, String userPhone) async {
    final existing =
        await (db.select(db.productLikes)..where(
              (t) =>
                  t.productId.equals(productId) & t.userPhone.equals(userPhone),
            ))
            .getSingleOrNull();
    if (existing == null) return false; // Not liked

    await (db.delete(
      db.productLikes,
    )..where((t) => t.id.equals(existing.id))).go();

    // Queue sync to backend
    if (syncService != null) {
      final remoteProductId =
          await syncService!.resolveRemoteProductId(productId);
      if (remoteProductId != null) {
        await syncService!.addToQueue('DELETE', 'product_likes', {
          'product_id': remoteProductId,
          'user_phone': userPhone,
        });
      }
    }
    return true;
  }

  /// Toggle like on a product. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(int productId, String userPhone) async {
    final isLiked = await isProductLiked(productId, userPhone);
    if (isLiked) {
      await unlikeProduct(productId, userPhone);
      return false;
    } else {
      await likeProduct(productId, userPhone);
      return true;
    }
  }

  /// Check if a product is liked by a specific user.
  Future<bool> isProductLiked(int productId, String userPhone) async {
    final existing =
        await (db.select(db.productLikes)..where(
              (t) =>
                  t.productId.equals(productId) & t.userPhone.equals(userPhone),
            ))
            .getSingleOrNull();
    return existing != null;
  }

  /// Watch whether a product is liked by a specific user (reactive).
  Stream<bool> watchIsProductLiked(int productId, String userPhone) {
    return (db.select(db.productLikes)..where(
          (t) => t.productId.equals(productId) & t.userPhone.equals(userPhone),
        ))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  /// Get total like count for a product.
  Future<int> getProductLikeCount(int productId) async {
    final countExpr = db.productLikes.id.count();
    final result =
        await (db.selectOnly(db.productLikes)
              ..addColumns([countExpr])
              ..where(db.productLikes.productId.equals(productId)))
            .getSingle();
    return result.read(countExpr) ?? 0;
  }

  /// Watch total like count for a product (reactive).
  Stream<int> watchProductLikeCount(int productId) {
    final countExpr = db.productLikes.id.count();
    return (db.selectOnly(db.productLikes)
          ..addColumns([countExpr])
          ..where(db.productLikes.productId.equals(productId)))
        .watch()
        .map((rows) => rows.first.read(countExpr) ?? 0);
  }

  /// Get total likes for all products of a shop.
  Future<int> getShopTotalLikes(int shopId) async {
    final products = await (db.select(
      db.products,
    )..where((t) => t.shopId.equals(shopId))).get();
    final productIds = products.map((p) => p.id).toList();
    if (productIds.isEmpty) return 0;

    final countExpr = db.productLikes.id.count();
    final result =
        await (db.selectOnly(db.productLikes)
              ..addColumns([countExpr])
              ..where(db.productLikes.productId.isIn(productIds)))
            .getSingle();
    return result.read(countExpr) ?? 0;
  }

  /// Get unsynced product likes for batch sync.
  Future<List<ProductLike>> getUnsyncedLikes() {
    return (db.select(db.productLikes)..where((t) => t.synced.equals(0))).get();
  }

  /// Mark likes as synced by their IDs.
  Future<void> markLikesSynced(List<int> likeIds) async {
    for (final id in likeIds) {
      await (db.update(db.productLikes)..where((t) => t.id.equals(id))).write(
        const ProductLikesCompanion(synced: Value(1)),
      );
    }
  }

  Stream<List<ProductReview>> watchProductReviews(int productId) {
    return (db.select(db.productReviews)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Product>> suggestedProducts(int productId) {
    return (db.select(db.products)..where((t) => t.id.equals(productId)))
        .watchSingleOrNull()
        .asyncMap((current) async {
          if (current == null) return <Product>[];
          return RecommendationService(this).similarProducts(
            source: current,
            limit: 10,
          );
        });
  }

  /// Get products from shops in the same commune, then neighboring communes
  Future<List<Product>> getNearbyProducts(
    String userCommune, {
    int limit = 20,
  }) async {
    // 1. Get shops in same commune
    final sameCommuneShops = await (db.select(
      db.shops,
    )..where((t) => t.commune.equals(userCommune))).get();
    final sameCommuneIds = sameCommuneShops.map((s) => s.id).toList();

    // 2. Get products from same-commune shops (priority)
    List<Product> results = [];
    if (sameCommuneIds.isNotEmpty) {
      results =
          await (db.select(db.products)
                ..where((t) => t.shopId.isIn(sameCommuneIds))
                ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
                ..limit(limit))
              .get();
    }

    // 3. If not enough, expand to neighboring communes
    if (results.length < limit) {
      final neighbors = LocationData.getNeighboringCommunes(userCommune);
      if (neighbors.isNotEmpty) {
        final nearbyShops = await (db.select(
          db.shops,
        )..where((t) => t.commune.isIn(neighbors))).get();
        final nearbyShopIds = nearbyShops
            .map((s) => s.id)
            .where((id) => !sameCommuneIds.contains(id))
            .toList();

        if (nearbyShopIds.isNotEmpty) {
          final remaining = limit - results.length;
          final nearbyProducts =
              await (db.select(db.products)
                    ..where((t) => t.shopId.isIn(nearbyShopIds))
                    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
                    ..limit(remaining))
                  .get();
          results = [...results, ...nearbyProducts];
        }
      }
    }

    return results;
  }

  /// Get stats for a specific product from Analytics table
  Future<Map<String, int>> getProductStats(int productId) async {
    final analytics =
        await (db.select(db.analytics)..where(
              (t) =>
                  t.entityId.equals(productId) & t.entityType.equals('product'),
            ))
            .get();

    int views = 0;
    int contacts = 0;
    int shares = 0;

    for (final a in analytics) {
      switch (a.interactionType) {
        case 'view':
          views++;
          break;
        case 'whatsapp':
        case 'call':
        case 'sms':
          contacts++;
          break;
        case 'share':
          shares++;
          break;
      }
    }

    // Also include global synced stats from the product row itself
    final product = await getProductById(productId);
    if (product != null) {
      views += product.viewsCount;
      shares += product.sharesCount;
    }

    return {'views': views, 'contacts': contacts, 'shares': shares};
  }

  /// Get top performing products for a shop (by views)
  Future<List<Map<String, dynamic>>> getTopProducts(
    int shopId, {
    int limit = 5,
  }) async {
    final products =
        await (db.select(db.products)
              ..where((t) => t.shopId.equals(shopId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.viewsCount),
                (t) => OrderingTerm.desc(t.sharesCount),
              ])
              ..limit(limit))
            .get();

    final results = <Map<String, dynamic>>[];
    for (final p in products) {
      // Get analytics-based contact count for each product
      final contactCount =
          await (db.selectOnly(db.analytics)
                ..addColumns([db.analytics.id.count()])
                ..where(
                  db.analytics.entityId.equals(p.id) &
                      db.analytics.entityType.equals('product') &
                      db.analytics.interactionType.isIn([
                        'whatsapp',
                        'call',
                        'sms',
                      ]),
                ))
              .getSingle()
              .then((row) => row.read(db.analytics.id.count()) ?? 0);

      results.add({
        'id': p.id,
        'name': p.name,
        'imageUrls': p.imageUrls,
        'price': p.price,
        'views': p.viewsCount,
        'contacts': contactCount,
        'shares': p.sharesCount,
      });
    }
    return results;
  }

  /// Search products by proximity using Haversine formula.
  /// Returns products sorted by distance (closest first).
  Future<List<Product>> searchProductsNearby({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
    String? query,
    int? categoryId,
  }) async {
    final results = await _searchProductsNearbyWithDistance(
      userLat: userLat,
      userLng: userLng,
      radiusKm: radiusKm,
      query: query,
      categoryId: categoryId,
    );
    return results.map((r) => r.$1).toList();
  }

  /// Same as [searchProductsNearby] but also returns distance in km for each product.
  Future<List<(Product, double)>> searchProductsNearbyWithDistance({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
    String? query,
    int? categoryId,
  }) => _searchProductsNearbyWithDistance(
    userLat: userLat,
    userLng: userLng,
    radiusKm: radiusKm,
    query: query,
    categoryId: categoryId,
  );

  Future<List<(Product, double)>> _searchProductsNearbyWithDistance({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
    String? query,
    int? categoryId,
  }) async {
    final lowerQuery = query != null && query.isNotEmpty
        ? '%${query.toLowerCase()}%'
        : null;

    final select = db.select(db.products).join([
      innerJoin(db.shops, db.shops.id.equalsExp(db.products.shopId)),
    ]);

    select.where(
      db.shops.latitude.isNotNull() & db.shops.longitude.isNotNull(),
    );

    if (lowerQuery != null) {
      select.where(
        db.products.name.lower().like(lowerQuery) |
            db.products.description.lower().like(lowerQuery) |
            db.products.category.lower().like(lowerQuery),
      );
    }

    if (categoryId != null) {
      select.where(db.products.categoryId.equals(categoryId));
    }

    final results = await select.get();

    final List<(Product, double)> productDistances = [];
    for (final row in results) {
      final product = row.readTable(db.products);
      final shop = row.readTable(db.shops);
      if (shop.latitude != null && shop.longitude != null) {
        final distance = _haversineDistance(
          userLat,
          userLng,
          shop.latitude!,
          shop.longitude!,
        );
        if (distance <= radiusKm) {
          productDistances.add((product, distance));
        }
      }
    }

    productDistances.sort((a, b) => a.$2.compareTo(b.$2));
    return productDistances;
  }

  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Fetch products from local DB with pagination
  Future<PaginatedResult<Product>> getProductsPaginated({
    int page = 1,
    int perPage = 20,
    String? categoryId,
    String? searchQuery,
  }) async {
    final offset = (page - 1) * perPage;

    // Build predicate
    Expression<bool> predicate = const Constant(true);
    if (categoryId != null) {
      predicate &= db.products.categoryId.equals(int.parse(categoryId));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = '%${searchQuery.toLowerCase()}%';
      predicate &=
          db.products.name.lower().like(lowerQuery) |
          db.products.description.lower().like(lowerQuery);
    }

    // Count total
    final countExpr = db.products.id.count();
    final countResult =
        await (db.selectOnly(db.products)
              ..addColumns([countExpr])
              ..where(predicate))
            .getSingle();
    final total = countResult.read(countExpr) ?? 0;

    // Fetch data
    final data =
        await (db.select(db.products)
              ..where((t) => predicate)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(perPage, offset: offset))
            .get();

    return PaginatedResult(
      data: data,
      page: page,
      perPage: perPage,
      total: total,
      hasMore: (offset + data.length) < total,
    );
  }
}
