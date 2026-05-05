import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../local/uza_database.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';

enum SyncStatus { idle, syncing, error, offline }

class SyncService extends ChangeNotifier {
  final UzaDatabase db;
  final ApiService api;
  final NotificationService? notificationService;
  Timer? _syncTimer;
  bool _isSyncing = false;
  SyncStatus _syncStatus = SyncStatus.idle;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool get isSyncing => _isSyncing;
  SyncStatus get syncStatus => _syncStatus;

  /// True when the database has no products yet (first-launch state).
  bool _isFirstSync = true;
  bool get isFirstSync => _isFirstSync;

  /// Only show update notification once per app session.
  bool _hasNotifiedThisSession = false;

  /// In-memory retry counters per SyncQueue item id.
  /// After 3 failures the item stays in queue but a warning is logged;
  /// on app restart the counters reset, giving items fresh attempts.
  final Map<int, int> _retryCounts = {};
  static const int _maxRetries = 3;

  /// Check local DB for existing products to initialise [isFirstSync].
  Future<void> checkFirstSync() async {
    try {
      final existing = await (db.select(db.products)..limit(1)).get();
      _isFirstSync = existing.isEmpty;
    } catch (_) {
      _isFirstSync = true;
    }
  }

  /// Number of pending changes in the SyncQueue.
  int _pendingChangesCount = 0;
  int get pendingChangesCount => _pendingChangesCount;

  static const Duration _requestTimeout = Duration(seconds: 10);

