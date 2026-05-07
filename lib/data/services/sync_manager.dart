import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../local/uza_database.dart';
import '../../core/services/api_service.dart';

enum SyncState { idle, syncing, error, offline }

class SyncManager extends ChangeNotifier {
  final UzaDatabase db;
  final ApiService apiService;

  SyncState _state = SyncState.idle;
  DateTime? _lastSyncTime;
  int _pendingCount = 0;
  Timer? _syncTimer;
  Timer? _retryTimer;

  static const int _maxRetries = 5;
  static const Duration _wifiSyncInterval = Duration(minutes: 1);
  static const Duration _mobileSyncInterval = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 15);

  SyncState get state => _state;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCount => _pendingCount;
  bool get isOnline => _state != SyncState.offline;

  SyncManager({required this.db, required this.apiService});

  /// Start background sync with connectivity-aware intervals.
  /// [isOnWifi] controls the sync frequency.
  void startSync({bool isOnWifi = false}) {
    stopSync();

    final interval = isOnWifi ? _wifiSyncInterval : _mobileSyncInterval;

    // Run first sync immediately
    fullSync();

    // Then schedule periodic syncs
    _syncTimer = Timer.periodic(interval, (_) => fullSync());

    // Schedule retry timer for failed items every 30 seconds
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state != SyncState.syncing) {
        _retryFailedItems();
      }
    });

    debugPrint('SyncManager: started with interval ${interval.inMinutes} min');
  }

  /// Stop all background sync timers.
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Update sync interval when connectivity type changes.
  void updateConnectivity({required bool isOnWifi}) {
    if (_syncTimer != null) {
      startSync(isOnWifi: isOnWifi);
    }
  }

  /// Mark the manager as offline (no network).
  void markOffline() {
    _state = SyncState.offline;
    notifyListeners();
    debugPrint('SyncManager: marked offline');
  }

  /// Mark the manager as back online and trigger a sync.
  void markOnline() {
    if (_state == SyncState.offline) {
      _state = SyncState.idle;
      notifyListeners();
      fullSync();
      debugPrint('SyncManager: back online, triggering fullSync');
    }
  }

  /// Queue a local change for sync.
  Future<void> queueChange({
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final id =
        '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}';

    await db
        .into(db.offlineQueue)
        .insertOnConflictUpdate(
          OfflineQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: jsonEncode(payload),
          ),
        );

    await _updatePendingCount();

    // If online, trigger immediate sync attempt for this item
    if (isOnline) {
      // Use a microtask to avoid blocking the caller
      Future.microtask(() => processPendingQueue());
    }

    debugPrint('SyncManager: queued $action $entityType/$entityId');
  }

  /// Process all pending and retryable queue items.
  Future<void> processPendingQueue() async {
    // Fetch all 'pending' and 'failed' items that haven't exceeded max retries
    final pendingItems =
        await (db.select(db.offlineQueue)..where(
              (t) =>
                  t.status.equals('pending') |
                  (t.status.equals('failed') &
                      t.retryCount.isSmallerThanValue(_maxRetries)),
            ))
            .get();

    if (pendingItems.isEmpty) return;

    debugPrint('SyncManager: processing ${pendingItems.length} pending items');

    for (final item in pendingItems) {
      await _processQueueItem(item);
    }

    await _updatePendingCount();
  }

  /// Process a single queue item.
  Future<void> _processQueueItem(OfflineQueueData item) async {
    // Mark as syncing
    await (db.update(
      db.offlineQueue,
    )..where((t) => t.id.equals(item.id))).write(
      OfflineQueueCompanion(
        status: const Value('syncing'),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );

    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;

      final success = await apiService
          .pushChange(item.entityType, item.action, payload)
          .timeout(_requestTimeout);

      if (success) {
        // Mark as synced
        await (db.update(db.offlineQueue)..where((t) => t.id.equals(item.id)))
            .write(const OfflineQueueCompanion(status: Value('synced')));
        debugPrint('SyncManager: synced ${item.entityType}/${item.entityId}');
      } else {
        await _handleItemFailure(item, 'Server returned failure');
      }
    } on TimeoutException {
      await _handleItemFailure(item, 'Request timed out');
    } catch (e) {
      await _handleItemFailure(item, e.toString());
    }
  }

  /// Handle a failed sync attempt with exponential backoff.
  Future<void> _handleItemFailure(
    OfflineQueueData item,
    String errorMessage,
  ) async {
    final newRetryCount = item.retryCount + 1;

    if (newRetryCount >= _maxRetries) {
      // Max retries reached - mark as permanently failed
      await (db.update(
        db.offlineQueue,
      )..where((t) => t.id.equals(item.id))).write(
        OfflineQueueCompanion(
          status: const Value('failed'),
          retryCount: Value(newRetryCount),
          errorMessage: Value('Max retries reached: $errorMessage'),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );
      debugPrint(
        'SyncManager: item ${item.id} permanently failed after $_maxRetries retries',
      );
    } else {
      // Apply exponential backoff delay
      final backoffMs = _calculateBackoff(newRetryCount);
      final nextAttempt = DateTime.now().add(Duration(milliseconds: backoffMs));

      await (db.update(
        db.offlineQueue,
      )..where((t) => t.id.equals(item.id))).write(
        OfflineQueueCompanion(
          status: const Value('failed'),
          retryCount: Value(newRetryCount),
          errorMessage: Value(errorMessage),
          lastAttemptAt: Value(nextAttempt),
        ),
      );
      debugPrint(
        'SyncManager: item ${item.id} failed (retry $newRetryCount/$_maxRetries), '
        'backoff ${backoffMs}ms',
      );
    }
  }

  /// Calculate exponential backoff: min(2^retryCount * 1000, 30000) ms.
  int _calculateBackoff(int retryCount) {
    return (1 << retryCount) * 1000; // 2^retryCount * 1000, capped below
  }

  /// Retry failed items whose backoff period has elapsed.
  Future<void> _retryFailedItems() async {
    final now = DateTime.now();

    final retryableItems =
        await (db.select(db.offlineQueue)..where(
              (t) =>
                  t.status.equals('failed') &
                  t.retryCount.isSmallerThanValue(_maxRetries) &
                  t.lastAttemptAt.isSmallerThanValue(now),
            ))
            .get();

    if (retryableItems.isEmpty) return;

    debugPrint('SyncManager: retrying ${retryableItems.length} items');

    for (final item in retryableItems) {
      // Reset to pending so processPendingQueue picks it up
      await (db.update(db.offlineQueue)..where((t) => t.id.equals(item.id)))
          .write(const OfflineQueueCompanion(status: Value('pending')));
    }

    await processPendingQueue();
  }

  /// Pull remote updates (differential sync) with per-endpoint isolation.
  Future<void> pullUpdates() async {
    final prefs = await db.select(db.appPreferences).getSingleOrNull();

    if (prefs == null) {
      await db
          .into(db.appPreferences)
          .insertOnConflictUpdate(
            AppPreferencesCompanion.insert(id: const Value(1)),
          );
    }

    final DateTime? lastSyncTime = prefs?.lastSync;

    // Fetch each endpoint independently so one failure doesn't block others
    List<Map<String, dynamic>> remoteCategories = [];
    List<Map<String, dynamic>> remoteShops = [];
    List<Map<String, dynamic>> remoteProducts = [];
    List<Map<String, dynamic>> remoteStories = [];

    // Categories
    try {
      remoteCategories = await apiService
          .fetchCategories(updatedSince: lastSyncTime)
          .timeout(_requestTimeout);
    } catch (e) {
      debugPrint('SyncManager: failed to pull categories: $e');
    }

    // Shops
    try {
      remoteShops = await apiService
          .fetchShops(updatedSince: lastSyncTime)
          .timeout(_requestTimeout);
    } catch (e) {
      debugPrint('SyncManager: failed to pull shops: $e');
    }

    // Products
    try {
      remoteProducts = await apiService
          .fetchProducts(updatedSince: lastSyncTime)
          .timeout(_requestTimeout);
    } catch (e) {
      debugPrint('SyncManager: failed to pull products: $e');
    }

    // Stories
    try {
      remoteStories = await apiService
          .fetchStories(updatedSince: lastSyncTime)
          .timeout(_requestTimeout);
    } catch (e) {
      debugPrint('SyncManager: failed to pull stories: $e');
    }

    // Build a map of remoteId -> localId for shops
    final allShops = await db.select(db.shops).get();
    final Map<String, int> shopIdMap = {
      for (var s in allShops)
        if (s.remoteId != null) s.remoteId!: s.id,
    };

    // Build map of existing categories by remoteId
    final allCategories = await db.select(db.categories).get();
    final Map<String, int> categoryIdMap = {};
    for (final c in allCategories) {
      final rId = c.remoteId;
      if (rId != null && rId.isNotEmpty) {
        categoryIdMap[rId] = c.id;
      }
    }

    // Batch upsert
    await db.batch((batch) {
      // Sync Categories
      for (var cat in remoteCategories) {
        final String rId = (cat['id'] ?? cat['remote_id'])?.toString() ?? '';
        final int? existingLocalId = categoryIdMap[rId];
        batch.insert(
          db.categories,
          CategoriesCompanion(
            id: existingLocalId != null
                ? Value(existingLocalId)
                : const Value.absent(),
            remoteId: Value(rId),
            name: Value(cat['name'] as String? ?? 'Sans nom'),
            icon: Value(cat['icon'] as String?),
            level: Value(_toInt(cat['level']) ?? 0),
            parentId: Value(_toInt(cat['parent_id'])),
            sortOrder: Value(_toInt(cat['sort_order']) ?? 0),
            updatedAt: Value(
              DateTime.tryParse(cat['updated_at'] as String? ?? '') ??
                  DateTime.now(),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // Sync Shops
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

      // Sync Products
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

        batch.insert(
          db.products,
          ProductsCompanion.insert(
            remoteId: Value(rId),
            shopId: localShopId,
            categoryId: Value(p['category_id'] as int?),
            name: sanitizedName,
            description: Value(p['description'] as String?),
            price: Value((p['price'] as num?)?.toDouble()),
            imageUrls: p['image_urls'] as String? ?? '',
            isArrival: Value(p['is_arrival'] == 1 || p['is_arrival'] == true),
            isPromotion: Value(
              p['is_promotion'] == 1 || p['is_promotion'] == true,
            ),
            boostStatus: Value(p['boost_status'] as int? ?? 0),
            hidePrice: Value(p['hide_price'] == 1 || p['hide_price'] == true),
            showStock: Value(p['show_stock'] == 1 || p['show_stock'] == true),
            stockCount: Value(p['stock_count'] as int?),
            viewsCount: Value(p['views_count'] as int? ?? 0),
            sharesCount: Value(p['shares_count'] as int? ?? 0),
            ratingsCount: Value(p['ratings_count'] as int? ?? 0),
            ratingAvg: Value((p['rating_avg'] as num? ?? 0.0).toDouble()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // Sync Stories
      for (var st in remoteStories) {
        final String rId = (st['id'] ?? st['remote_id'])?.toString() ?? '';
        batch.insert(
          db.stories,
          StoriesCompanion.insert(
            remoteId: Value(rId),
            shopId: st['shop_id'] as int? ?? 0,
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

    // Update last sync time
    await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
      AppPreferencesCompanion(lastSync: Value(DateTime.now())),
    );

    debugPrint(
      'SyncManager: pulled updates - '
      'categories: ${remoteCategories.length}, '
      'shops: ${remoteShops.length}, '
      'products: ${remoteProducts.length}, '
      'stories: ${remoteStories.length}',
    );
  }

  /// Full sync cycle: push first, then pull.
  Future<void> fullSync() async {
    if (_state == SyncState.syncing) return; // Prevent concurrent syncs

    _state = SyncState.syncing;
    notifyListeners();

    try {
      await processPendingQueue(); // Push first
      await pullUpdates(); // Then pull
      _state = SyncState.idle;
      _lastSyncTime = DateTime.now();
      debugPrint('SyncManager: full sync completed at $_lastSyncTime');
    } catch (e) {
      _state = SyncState.error;
      debugPrint('SyncManager: sync failed: $e');
    }

    await _updatePendingCount();
    notifyListeners();
  }

  /// Update the pending count from the database.
  Future<void> _updatePendingCount() async {
    final count =
        await (db.select(db.offlineQueue)
              ..where((t) => t.status.isNotIn(const ['synced'])))
            .get()
            .then((rows) => rows.length);

    if (_pendingCount != count) {
      _pendingCount = count;
      notifyListeners();
    }
  }

  /// Check if there is a conflict for the given entity.
  /// A conflict exists when there's a local pending change AND the server has a newer update.
  Future<bool> hasConflict(
    String entityType,
    String entityId,
    DateTime serverUpdatedAt,
  ) async {
    // Check if there's a local pending change for this entity
    final localPending =
        await (db.select(db.offlineQueue)..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.entityId.equals(entityId) &
                  t.status.isNotIn(const ['synced']),
            ))
            .getSingleOrNull();

    if (localPending == null) {
      return false; // No local pending change, no conflict
    }

    // There's a pending local change; check if server has a newer update
    // The serverUpdatedAt comes from the server response, so if the caller detected
    // that server data is newer than local data, that's a conflict.
    // The presence of a pending local change + server having an update = conflict.
    return true;
  }

  /// Get all pending items for a specific entity type.
  Future<List<OfflineQueueData>> getPendingForType(String entityType) async {
    return await (db.select(db.offlineQueue)..where(
          (t) =>
              t.entityType.equals(entityType) &
              t.status.isNotIn(const ['synced']),
        ))
        .get();
  }

  /// Remove a synced item from the queue (cleanup).
  Future<void> removeSyncedItems() async {
    await (db.delete(
      db.offlineQueue,
    )..where((t) => t.status.equals('synced'))).go();
    await _updatePendingCount();
  }

  /// Clear all items from the offline queue (use with caution).
  Future<void> clearQueue() async {
    await db.delete(db.offlineQueue).go();
    _pendingCount = 0;
    notifyListeners();
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