  SyncService(this.db, this.api, {this.notificationService});

  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint("Sync already in progress, skipping...");
      return;
    }

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      debugPrint("Starting background sync...");
      await pushLocalChanges();
      await pullRemoteUpdates();
      _lastSyncTime = DateTime.now();
      _syncStatus = SyncStatus.idle;
      debugPrint("Sync completed at $_lastSyncTime");
    } catch (e) {
      debugPrint("SYNC ERROR: $e");
      _syncStatus = SyncStatus.error;
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
      notifyListeners();
    }
  }

  Future<void> pushLocalChanges() async {
    try {
      final queue = await db.select(db.syncQueue).get();

      for (var item in queue) {
        try {
          final success = await api
              .pushChange(
                item.entityType,
                item.action,
                jsonDecode(item.entityData),
              )
              .timeout(_requestTimeout);

          if (success) {
            await (db.delete(
              db.syncQueue,
            )..where((t) => t.id.equals(item.id))).go();
            _retryCounts.remove(item.id); // clear on success
          } else {
            // Failed push – increment retry counter
            final retries = (_retryCounts[item.id] ?? 0) + 1;
            _retryCounts[item.id] = retries;

            if (retries >= _maxRetries) {
              debugPrint(
                'PUSH WARNING: ${item.entityType}/${item.action} '
                'failed $retries times — keeping in queue for next session',
              );
            } else {
              debugPrint(
                'PUSH FAILED: ${item.entityType}/${item.action} '
                '(attempt $retries/$_maxRetries) — will retry next sync',
              );
            }
          }
        } on TimeoutException {
          final retries = (_retryCounts[item.id] ?? 0) + 1;
          _retryCounts[item.id] = retries;
          debugPrint(
            'PUSH TIMEOUT: ${item.entityType}/${item.action} '
            '(attempt $retries/$_maxRetries) — will retry next sync',
          );
        } catch (e) {
          final retries = (_retryCounts[item.id] ?? 0) + 1;
          _retryCounts[item.id] = retries;
          debugPrint(
            'PUSH ERROR for item ${item.id}: $e — will retry next sync',
          );
        }
      }
    } catch (e) {
      debugPrint('PUSH ERROR: $e');
    }
  }

  /// Immediately retries ALL queued items regardless of retry count.
  /// Useful when the user manually triggers a refresh.
  Future<void> forcePush() async {
    // Reset retry counters so every item gets a fresh attempt
    _retryCounts.clear();
    await pushLocalChanges();
    await _updatePendingCount();
  }

  Future<void> pullRemoteUpdates() async {
    try {
      final prefs = await db.select(db.appPreferences).getSingleOrNull();

      if (prefs == null) {
        await db
            .into(db.appPreferences)
            .insertOnConflictUpdate(
              AppPreferencesCompanion.insert(id: const Value(1)),
            );
      }

      final DateTime? lastSyncTime = prefs?.lastSync;

      // ── PHASE 1: categories & products (most critical for display) ──────
      List<Map<String, dynamic>> remoteCategories = [];
      List<Map<String, dynamic>> remoteProducts = [];

      try {
        remoteCategories = await api
            .fetchCategories(updatedSince: lastSyncTime)
            .timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: categories');
      } catch (e) {
        debugPrint('PULL ERROR (categories): $e');
      }

      try {
        remoteProducts = await api
            .fetchProducts(updatedSince: lastSyncTime)
            .timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: products');
      } catch (e) {
        debugPrint('PULL ERROR (products): $e');
      }

      // Build a map of remoteId -> localId for shops to resolve product relationships
      final allShops = await db.select(db.shops).get();
      final Map<String, int> shopIdMap = {
        for (var s in allShops) s.remoteId ?? '': s.id,
      };

      // Build a comprehensive map of remoteId -> localId from ALL existing
      // products to prevent any duplication during pull sync.
      final allProducts = await db.select(db.products).get();
      final Map<String, int> productIdMap = {};
      for (final p in allProducts) {
        final rId = p.remoteId;
        if (rId != null && rId.isNotEmpty) {
          productIdMap[rId] = p.id;
        }
      }

      // Batch-insert categories & products immediately so the UI can render
      if (remoteCategories.isNotEmpty || remoteProducts.isNotEmpty) {
        await db.batch((batch) {
          for (var cat in remoteCategories) {
            final String rId =
                (cat['id'] ?? cat['remote_id'])?.toString() ?? '';
            batch.insert(
              db.categories,
              CategoriesCompanion.insert(
                remoteId: Value(rId),
                name: cat['name'] as String? ?? 'Sans nom',
                icon: Value(cat['icon'] as String?),
                updatedAt: Value(
                  DateTime.tryParse(cat['updated_at'] as String? ?? '') ??
                      DateTime.now(),
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }

          for (var p in remoteProducts) {
            final String rId = (p['id'] ?? p['remote_id'])?.toString() ?? '';
            final String rawName = p['name'] as String? ?? '';
            final String sanitizedName = rawName.trim().isEmpty
                ? 'Produit'
                : rawName;

            final String sRemoteId =
                (p['shop_id'] ?? p['shop_remote_id'])?.toString() ?? '';
            final int localShopId =
                shopIdMap[sRemoteId] ??
                (p['shop_id'] is int ? p['shop_id'] as int : 0);

            final int? existingLocalId = productIdMap[rId];

            batch.insert(
              db.products,
              ProductsCompanion(
                id: existingLocalId != null
                    ? Value(existingLocalId)
                    : const Value.absent(),
                remoteId: Value(rId),
                shopId: Value(localShopId),
                categoryId: Value(p['category_id'] as int?),
                name: Value(sanitizedName),
                description: Value(p['description'] as String?),
                price: Value((p['price'] as num?)?.toDouble()),
                imageUrls: Value(p['image_urls'] as String? ?? ''),
                isArrival: Value(
                  p['is_arrival'] == 1 || p['is_arrival'] == true,
                ),
                isPromotion: Value(
                  p['is_promotion'] == 1 || p['is_promotion'] == true,
                ),
                boostStatus: Value(p['boost_status'] as int? ?? 0),
                hidePrice: Value(
                  p['hide_price'] == 1 || p['hide_price'] == true,
                ),
                showStock: Value(
                  p['show_stock'] == 1 || p['show_stock'] == true,
                ),
                stockCount: Value(p['stock_count'] as int?),
                viewsCount: Value(p['views_count'] as int? ?? 0),
                sharesCount: Value(p['shares_count'] as int? ?? 0),
                ratingsCount: Value(p['ratings_count'] as int? ?? 0),
                ratingAvg: Value((p['rating_avg'] as num? ?? 0.0).toDouble()),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });

        // Update first-sync flag now that products exist
        if (remoteProducts.isNotEmpty) {
          _isFirstSync = false;
        }

        // Small delay to let the DB transaction fully settle before the UI
        // reads the new state — prevents momentary duplicate flickering.
        await Future.delayed(const Duration(milliseconds: 50));

        // Notify UI immediately — categories & products are ready
        notifyListeners();
      }

      // ── PHASE 2: shops & stories (less critical) ───────────────────────
      List<Map<String, dynamic>> remoteShops = [];
      List<Map<String, dynamic>> remoteStories = [];

      try {
        remoteShops = await api
            .fetchShops(updatedSince: lastSyncTime)
            .timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: shops');
      } catch (e) {
        debugPrint('PULL ERROR (shops): $e');
      }

      try {
        remoteStories = await api
            .fetchStories(updatedSince: lastSyncTime)
            .timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: stories');
      } catch (e) {
        debugPrint('PULL ERROR (stories): $e');
      }

      // Pre-check story deduplication before batch insert
      final existingStoryRemoteIds = <String>{};
      if (remoteStories.isNotEmpty) {
        final remoteIds = remoteStories
            .map((st) => (st['id'] ?? st['remote_id'])?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        if (remoteIds.isNotEmpty) {
          final existingStories = await (db.select(
            db.stories,
          )..where((t) => t.remoteId.isIn(remoteIds))).get();
          existingStoryRemoteIds.addAll(
            existingStories.map((s) => s.remoteId).whereType<String>(),
          );
        }
      }

      if (remoteShops.isNotEmpty || remoteStories.isNotEmpty) {
        await db.batch((batch) {
          for (var s in remoteShops) {
            final String rId = (s['id'] ?? s['remote_id'])?.toString() ?? '';
            final String rawName = s['name'] as String? ?? '';
            final String sanitizedName = rawName.trim().isEmpty
                ? 'Boutique'
                : rawName;

            batch.insert(
              db.shops,
              ShopsCompanion.insert(
                remoteId: Value(rId),
                name: sanitizedName,
                description: Value(s['description'] as String?),
                logoUrl: Value(s['logo_url'] as String?),
                type: ShopType.values.firstWhere(
                  (e) => e.name == s['type'],
                  orElse: () => ShopType.retail,
                ),
                ownerId: Value(s['owner_id']?.toString()),
                address: Value(s['address'] as String?),
                whatsapp: Value(s['whatsapp'] as String?),
                phone: Value(s['phone'] as String?),
                email: Value(s['email'] as String?),
                instagramUrl: Value(s['instagram_url'] as String?),
                tiktokUrl: Value(s['tiktok_url'] as String?),
                facebookUrl: Value(s['facebook_url'] as String?),
                youtubeUrl: Value(s['youtube_url'] as String?),
                bannerUrl: Value(s['banner_url'] as String?),
                boostStatus: Value(s['boost_status'] as int? ?? 0),
                bannerStatus: Value(s['banner_status'] as int? ?? 0),
                bannerText: Value(s['banner_text'] as String?),
                videoUrl: Value(s['video_url'] as String?),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }

          for (var st in remoteStories) {
            final String rId = (st['id'] ?? st['remote_id'])?.toString() ?? '';

            // Skip if story with this remoteId already exists (dedup)
            if (rId.isNotEmpty && existingStoryRemoteIds.contains(rId)) {
              continue;
            }

            // Map server shop_id to local shop id
            final String sRemoteId = (st['shop_id'])?.toString() ?? '';
            final int localShopId =
                shopIdMap[sRemoteId] ??
                (st['shop_id'] is int ? st['shop_id'] as int : 0);

            batch.insert(
              db.stories,
              StoriesCompanion.insert(
                remoteId: Value(rId),
                shopId: localShopId,
                mediaUrl: st['media_url'] as String? ?? '',
                mediaType: st['media_type'] as String? ?? 'image',
                expiresAt:
                    DateTime.tryParse(st['expires_at'] as String? ?? '') ??
                    DateTime.now().add(const Duration(hours: 24)),
                createdAt: Value(
                  DateTime.tryParse(st['created_at'] as String? ?? '') ??
                      DateTime.now(),
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }

      debugPrint(
        "Boutiques: ${remoteShops.length}, Produits: ${remoteProducts.length} synchronisés.",
      );

      if (remoteProducts.isNotEmpty) {
        _prefetchBoostedImages(remoteProducts);
      }

      // Update last sync time
      await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
        AppPreferencesCompanion(lastSync: Value(DateTime.now())),
      );

      // Only notify once per session and only for significant changes
      if (notificationService != null &&
          !_hasNotifiedThisSession &&
          (remoteShops.length > 5 || remoteProducts.length > 5)) {
        final prefs = await db.select(db.appPreferences).getSingleOrNull();
        final notificationsEnabled = prefs?.notificationsEnabled ?? true;
        if (notificationsEnabled) {
          notificationService!.addNotification(
            'Mise à jour terminée',
            '${remoteShops.length} boutiques et ${remoteProducts.length} produits mis à jour.',
          );
          _hasNotifiedThisSession = true;
        }
      }
    } catch (e, stack) {
      debugPrint("PULL ERROR: $e");
      debugPrint("STACK TRACE: $stack");
      _syncStatus = SyncStatus.error;
      notifyListeners();
    }
    // NOTE: _isSyncing is managed by syncNow()'s finally block.
  }

  void _prefetchBoostedImages(List<Map<String, dynamic>> products) {
    // Basic pre-fetching logic (will trigger CachedNetworkImage pre-caching)
    final boosted = products.where((p) => p['boostStatus'] == 2);
    for (var p in boosted) {
      final imgString = p['imageUrls'] as String? ?? '';
      final images = imgString.split(',');
      if (images.isNotEmpty && images.first.isNotEmpty) {
        // We could use an ImageProvider and resolve it here to force cache
        // precacheImage(NetworkImage(images.first), ...);
      }
    }
  }

  Future<void> addToQueue(
    String action,
    String entityType,
    Map<String, dynamic> data,
  ) async {
    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            action: action,
            entityType: entityType,
            entityData: jsonEncode(data),
          ),
        );
  }

  Future<void> reportInteraction(
    int entityId,
    String type, {
    double? rating,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("${api.baseUrl}/sync.php"),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': ApiService.apiKey,
            },
            body: jsonEncode({
              'entityType': 'products',
              'action': 'INCREMENT_STAT',
              'data': {
                'id': entityId,
                'type': type,
                if (rating != null) 'rating': rating,
              },
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        debugPrint("Failed to report interaction: ${response.body}");
      }
    } on TimeoutException {
      debugPrint('TIMEOUT: reportInteraction for entity $entityId');
    } catch (e) {
      debugPrint("Error reporting interaction: $e");
    }
  }

  /// Ensures that categories are synced from the server at least once.
  /// Call this before showing the product creation form so that the
  /// category dropdown is populated with server-side categories.
  Future<void> ensureCategoriesSynced() async {
    try {
      final existing = await (db.select(db.categories)..limit(1)).get();
      if (existing.isNotEmpty) return; // categories already present

      // Force a pull of categories from server
      debugPrint('Categories table empty — forcing category sync…');
      List<Map<String, dynamic>> remoteCategories = [];
      try {
        remoteCategories = await api.fetchCategories().timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: categories (ensureCategoriesSynced)');
      } catch (e) {
        debugPrint('PULL ERROR (ensureCategoriesSynced): $e');
      }

      if (remoteCategories.isNotEmpty) {
        await db.batch((batch) {
          for (var cat in remoteCategories) {
            final String rId =
                (cat['id'] ?? cat['remote_id'])?.toString() ?? '';
            batch.insert(
              db.categories,
              CategoriesCompanion.insert(
                remoteId: Value(rId),
                name: cat['name'] as String? ?? 'Sans nom',
                icon: Value(cat['icon'] as String?),
                updatedAt: Value(
                  DateTime.tryParse(cat['updated_at'] as String? ?? '') ??
                      DateTime.now(),
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        debugPrint('Synced ${remoteCategories.length} categories.');
      }
    } catch (e) {
      debugPrint('ensureCategoriesSynced error: $e');
    }
  }

  /// Update the pending changes count from the SyncQueue.
  Future<void> _updatePendingCount() async {
    try {
      final count = await db
          .select(db.syncQueue)
          .get()
          .then((rows) => rows.length);
      if (_pendingChangesCount != count) {
        _pendingChangesCount = count;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating pending count: $e');
    }
  }
}
