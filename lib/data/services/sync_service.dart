import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../local/uza_database.dart';
import '../../core/services/api_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/test_data_cleanup.dart';
import '../../core/services/product_alerts_service.dart';
import '../../core/services/product_alert_notifier.dart';
import '../../core/services/product_upload_service.dart';
import '../repositories/order_repository.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/shop_repository.dart';
import '../repositories/product_update_repository.dart';
import '../repositories/story_repository.dart';
import '../../core/services/product_update_notifier.dart';
import '../../core/utils/shop_stats_types.dart';

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

  /// True when local catalog data is available (offline / slow-network UX).
  bool _hasLocalCatalog = false;
  bool get hasLocalCatalog => _hasLocalCatalog;

  bool _bootstrapSyncRequested = false;
  bool _fullCatalogSyncScheduled = false;

  static const int _previewProductPages = 1;
  static const int _previewProductsPerPage = 80;
  static const int _previewShopPages = 3;

  /// Only show update notification once per app session.
  bool _hasNotifiedThisSession = false;

  DateTime? _lastMediaPrefetch;
  static const Duration _mediaPrefetchCooldown = Duration(minutes: 20);
  static const int _priorityProductPrefetch = 48;
  static const int _priorityShopPrefetch = 24;
  static const int _priorityStoryPrefetch = 30;

  /// In-memory retry counters per SyncQueue item id.
  /// After 3 failures the item stays in queue but a warning is logged;
  /// on app restart the counters reset, giving items fresh attempts.
  final Map<int, int> _retryCounts = {};
  static const int _maxRetries = 3;
  Future<void>? _pushChain;
  static const String _kDeletedStoryRemoteIds = 'deleted_story_remote_ids';

  Future<void> markStoryDeletedRemotely(String remoteId) async {
    if (remoteId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kDeletedStoryRemoteIds) ?? [];
    if (!ids.contains(remoteId)) {
      ids.add(remoteId);
      await prefs.setStringList(_kDeletedStoryRemoteIds, ids);
    }
  }

  Future<Set<String>> _loadDeletedStoryRemoteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kDeletedStoryRemoteIds) ?? []).toSet();
  }

  /// Check local DB for existing products to initialise [isFirstSync].
  Future<void> checkFirstSync() async {
    try {
      final existing = await (db.select(db.products)..limit(1)).get();
      _isFirstSync = existing.isEmpty;
      _hasLocalCatalog = existing.isNotEmpty;
      final prefs = await db.select(db.appPreferences).getSingleOrNull();
      _lastSyncTime = prefs?.lastSync;
    } catch (_) {
      _isFirstSync = true;
      _hasLocalCatalog = false;
    }
    notifyListeners();
  }

  /// Single startup sync — idempotent, safe to call from HomeScreen and main().
  Future<void> requestBootstrapSync() async {
    if (_bootstrapSyncRequested) return;
    _bootstrapSyncRequested = true;
    await _runBootstrapSync();
  }

  Future<void> _runBootstrapSync() async {
    try {
      if (_isFirstSync) {
        if (!_isSyncing) {
          await syncCatalogPreview();
        }
        if (!_fullCatalogSyncScheduled) {
          _fullCatalogSyncScheduled = true;
          unawaited(
            syncNow().catchError((e) {
              debugPrint('Full catalog sync after preview error: $e');
            }),
          );
        }
        return;
      }
      await repairShopsWithoutRemoteId();
      if (!_isSyncing) {
        await syncNow();
      }
    } catch (e) {
      debugPrint('Bootstrap sync error: $e');
    }
  }

  /// Fast first-launch path: categories + shops + first product page only.
  Future<void> syncCatalogPreview() async {
    if (_isSyncing) return;

    if (!isOnline) {
      _syncStatus = SyncStatus.offline;
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      debugPrint('Starting catalog preview sync (first launch)...');
      await pullRemoteUpdates(catalogPreview: true);
      _syncStatus = SyncStatus.idle;
    } catch (e) {
      debugPrint('Catalog preview sync error: $e');
      _syncStatus = SyncStatus.error;
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
      notifyListeners();
    }
  }

  /// Queue any shops that have no remoteId for a fresh sync push.
  /// This repairs shops created before the remoteId mapping fix was deployed.
  Future<void> repairShopsWithoutRemoteId() async {
    try {
      final shops = await db.select(db.shops).get();
      final shopsWithoutRemoteId = shops
          .where((s) => s.remoteId == null || s.remoteId!.isEmpty)
          .toList();

      if (shopsWithoutRemoteId.isEmpty) return;

      debugPrint(
        'REPAIR: Found ${shopsWithoutRemoteId.length} shop(s) with no remoteId — re-queuing for sync',
      );

      // Check which shops are already in the sync queue to avoid duplicates
      final queue = await db.select(db.syncQueue).get();
      final queuedShopLocalIds = queue
          .where((item) => item.entityType == 'shops')
          .map((item) {
            try {
              final data = jsonDecode(item.entityData) as Map<String, dynamic>;
              return data['local_id'] as int?;
            } catch (_) {
              return null;
            }
          })
          .whereType<int>()
          .toSet();

      for (final shop in shopsWithoutRemoteId) {
        if (queuedShopLocalIds.contains(shop.id)) continue; // already queued
        await addToQueue('CREATE', 'shops', {
          'local_id': shop.id,
          'name': shop.name,
          'description': shop.description,
          'address': shop.address,
          'logo_url': _plainMediaUrl(shop.logoUrl),
          'type': shop.type.name,
          'owner_id': shop.ownerId,
          'phone': shop.phone,
          'whatsapp': shop.whatsapp,
          'facebook_url': shop.facebookUrl,
          'instagram_url': shop.instagramUrl,
          'tiktok_url': shop.tiktokUrl,
          'youtube_url': shop.youtubeUrl,
          'city': shop.city,
          'commune': shop.commune,
          if (shop.latitude != null) 'latitude': shop.latitude,
          if (shop.longitude != null) 'longitude': shop.longitude,
        });
        debugPrint('REPAIR: Re-queued shop id=${shop.id} name=${shop.name}');
      }
    } catch (e) {
      debugPrint('REPAIR shops error: $e');
    }
  }

  /// Number of pending changes in the SyncQueue.
  int _pendingChangesCount = 0;
  int get pendingChangesCount => _pendingChangesCount;

  Duration get _requestTimeout {
    if (liteMode) return const Duration(seconds: 8);
    if (_connectivity == null) return const Duration(seconds: 12);
    switch (_connectivity!.type) {
      case ConnectivityType.wifi:
        return const Duration(seconds: 20);
      case ConnectivityType.mobile:
        return const Duration(seconds: 10);
      case ConnectivityType.none:
        return const Duration(seconds: 5);
    }
  }

  SyncService(
    this.db,
    this.api, {
    this.notificationService,
  });

  StoryRepository? storyRepository;
  ProductRepository? productRepository;
  ShopRepository? shopRepository;
  OrderRepository? orderRepository;
  DeliveryRepository? deliveryRepository;
  ProductAlertsService? productAlertsService;

  ConnectivityService? _connectivity;
  VoidCallback? _connectivityListener;

  /// Binds network state; pauses sync when offline and resumes when online.
  void bindConnectivity(ConnectivityService connectivity) {
    _connectivity?.removeListener(_connectivityListener ?? () {});
    _connectivity = connectivity;
    _connectivityListener = () {
      if (connectivity.isOnline) {
        if (_syncStatus == SyncStatus.offline) {
          _syncStatus = SyncStatus.idle;
          notifyListeners();
        }
        _restartAutoSyncTimer();
        syncNow();
      } else {
        _syncStatus = SyncStatus.offline;
        _syncTimer?.cancel();
        notifyListeners();
      }
    };
    connectivity.addListener(_connectivityListener!);
    if (!connectivity.isOnline) {
      _syncStatus = SyncStatus.offline;
    }
  }

  bool get isOnline => _connectivity?.isOnline ?? true;
  bool liteMode = false;

  Duration get _autoSyncInterval {
    if (liteMode) return const Duration(minutes: 15);
    if (_connectivity == null) return const Duration(seconds: 30);
    switch (_connectivity!.type) {
      case ConnectivityType.wifi:
        return const Duration(seconds: 30);
      case ConnectivityType.mobile:
        return const Duration(minutes: 3);
      case ConnectivityType.none:
        return const Duration(minutes: 5);
    }
  }

  void _restartAutoSyncTimer() {
    if (_connectivity != null && !_connectivity!.isOnline) return;
    startAutoSync(interval: _autoSyncInterval);
  }

  void startAutoSync({Duration? interval}) {
    _syncTimer?.cancel();
    final effective = interval ?? _autoSyncInterval;
    _syncTimer = Timer.periodic(effective, (_) => syncNow());
  }

  /// Forces a full catalog pull (deletion detection included).
  Future<void> forceFullSync() async {
    _isFirstSync = true;
    await syncNow();
  }

  @override
  void dispose() {
    if (_connectivityListener != null) {
      _connectivity?.removeListener(_connectivityListener!);
    }
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Trigger an immediate sync (push + pull) for real-time updates.
  /// This is called after creating content to make it visible to others quickly.
  Future<void> triggerImmediateSync() async {
    if (_isSyncing) {
      debugPrint("Immediate sync: already syncing, skipping");
      return;
    }
    debugPrint("IMMEDIATE SYNC: Triggering push+pull for real-time update");
    await syncNow();
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint("Sync already in progress, skipping...");
      return;
    }

    if (!isOnline) {
      _syncStatus = SyncStatus.offline;
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      debugPrint("Starting background sync...");
      if (!_isFirstSync) {
        await repairShopsWithoutRemoteId();
        await repairProductShopLinks();
      }
      if (productRepository != null && shopRepository != null) {
        await ProductUploadService.processAllPending(
          db: db,
          api: api,
          productRepo: productRepository!,
          shopRepo: shopRepository!,
          syncService: this,
        );
      }
      await pushLocalChanges();
      await pullRemoteUpdates();
      await _fireProductAlerts();

      // Clean up expired stories during each sync cycle
      if (storyRepository != null) {
        try {
          final deleted = await storyRepository!.deleteExpiredStories();
          if (deleted > 0) {
            debugPrint('Cleaned up $deleted expired stories');
          }
        } catch (e) {
          debugPrint('STORY CLEANUP ERROR: $e');
        }
      }

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

  /// Push order: users → shops → products → stories (shops before products).
  int _pushPriority(String entityType) {
    switch (entityType) {
      case 'users':
        return 0;
      case 'shops':
        return 1;
      case 'products':
        return 2;
      case 'stories':
        return 3;
      default:
        return 4;
    }
  }

  Future<void> pushLocalChanges() {
    final previous = _pushChain ?? Future<void>.value();
    final current = previous.then((_) => _pushLocalChangesImpl());
    _pushChain = current;
    return current.whenComplete(() {
      if (identical(_pushChain, current)) {
        _pushChain = null;
      }
    });
  }

  Future<void> _pushLocalChangesImpl() async {
    try {
      final queue = await db.select(db.syncQueue).get();
      if (queue.isEmpty) {
        debugPrint('PUSH: queue is empty — nothing to push');
        return;
      }

      final sortedQueue = [...queue]
        ..sort(
          (a, b) => _pushPriority(a.entityType).compareTo(
            _pushPriority(b.entityType),
          ),
        );

      debugPrint('=' * 60);
      debugPrint('PUSH: Starting push of ${sortedQueue.length} items');
      debugPrint(
        'PUSH: Queue items (sorted): ${sortedQueue.map((item) => '${item.entityType}/${item.action}').join(', ')}',
      );
      debugPrint('=' * 60);

      int pushed = 0;
      int failed = 0;
      int skipped = 0;

      for (var item in sortedQueue) {
        // Skip items that already exceeded max retries — they'll stay in
        // queue but won't be attempted until a forcePush resets counters.
        final currentRetries = _retryCounts[item.id] ?? 0;
        if (currentRetries >= _maxRetries) {
          skipped++;
          if (skipped == 1) {
            // Log only once for the first skipped item to avoid spam
            debugPrint(
              'PUSH: skipping items that exceeded $_maxRetries retries '
              '(first skipped: ${item.entityType}/${item.action} id=${item.id})',
            );
          }
          continue;
        }

        debugPrint(
          'PUSH [${pushed + failed + skipped + 1}/${queue.length}] '
          '${item.entityType}/${item.action} id=${item.id}',
        );
        debugPrint('PUSH DATA (full): ${item.entityData}');

        try {
          var payload =
              jsonDecode(item.entityData) as Map<String, dynamic>;

          if (item.entityType == 'products') {
            final prepared = await _prepareProductPushPayload(
              item.action,
              payload,
            );
            if (prepared == null) {
              skipped++;
              debugPrint(
                'PUSH: deferring products/${item.action} queue id=${item.id} '
                '— waiting for server id after CREATE',
              );
              continue;
            }
            payload = prepared;
          }

          final responseData = await api
              .pushChange(
                item.entityType,
                item.action,
                payload,
              )
              .timeout(_requestTimeout);

          if (responseData != null) {
            // Map server-returned ID back to local entity
            final serverId = responseData['id'];
            if (serverId != null && item.entityType == 'stories') {
              await _mapServerIdToLocalStory(item, serverId.toString());
            }
            if (serverId != null && item.entityType == 'products') {
              await _mapServerIdToLocalProduct(item, serverId.toString());
            }
            if (serverId != null && item.entityType == 'shops') {
              await _mapServerIdToLocalShop(item, serverId.toString());
            }
            if (serverId != null && item.entityType == 'orders') {
              await _mapServerIdToLocalOrder(item, serverId.toString());
            }
            if (serverId != null && item.entityType == 'deliveries') {
              await _mapServerIdToLocalDelivery(item, serverId.toString());
            }

            await (db.delete(
              db.syncQueue,
            )..where((t) => t.id.equals(item.id))).go();
            _retryCounts.remove(item.id); // clear on success
            pushed++;
            debugPrint(
              'PUSH ✓ ${item.entityType}/${item.action} id=${item.id} removed from queue',
            );
          } else {
            // Failed push – increment retry counter
            failed++;
            final retries = (_retryCounts[item.id] ?? 0) + 1;
            _retryCounts[item.id] = retries;

            debugPrint(
              'PUSH ✗ FAILED RESPONSE: ${item.entityType}/${item.action} '
              'id=${item.id} data=${item.entityData}',
            );

            if (retries >= _maxRetries) {
              debugPrint(
                'PUSH ✗ ${item.entityType}/${item.action} id=${item.id} '
                'failed $retries times — keeping in queue, will skip until forcePush',
              );
            } else {
              debugPrint(
                'PUSH ✗ ${item.entityType}/${item.action} id=${item.id} '
                '(attempt $retries/$_maxRetries) — will retry next sync',
              );
            }
          }
        } on TimeoutException {
          failed++;
          final retries = (_retryCounts[item.id] ?? 0) + 1;
          _retryCounts[item.id] = retries;
          debugPrint(
            'PUSH ⏱ ${item.entityType}/${item.action} id=${item.id} '
            'TIMEOUT (attempt $retries/$_maxRetries)',
          );
        } catch (e) {
          failed++;
          final retries = (_retryCounts[item.id] ?? 0) + 1;
          _retryCounts[item.id] = retries;
          debugPrint(
            'PUSH ✗ ${item.entityType}/${item.action} id=${item.id} '
            'ERROR: $e (attempt $retries/$_maxRetries)',
          );
        }
      }

      debugPrint(
        'PUSH summary: $pushed pushed, $failed failed, $skipped skipped '
        'out of ${sortedQueue.length} queued items',
      );
    } catch (e) {
      debugPrint('PUSH FATAL ERROR: $e');
    }
  }

  /// Immediately retries ALL queued items regardless of retry count.
  /// Useful when the user manually triggers a refresh.
  Future<void> forcePush() async {
    debugPrint('FORCE PUSH: Resetting retry counters and pushing all items');
    // Reset retry counters so every item gets a fresh attempt
    _retryCounts.clear();
    await pushLocalChanges();

    // IMMEDIATE PULL: After pushing, pull updates from server so other users' content appears quickly
    debugPrint(
      'FORCE PUSH: Triggering immediate pull to get other users\' content',
    );
    await pullRemoteUpdates();

    if (productRepository != null) {
      final dupesRemoved = await productRepository!.repairDisplayDuplicates();
      if (dupesRemoved > 0) {
        debugPrint('FORCE PUSH: removed $dupesRemoved duplicate product row(s)');
        notifyListeners();
      }
    }

    await _updatePendingCount();
  }

  /// Vérifie users + shops sur le serveur après création de boutique.
  /// Relance un push si la boutique manque encore.
  Future<({bool userExists, bool shopExists})> verifyUserAndShopOnServer(
    String phone, {
    int? localShopId,
  }) async {
    var status = await api.verifyUserAndShopOnServer(phone);
    if (localShopId != null && (!status.userExists || !status.shopExists)) {
      debugPrint(
        'VERIFY: retry push (user=${status.userExists} shop=${status.shopExists})',
      );
      await forcePush();
      status = await api.verifyUserAndShopOnServer(phone);
    }
    return status;
  }

  /// Clear all items from the sync queue (use with caution)
  Future<void> clearQueue() async {
    debugPrint('CLEAR QUEUE: Removing all items from sync queue');
    await db.delete(db.syncQueue).go();
    _retryCounts.clear();
    await _updatePendingCount();
    notifyListeners();
  }

  /// Get detailed queue status for debugging
  Future<Map<String, dynamic>> getQueueStatus() async {
    final queue = await db.select(db.syncQueue).get();
    final Map<String, int> entityTypeCounts = {};
    final Map<String, int> actionCounts = {};

    for (var item in queue) {
      entityTypeCounts[item.entityType] =
          (entityTypeCounts[item.entityType] ?? 0) + 1;
      actionCounts[item.action] = (actionCounts[item.action] ?? 0) + 1;
    }

    return {
      'total': queue.length,
      'byEntityType': entityTypeCounts,
      'byAction': actionCounts,
      'items': queue
          .map(
            (item) => {
              'id': item.id,
              'entityType': item.entityType,
              'action': item.action,
              'retries': _retryCounts[item.id] ?? 0,
            },
          )
          .toList(),
    };
  }

  /// Reset sync state and perform a full sync
  Future<void> fullResetAndSync() async {
    debugPrint('FULL RESET: Clearing retry counters and forcing sync');
    _retryCounts.clear();
    _lastSyncTime = null;
    _isFirstSync = true;

    // Reset last sync time in database to force full pull
    try {
      final prefs = await db.select(db.appPreferences).getSingleOrNull();
      if (prefs != null) {
        await db
            .into(db.appPreferences)
            .insertOnConflictUpdate(
              AppPreferencesCompanion(
                id: const Value(1),
                lastSync: const Value.absent(),
              ),
            );
      }
    } catch (e) {
      debugPrint('FULL RESET: Error resetting preferences: $e');
    }

    await syncNow();
  }

  /// Remote IDs with pending local edits in [SyncQueue] — skip server overwrite on pull.
  Future<Set<String>> _pendingRemoteIds(String entityType) async {
    final queue = await db.select(db.syncQueue).get();
    final pending = <String>{};
    for (final item in queue) {
      if (item.entityType != entityType) continue;
      try {
        final data = jsonDecode(item.entityData) as Map<String, dynamic>;
        final remoteId = data['id']?.toString();
        if (remoteId != null && remoteId.isNotEmpty) {
          pending.add(remoteId);
        }
        final localId = data['local_id'] as int?;
        if (localId != null) {
          if (entityType == 'products') {
            final row = await (db.select(
              db.products,
            )..where((t) => t.id.equals(localId))).getSingleOrNull();
            if (row?.remoteId != null && row!.remoteId!.isNotEmpty) {
              pending.add(row.remoteId!);
            }
          } else if (entityType == 'shops') {
            final row = await (db.select(
              db.shops,
            )..where((t) => t.id.equals(localId))).getSingleOrNull();
            if (row?.remoteId != null && row!.remoteId!.isNotEmpty) {
              pending.add(row.remoteId!);
            }
          }
        }
      } catch (_) {}
    }
    return pending;
  }

  Future<List<Map<String, dynamic>>> _fetchProductsPaginated({
    int perPage = 100,
    int? maxPages,
  }) async {
    final all = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final result = await api
          .fetchProductsPaginated(page: page, perPage: perPage)
          .timeout(_requestTimeout);
      final data =
          (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      all.addAll(data);
      final meta = result['meta'] as Map<String, dynamic>?;
      if (maxPages != null && page >= maxPages) break;
      if (meta?['has_more'] != true || data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> _fetchAllProductsPaginated() =>
      _fetchProductsPaginated();

  /// Fix products whose [shopId] stores a server shop id instead of local id.
  Future<int> repairProductShopLinks() async {
    try {
      final shops = await db.select(db.shops).get();
      if (shops.isEmpty) return 0;

      final serverToLocal = <String, int>{};
      final localById = <int, Shop>{};
      for (final shop in shops) {
        localById[shop.id] = shop;
        if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
          serverToLocal[shop.remoteId!] = shop.id;
        }
      }

      final products = await db.select(db.products).get();
      var fixed = 0;
      for (final product in products) {
        final targetLocalId = _targetLocalShopIdForRepair(
          product,
          serverToLocal: serverToLocal,
          localById: localById,
        );
        if (targetLocalId == null || targetLocalId == product.shopId) continue;

        await (db.update(db.products)..where((t) => t.id.equals(product.id)))
            .write(ProductsCompanion(shopId: Value(targetLocalId)));
        fixed++;
      }

      if (fixed > 0) {
        debugPrint('REPAIR: Fixed $fixed product→shop link(s)');
        notifyListeners();
      }
      return fixed;
    } catch (e) {
      debugPrint('REPAIR product shop links error: $e');
      return 0;
    }
  }

  int? _targetLocalShopIdForRepair(
    Product product, {
    required Map<String, int> serverToLocal,
    required Map<int, Shop> localById,
  }) {
    final fromMeta = ProductRepository.readServerShopIdFromProduct(product);
    if (fromMeta != null) {
      return serverToLocal[fromMeta.toString()];
    }

    final serverKey = product.shopId.toString();
    final mapped = serverToLocal[serverKey];
    if (mapped == null) return null;

    final currentShop = localById[product.shopId];
    if (currentShop == null) return mapped;

    final hasRemoteId =
        product.remoteId != null && product.remoteId!.trim().isNotEmpty;
    if (!hasRemoteId) return null;

    if (currentShop.remoteId == serverKey) return null;
    return mapped;
  }

  static String? _mergeProductSyncMetadata(
    String? existingMetadata, {
    required dynamic serverShopId,
  }) {
    if (serverShopId == null) return existingMetadata;

    final parsed = serverShopId is int
        ? serverShopId
        : int.tryParse(serverShopId.toString());
    if (parsed == null) return existingMetadata;

    Map<String, dynamic> meta = {};
    if (existingMetadata != null && existingMetadata.isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(
          jsonDecode(existingMetadata) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    meta[ProductRepository.syncShopIdMetaKey] = parsed;
    return jsonEncode(meta);
  }

  int? _findExistingLocalProductIdForPull({
    required String remoteId,
    required int localShopId,
    required String sanitizedName,
    required double? serverPrice,
    required Map<String, int> productIdMap,
    required List<Product> allProducts,
  }) {
    final mapped = productIdMap[remoteId];
    if (mapped != null) return mapped;

    final normalizedName = sanitizedName.toLowerCase();
    for (final lp in allProducts) {
      if (lp.remoteId != null && lp.remoteId!.isNotEmpty) {
        if (lp.remoteId == remoteId) return lp.id;
        continue;
      }
      if (lp.shopId != localShopId) continue;
      if (lp.name.trim().toLowerCase() != normalizedName) continue;
      if (serverPrice != null &&
          lp.price != null &&
          lp.price!.toStringAsFixed(2) != serverPrice.toStringAsFixed(2)) {
        continue;
      }
      return lp.id;
    }
    return null;
  }

  int _resolveLocalShopIdForProduct(
    Map<String, dynamic> product,
    Map<String, int> shopIdMap,
    List<Shop> localShops,
  ) {
    final serverShopId =
        (product['shop_id'] ?? product['shop_remote_id'])?.toString() ?? '';
    if (serverShopId.isEmpty) return 0;

    final mapped = shopIdMap[serverShopId];
    if (mapped != null && mapped > 0) return mapped;

    for (final shop in localShops) {
      if (shop.remoteId == serverShopId) return shop.id;
    }

    return 0;
  }

  int? _findExistingLocalShopIdForPull(
    Map<String, dynamic> serverShop,
    String remoteId,
    Map<String, int> shopIdMap,
    Map<String, int> ownerIdToLocalShopId,
  ) {
    final fromRemote = shopIdMap[remoteId];
    if (fromRemote != null) return fromRemote;

    for (final key in PhoneUtils.lookupKeys(
      serverShop['owner_id']?.toString(),
    )) {
      final localId = ownerIdToLocalShopId[key];
      if (localId != null) return localId;
    }

    // Do not match by shop phone/whatsapp — contact numbers are not owner identity
    // and merging here caused one seller's products to appear on another's profile.
    return null;
  }

  void _registerOwnerShopKeys(Map<String, int> map, Shop shop) {
    if (shop.remoteId != null && shop.remoteId!.isNotEmpty) return;
    for (final key in PhoneUtils.lookupKeys(shop.ownerId)) {
      map.putIfAbsent(key, () => shop.id);
    }
  }

  Future<void> _pullInsertShops({
    required List<Map<String, dynamic>> remoteShops,
    required Map<String, int> shopIdMap,
    required Map<String, int> ownerIdToLocalShopId,
    required Map<int, Shop> localShopById,
    required Set<String> pendingShopRemoteIds,
    required bool fullSync,
  }) async {
    final serverRemoteIds = <String>{};
    for (var s in remoteShops) {
      final dynamic rawRemoteId = s['remote_id'];
      final String rId =
          rawRemoteId != null && rawRemoteId.toString().isNotEmpty
          ? rawRemoteId.toString()
          : (s['id']?.toString() ?? '');
      if (rId.isNotEmpty) {
        serverRemoteIds.add(rId);
      }
    }

    if (fullSync) {
      final allLocalShops = await db.select(db.shops).get();
      for (var localShop in allLocalShops) {
        if (localShop.remoteId != null &&
            localShop.remoteId!.isNotEmpty &&
            !serverRemoteIds.contains(localShop.remoteId)) {
          await (db.delete(
            db.shops,
          )..where((t) => t.id.equals(localShop.id))).go();
          debugPrint(
            'Sync: Removed deleted shop ${localShop.name} (remoteId: ${localShop.remoteId})',
          );
        }
      }
    }

    await db.batch((batch) {
      for (var s in remoteShops) {
        final dynamic rawRemoteId = s['remote_id'];
        final String rId =
            rawRemoteId != null && rawRemoteId.toString().isNotEmpty
            ? rawRemoteId.toString()
            : (s['id']?.toString() ?? '');
        if (rId.isNotEmpty && pendingShopRemoteIds.contains(rId)) {
          continue;
        }
        final String rawName = s['name'] as String? ?? '';
        final String sanitizedName = rawName.trim().isEmpty
            ? 'Boutique'
            : rawName;
        final int? existingLocalId = _findExistingLocalShopIdForPull(
          s,
          rId,
          shopIdMap,
          ownerIdToLocalShopId,
        );
        final Shop? existingShop = existingLocalId != null
            ? localShopById[existingLocalId]
            : null;
        final rawOwner = s['owner_id']?.toString();
        final normalizedOwner = rawOwner == null || rawOwner.isEmpty
            ? null
            : (PhoneUtils.normalizeDrc(rawOwner).isNotEmpty
                  ? PhoneUtils.normalizeDrc(rawOwner)
                  : rawOwner);

        batch.insert(
          db.shops,
          ShopsCompanion.insert(
            id: existingLocalId != null
                ? Value(existingLocalId)
                : const Value.absent(),
            remoteId: Value(rId),
            name: sanitizedName,
            description: Value(s['description'] as String?),
            logoUrl: Value(
              _mergeMediaUrlForLocal(
                _coerceMediaField(s['logo_url']),
                existingShop?.logoUrl,
              ),
            ),
            type: ShopType.values.firstWhere(
              (e) => e.name == s['type'],
              orElse: () => ShopType.retail,
            ),
            ownerId: Value(normalizedOwner),
            address: Value(s['address'] as String?),
            whatsapp: Value(_normalizeShopPhone(s['whatsapp'] as String?)),
            phone: Value(_normalizeShopPhone(s['phone'] as String?)),
            email: Value(s['email'] as String?),
            instagramUrl: Value(s['instagram_url'] as String?),
            tiktokUrl: Value(s['tiktok_url'] as String?),
            facebookUrl: Value(s['facebook_url'] as String?),
            youtubeUrl: Value(s['youtube_url'] as String?),
            bannerUrl: Value(
              _mergeMediaUrlForLocal(
                _coerceMediaField(s['banner_url']),
                existingShop?.bannerUrl,
              ),
            ),
            boostStatus: Value(_toInt(s['boost_status']) ?? 0),
            bannerStatus: Value(_toInt(s['banner_status']) ?? 0),
            bannerText: Value(s['banner_text'] as String?),
            videoUrl: Value(
              _mergeMediaUrlForLocal(
                _coerceMediaField(s['video_url']),
                existingShop?.videoUrl,
              ),
            ),
            isBoosted: Value(_toBool(s['is_boosted'])),
            isVerified: Value(_toBool(s['is_verified'])),
            verifiedAt: Value(
              DateTime.tryParse(s['verified_at']?.toString() ?? ''),
            ),
            city: Value(s['city'] as String?),
            commune: Value(s['commune'] as String?),
            latitude: Value(_toDouble(s['latitude'])),
            longitude: Value(_toDouble(s['longitude'])),
            lastActiveAt: Value(
              DateTime.tryParse(s['last_active_at']?.toString() ?? ''),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    debugPrint('Sync: Synced ${remoteShops.length} shops from server');
  }

  Future<List<Map<String, dynamic>>> _fetchShopsPaginated({
    int perPage = 100,
    int? maxPages,
  }) async {
    final all = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final result = await api
          .fetchShopsPaginated(page: page, perPage: perPage)
          .timeout(_requestTimeout);
      final data =
          (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      all.addAll(data);
      final meta = result['meta'] as Map<String, dynamic>?;
      if (maxPages != null && page >= maxPages) break;
      if (meta?['has_more'] != true || data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> _fetchAllShopsPaginated() =>
      _fetchShopsPaginated();

  Future<void> pullRemoteUpdates({bool catalogPreview = false}) async {
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
      final bool fullSync = _isFirstSync || lastSyncTime == null;
      final DateTime? updatedSince =
          fullSync ? null : lastSyncTime.subtract(const Duration(minutes: 1));

      final pendingProductRemoteIds = await _pendingRemoteIds('products');
      final pendingShopRemoteIds = await _pendingRemoteIds('shops');

      // ── PHASE 1: categories, shops, then products ───────────────────────
      List<Map<String, dynamic>> remoteCategories = [];
      List<Map<String, dynamic>> remoteProducts = [];
      List<Map<String, dynamic>> remoteShops = [];
      var productsPullOk = false;
      var shopsPullOk = false;

      try {
        // Categories: always full fetch (small payload, deletion detection)
        remoteCategories = await api.fetchCategories().timeout(_requestTimeout);
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: categories');
      } catch (e) {
        debugPrint('PULL ERROR (categories): $e');
      }

      // Shops: full fetch, or limited pages on first-launch preview.
      try {
        remoteShops = catalogPreview && fullSync
            ? await _fetchShopsPaginated(maxPages: _previewShopPages)
            : await _fetchAllShopsPaginated();
        shopsPullOk = true;
        debugPrint(
          'PULL: shops (${catalogPreview ? "preview" : "full paginated"}) '
          '→ ${remoteShops.length}',
        );
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: shops (phase 1)');
        try {
          remoteShops = await api
              .fetchShops(updatedSince: updatedSince)
              .timeout(_requestTimeout);
          shopsPullOk = remoteShops.isNotEmpty;
          debugPrint(
            'PULL: shops fallback (incremental) → ${remoteShops.length}',
          );
        } catch (e) {
          debugPrint('PULL ERROR (shops fallback): $e');
        }
      } catch (e) {
        debugPrint('PULL ERROR (shops phase 1): $e');
      }

      try {
        if (fullSync) {
          remoteProducts = catalogPreview
              ? await _fetchProductsPaginated(
                  maxPages: _previewProductPages,
                  perPage: _previewProductsPerPage,
                )
              : await _fetchAllProductsPaginated();
        } else {
          remoteProducts = await api
              .fetchProducts(updatedSince: updatedSince)
              .timeout(_requestTimeout);
        }
        productsPullOk = true;
        debugPrint(
          'PULL: products (${fullSync ? "full" : "incremental"}) '
          '→ ${remoteProducts.length}',
        );
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: products');
      } catch (e) {
        debugPrint('PULL ERROR (products): $e');
      }

      // Build a map of remoteId -> localId for shops to resolve product relationships
      var allShops = await db.select(db.shops).get();
      var localShopById = <int, Shop>{
        for (final shop in allShops) shop.id: shop,
      };
      final Map<String, int> shopIdMap = {};
      for (final s in allShops) {
        if (s.remoteId != null && s.remoteId!.isNotEmpty) {
          shopIdMap[s.remoteId!] = s.id;
        }
      }

      // Build owner_id -> localId map for shops that have no remoteId yet,
      // so the pull phase can update them in-place instead of creating duplicates.
      final Map<String, int> ownerIdToLocalShopId = {};
      for (final s in allShops) {
        _registerOwnerShopKeys(ownerIdToLocalShopId, s);
      }

      // Build a comprehensive map of remoteId -> localId from ALL existing
      // products to prevent any duplication during pull sync.
      final allProducts = await db.select(db.products).get();
      final Map<int, Product> localProductById = {
        for (final product in allProducts) product.id: product,
      };
      final Map<String, int> productIdMap = {};
      for (final p in allProducts) {
        final rId = p.remoteId;
        if (rId != null && rId.isNotEmpty) {
          productIdMap[rId] = p.id;
        }
      }

      // Build a map of remoteId -> localId for existing categories
      final allCategories = await db.select(db.categories).get();
      final Map<String, int> categoryIdMap = {};
      for (final c in allCategories) {
        final rId = c.remoteId;
        if (rId != null && rId.isNotEmpty) {
          categoryIdMap[rId] = c.id;
        }
      }

      // Build a map of remote_id -> category data to calculate correct levels
      final Map<String, Map<String, dynamic>> remoteCatMap = {};
      for (var cat in remoteCategories) {
        final dynamic rawRemoteId = cat['remote_id'];
        final String rId =
            rawRemoteId != null && rawRemoteId.toString().isNotEmpty
            ? rawRemoteId.toString()
            : (cat['id']?.toString() ?? '');
        remoteCatMap[rId] = cat;
      }

      // Calculate correct levels based on parent-child relationships
      final Map<String, int> calculatedLevels = {};
      for (var entry in remoteCatMap.entries) {
        final rId = entry.key;
        final cat = entry.value;
        final parentId = cat['parent_id'];
        if (parentId == null) {
          calculatedLevels[rId] = 0;
        }
      }

      // Iteratively calculate levels
      bool changed = true;
      int maxIterations = 10;
      while (changed && maxIterations > 0) {
        changed = false;
        maxIterations--;
        for (var entry in remoteCatMap.entries) {
          final rId = entry.key;
          final cat = entry.value;
          if (calculatedLevels.containsKey(rId)) continue;

          final dynamic rawParentId = cat['parent_id'];
          if (rawParentId == null) {
            calculatedLevels[rId] = 0;
            changed = true;
            continue;
          }

          final String parentRemoteId = rawParentId.toString();
          if (calculatedLevels.containsKey(parentRemoteId)) {
            calculatedLevels[rId] = calculatedLevels[parentRemoteId]! + 1;
            changed = true;
          }
        }
      }

      // Sync shops BEFORE products so shop_id mapping is correct.
      if (shopsPullOk && remoteShops.isNotEmpty) {
        await _pullInsertShops(
          remoteShops: remoteShops,
          shopIdMap: shopIdMap,
          ownerIdToLocalShopId: ownerIdToLocalShopId,
          localShopById: localShopById,
          pendingShopRemoteIds: pendingShopRemoteIds,
          fullSync: fullSync,
        );
        allShops = await db.select(db.shops).get();
        localShopById
          ..clear()
          ..addAll({for (final shop in allShops) shop.id: shop});
        shopIdMap.clear();
        for (final s in allShops) {
          if (s.remoteId != null && s.remoteId!.isNotEmpty) {
            shopIdMap[s.remoteId!] = s.id;
          }
        }
        ownerIdToLocalShopId.clear();
        for (final s in allShops) {
          _registerOwnerShopKeys(ownerIdToLocalShopId, s);
        }
        debugPrint(
          'PULL: shopIdMap ready with ${shopIdMap.length} entries for products',
        );
      } else if (!shopsPullOk) {
        debugPrint(
          'PULL WARNING: shops pull failed — products may be skipped',
        );
      }

      // Remove local products deleted on the server (every successful pull)
      if (productsPullOk) {
        final serverProductRemoteIds = <String>{};
        for (var p in remoteProducts) {
          final dynamic rawRemoteId = p['remote_id'];
          final String rId =
              rawRemoteId != null && rawRemoteId.toString().isNotEmpty
              ? rawRemoteId.toString()
              : (p['id']?.toString() ?? '');
          if (rId.isNotEmpty) {
            serverProductRemoteIds.add(rId);
          }
        }
        final purgedProducts = await _purgeOrphanedLocalProducts(
          serverProductRemoteIds,
          pendingRemoteIds: pendingProductRemoteIds,
        );
        if (purgedProducts > 0) {
          notifyListeners();
        }
      }

      // Batch-insert categories & products immediately so the UI can render
      if (remoteCategories.isNotEmpty || remoteProducts.isNotEmpty) {
        // Deletion sync only on full pull (incremental lists are partial)
        if (fullSync && remoteCategories.isNotEmpty) {
          final serverCategoryRemoteIds = <String>{};
          for (var cat in remoteCategories) {
            final dynamic rawRemoteId = cat['remote_id'];
            final String rId =
                rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                ? rawRemoteId.toString()
                : (cat['id']?.toString() ?? '');
            if (rId.isNotEmpty) {
              serverCategoryRemoteIds.add(rId);
            }
          }

          for (var localCat in allCategories) {
            if (localCat.remoteId != null &&
                localCat.remoteId!.isNotEmpty &&
                !serverCategoryRemoteIds.contains(localCat.remoteId)) {
              await (db.delete(
                db.categories,
              )..where((t) => t.id.equals(localCat.id))).go();
              debugPrint(
                'Sync: Removed deleted category ${localCat.name} (remoteId: ${localCat.remoteId})',
              );
            }
          }
        }

        final skippedProducts = <Map<String, dynamic>>[];

        await db.batch((batch) {
          for (var cat in remoteCategories) {
            // Use remote_id if available, otherwise use id as fallback
            final dynamic rawRemoteId = cat['remote_id'];
            final String rId =
                rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                ? rawRemoteId.toString()
                : (cat['id']?.toString() ?? '');
            final int? existingLocalId = categoryIdMap[rId];

            // Use calculated level if available, otherwise fall back to server value
            final int calculatedLevel =
                calculatedLevels[rId] ?? (_toInt(cat['level']) ?? 0);

            batch.insert(
              db.categories,
              CategoriesCompanion(
                id: existingLocalId != null
                    ? Value(existingLocalId)
                    : const Value.absent(),
                remoteId: Value(rId),
                name: Value(cat['name'] as String? ?? 'Sans nom'),
                icon: Value(cat['icon'] as String?),
                level: Value(calculatedLevel),
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

          for (var p in remoteProducts) {
            // Use remote_id if available, otherwise use id as fallback
            final dynamic rawRemoteId = p['remote_id'];
            final String rId =
                rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                ? rawRemoteId.toString()
                : (p['id']?.toString() ?? '');
            if (rId.isNotEmpty && pendingProductRemoteIds.contains(rId)) {
              continue;
            }
            final String rawName = p['name'] as String? ?? '';
            final String sanitizedName = rawName.trim().isEmpty
                ? 'Produit'
                : rawName;

            final int localShopId = _resolveLocalShopIdForProduct(
              p,
              shopIdMap,
              allShops,
            );
            if (localShopId <= 0) {
              debugPrint(
                'Sync: skip product ${p['name']} — shop_id ${p['shop_id']} not mapped locally',
              );
              skippedProducts.add(p);
              continue;
            }

            final serverPrice = (p['price'] as num?)?.toDouble();
            final existingLocalId = _findExistingLocalProductIdForPull(
              remoteId: rId,
              localShopId: localShopId,
              sanitizedName: sanitizedName,
              serverPrice: serverPrice,
              productIdMap: productIdMap,
              allProducts: allProducts,
            );
            if (existingLocalId != null) {
              productIdMap[rId] = existingLocalId;
            }
            final Product? existingProduct = existingLocalId != null
                ? localProductById[existingLocalId]
                : null;

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
                imageUrls: Value(
                  _mergeImageUrlsForLocal(
                    _coerceMediaField(p['image_urls']),
                    existingProduct?.imageUrls,
                  ),
                ),
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
                metadata: Value(
                  _mergeProductSyncMetadata(
                    p['metadata'] as String?,
                    serverShopId: p['shop_id'],
                  ),
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });

        if (skippedProducts.isNotEmpty && shopsPullOk) {
          final retried = await _retrySkippedProducts(
            skippedProducts,
            pendingProductRemoteIds: pendingProductRemoteIds,
          );
          if (retried > 0) {
            debugPrint('PULL: retried $retried product(s) after shop sync');
          }
        }

        // Update catalog flags once products are available locally.
        if (remoteProducts.isNotEmpty) {
          _hasLocalCatalog = true;
          if (!catalogPreview) {
            _isFirstSync = false;
          }
        }

        // Small delay to let the DB transaction fully settle before the UI
        // reads the new state — prevents momentary duplicate flickering.
        await Future.delayed(const Duration(milliseconds: 50));

        // Notify UI immediately — categories & products are ready
        notifyListeners();

        if (catalogPreview) {
          debugPrint(
            'PULL: catalog preview done (${remoteProducts.length} products) '
            '— full sync continues in background',
          );
          return;
        }
      }

      // ── PHASE 2: stories ───────────────────────────────────────────────
      List<Map<String, dynamic>> remoteStories = [];
      var storiesPullOk = false;

      try {
        final fetched = await api
            .fetchStories(updatedSince: updatedSince)
            .timeout(_requestTimeout);
        if (fetched != null) {
          remoteStories = fetched;
          storiesPullOk = true;
        } else {
          debugPrint('PULL: stories fetch failed (non-200 or network error)');
        }
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: stories');
      } catch (e) {
        debugPrint('PULL ERROR (stories): $e');
      }

      // Pre-check story deduplication and build conflict resolution map before batch insert
      final existingStoryRemoteIds = <String>{};
      final Map<String, Story> existingStoriesByRemoteId = {};
      final Map<String, DateTime> storyTimestamps = {};
      if (remoteStories.isNotEmpty) {
        final remoteIds = remoteStories
            .map((st) {
              // Use remote_id if available, otherwise use id as fallback
              final dynamic rawRemoteId = st['remote_id'];
              return rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                  ? rawRemoteId.toString()
                  : (st['id']?.toString() ?? '');
            })
            .where((id) => id.isNotEmpty)
            .toList();
        if (remoteIds.isNotEmpty) {
          final existingStories = await (db.select(
            db.stories,
          )..where((t) => t.remoteId.isIn(remoteIds))).get();
          for (final story in existingStories) {
            if (story.remoteId != null && story.remoteId!.isNotEmpty) {
              existingStoryRemoteIds.add(story.remoteId!);
              existingStoriesByRemoteId[story.remoteId!] = story;
              storyTimestamps[story.remoteId!] = story.createdAt;
            }
          }
        }
      }

      // Refresh shopIdMap after shops are committed so stories can resolve shop IDs
      // (critical for first-sync where new shops were not in the original map)
      {
        final freshShops = await db.select(db.shops).get();
        for (var s in freshShops) {
          if (s.remoteId != null && s.remoteId!.isNotEmpty) {
            shopIdMap[s.remoteId!] = s.id;
          }
          // Also map by ownerId for fallback lookups
          if (s.ownerId != null && s.ownerId!.isNotEmpty) {
            shopIdMap['owner:${s.ownerId}'] = s.id;
          }
          // Also map by shop name for fallback lookups
          shopIdMap['name:${s.name}'] = s.id;
        }
      }

      // Build a comprehensive shop lookup map BEFORE the batch insert
      // This includes remote_id, owner_id, and name-based lookups
      final Map<String, int> comprehensiveShopMap = Map.from(shopIdMap);

      // Pre-load all shops for quick lookup during story sync
      final allShopsForStorySync = await db.select(db.shops).get();
      for (var shop in allShopsForStorySync) {
        if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
          comprehensiveShopMap[shop.remoteId!] = shop.id;
        }
        if (shop.ownerId != null && shop.ownerId!.isNotEmpty) {
          comprehensiveShopMap['owner:${shop.ownerId}'] = shop.id;
        }
        comprehensiveShopMap['name:${shop.name}'] = shop.id;
      }

      // ── PHASE 2b: sync stories using the refreshed shopIdMap ────────────
      if (storiesPullOk) {
        // Build a set of remote IDs that exist on the server
        final serverStoryRemoteIds = <String>{};
        for (var st in remoteStories) {
          final dynamic rawRemoteId = st['remote_id'];
          final String rId =
              rawRemoteId != null && rawRemoteId.toString().isNotEmpty
              ? rawRemoteId.toString()
              : (st['id']?.toString() ?? '');
          if (rId.isNotEmpty) {
            serverStoryRemoteIds.add(rId);
          }
        }

        // Only purge when we have a confirmed server snapshot.
        // Never wipe local arrivages on an empty list during incremental sync
        // (transient API issues used to delete everything after logout).
        if (fullSync || remoteStories.isNotEmpty) {
          final purgedStories = await _purgeOrphanedLocalStories(
            serverStoryRemoteIds,
          );
          if (purgedStories > 0) {
            notifyListeners();
          }
        }
      }

      if (remoteStories.isNotEmpty) {
        final deletedStoryRemoteIds = await _loadDeletedStoryRemoteIds();
        // INCREMENTAL UPSERT: Only insert/update new or changed stories
        // Avoid re-inserting existing stories to preserve UI state
        await db.batch((batch) {
          for (var st in remoteStories) {
            // Use remote_id if available, otherwise use id as fallback
            final dynamic rawRemoteId = st['remote_id'];
            final String rId =
                rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                ? rawRemoteId.toString()
                : (st['id']?.toString() ?? '');

            if (rId.isNotEmpty && deletedStoryRemoteIds.contains(rId)) {
              continue;
            }

            // Skip if story already exists and hasn't changed (dedup optimization)
            if (rId.isNotEmpty && existingStoryRemoteIds.contains(rId)) {
              continue;
            }

            // Parse server timestamps for conflict resolution
            final DateTime? serverCreatedAt = DateTime.tryParse(
              st['created_at'] as String? ?? '',
            );
            final DateTime? serverUpdatedAt = DateTime.tryParse(
              st['updated_at'] as String? ?? st['created_at'] as String? ?? '',
            );
            final serverTimestamp = serverUpdatedAt ?? serverCreatedAt;

            // Map server shop_id to local shop id using comprehensive lookup
            // Try multiple strategies: remote_id, owner_id, shop_name
            final String serverShopId = (st['shop_id'])?.toString() ?? '';
            int localShopId = comprehensiveShopMap[serverShopId] ?? 0;

            // Fallback 1: Try owner_id from the story data
            if (localShopId == 0) {
              final String? storyOwnerId = st['owner_id']?.toString();
              if (storyOwnerId != null && storyOwnerId.isNotEmpty) {
                localShopId = comprehensiveShopMap['owner:$storyOwnerId'] ?? 0;
                if (localShopId != 0) {
                  debugPrint(
                    'Story sync: Found shop by owner_id fallback - localShopId=$localShopId',
                  );
                }
              }
            }

            // Fallback 2: Try shop_name from the story data
            if (localShopId == 0) {
              final String? shopName = st['shop_name']?.toString();
              if (shopName != null && shopName.isNotEmpty) {
                localShopId = comprehensiveShopMap['name:$shopName'] ?? 0;
                if (localShopId != 0) {
                  debugPrint(
                    'Story sync: Found shop by name fallback - localShopId=$localShopId',
                  );
                }
              }
            }

            if (localShopId == 0) {
              debugPrint(
                'Story sync: ERROR - could not map shop ID for story $rId, '
                'server shop ID: $serverShopId, '
                'owner_id: ${st['owner_id']}, '
                'shop_name: ${st['shop_name']}, '
                'skipping story',
              );
              continue; // Skip this story to avoid orphaned records
            }

            // Conflict resolution: last-write-wins based on timestamps
            if (rId.isNotEmpty && storyTimestamps.containsKey(rId)) {
              final localCreatedAt = storyTimestamps[rId]!;

              // Skip if local version is newer
              if (serverTimestamp != null &&
                  localCreatedAt.isAfter(serverTimestamp)) {
                debugPrint(
                  'Story sync: skipping update for story $rId - local version is newer '
                  '(local: $localCreatedAt, remote: $serverTimestamp)',
                );
                continue;
              }
            }

            final String rawMediaUrl = st['media_url'] as String? ?? '';
            final String? storedMediaUrl = _mergeMediaUrlForLocal(
              rawMediaUrl,
              null,
            );

            // INSERT OR REPLACE to handle both new and updated stories
            batch.insert(
              db.stories,
              StoriesCompanion.insert(
                remoteId: Value(rId),
                shopId: localShopId,
                mediaUrl: storedMediaUrl ?? '',
                mediaType: st['media_type'] as String? ?? 'image',
                isArrivage: Value((_toInt(st['is_arrivage']) ?? 0) == 1),
                expiresAt:
                    DateTime.tryParse(st['expires_at'] as String? ?? '') ??
                    DateTime.now().add(const Duration(days: 7)),
                createdAt: Value(serverCreatedAt ?? DateTime.now()),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }

      // Sync story_media items after stories are inserted
      // (We need the auto-generated local story IDs)
      // OPTIMIZED: Only update media for NEW or CHANGED stories to avoid UI flickering
      if (remoteStories.isNotEmpty) {
        try {
          for (var st in remoteStories) {
            if (st['media_items'] is! List) continue;
            // Use remote_id if available, otherwise use id as fallback
            final dynamic rawRemoteId = st['remote_id'];
            final String rId =
                rawRemoteId != null && rawRemoteId.toString().isNotEmpty
                ? rawRemoteId.toString()
                : (st['id']?.toString() ?? '');
            if (rId.isEmpty) continue;

            // Find the local story by remoteId
            final localStory = await (db.select(
              db.stories,
            )..where((t) => t.remoteId.equals(rId))).getSingleOrNull();
            if (localStory == null) continue;

            // Only delete and re-insert media for NEW stories
            // This prevents breaking image links for existing stories
            final existingMedia = await (db.select(
              db.storyMedia,
            )..where((t) => t.storyId.equals(localStory.id))).get();

            if (existingMedia.isEmpty) {
              // Only insert if no media exists yet (new story)
              for (var mi in st['media_items'] as List) {
                final mediaItem = mi as Map<String, dynamic>;
                final rawMediaUrl = mediaItem['media_url'] as String? ?? '';
                final storedMediaUrl =
                    _normalizeServerMedia(rawMediaUrl) ?? '';
                await db
                    .into(db.storyMedia)
                    .insert(
                      StoryMediaCompanion.insert(
                        storyId: localStory.id,
                        mediaUrl: storedMediaUrl,
                        mediaType: Value(
                          mediaItem['media_type'] as String? ?? 'image',
                        ),
                        sortOrder: Value(mediaItem['sort_order'] as int? ?? 0),
                      ),
                    );
              }
            }
          }
        } catch (e) {
          debugPrint('STORY_MEDIA SYNC ERROR: $e');
        }
      }

      if (remoteStories.isNotEmpty && existingStoriesByRemoteId.isNotEmpty) {
        await _repairExistingStoriesFromServer(
          remoteStories,
          existingStoriesByRemoteId,
        );
      }
      await _repairMisclassifiedArrivages();

      debugPrint(
        "Boutiques: ${remoteShops.length}, Produits: ${remoteProducts.length} synchronisés.",
      );

      await repairProductShopLinks();
      if (productRepository != null) {
        final dupesRemoved = await productRepository!.repairDisplayDuplicates();
        if (dupesRemoved > 0) {
          debugPrint(
            'Sync: removed $dupesRemoved duplicate local product row(s)',
          );
        }
      }
      await _repairMediaUrlsFromServer();
      await _pullRemoteOrders(updatedSince: updatedSince);
      await _pullRemoteDeliveries(updatedSince: updatedSince);
      await _pullProductUpdates(updatedSince: updatedSince);
      final purged = await TestDataCleanup.purgeLocal(db);
      if (purged > 0) {
        debugPrint('TestDataCleanup: removed $purged local test records');
      }
      unawaited(_prefetchPriorityMedia());

      // Update last sync time
      await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
        AppPreferencesCompanion(lastSync: Value(DateTime.now())),
      );
      _isFirstSync = false;

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

  static String? _normalizeShopPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = PhoneUtils.normalizeDrc(value);
    return PhoneUtils.isValidDrc(normalized) ? normalized : null;
  }

  static String? _plainMediaUrl(String? value) {
    if (value == null || value.isEmpty) return value;
    final decrypted = CryptoUtils.decrypt(value);
    if (decrypted.startsWith('http://') ||
        decrypted.startsWith('https://') ||
        decrypted.startsWith('data:image')) {
      return decrypted;
    }
    return value;
  }

  /// Keep server media URLs in plain form (same as MySQL).
  static String? _normalizeServerMedia(String? value) {
    if (ImageUtils.isEmptyMediaValue(value)) return null;
    return value!.trim();
  }

  static String? _coerceMediaField(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      if (value.isEmpty) return null;
      return jsonEncode(value);
    }
    if (value is String) {
      return ImageUtils.isEmptyMediaValue(value) ? null : value.trim();
    }
    final asString = value.toString().trim();
    return ImageUtils.isEmptyMediaValue(asString) ? null : asString;
  }

  static String _mergeImageUrlsForLocal(String? remote, String? existing) {
    final fromServer = _normalizeServerMedia(remote);
    if (fromServer != null) return fromServer;
    return existing ?? '';
  }

  static String? _mergeMediaUrlForLocal(String? remote, String? existing) {
    final fromServer = _normalizeServerMedia(remote);
    if (fromServer != null) return fromServer;
    if (existing != null && existing.isNotEmpty) return existing;
    return null;
  }

  /// Warm disk cache from local DB — call on startup so images survive restarts.
  Future<void> warmMediaCache() => _prefetchPriorityMedia(force: true);

  Future<void> _repairMediaUrlsFromServer() async {
    if (!isOnline) return;

    try {
      final remoteProducts = await _fetchAllProductsPaginated();
      final remoteShops = await _fetchAllShopsPaginated();
      final localProducts = await db.select(db.products).get();
      final localShops = await db.select(db.shops).get();

      final productByRemoteId = <String, Product>{
        for (final product in localProducts)
          if (product.remoteId != null && product.remoteId!.isNotEmpty)
            product.remoteId!: product,
      };
      final shopByRemoteId = <String, Shop>{
        for (final shop in localShops)
          if (shop.remoteId != null && shop.remoteId!.isNotEmpty)
            shop.remoteId!: shop,
      };

      var repaired = 0;

      await db.batch((batch) {
        for (final remote in remoteProducts) {
          final dynamic rawRemoteId = remote['remote_id'];
          final rId = rawRemoteId != null && rawRemoteId.toString().isNotEmpty
              ? rawRemoteId.toString()
              : (remote['id']?.toString() ?? '');
          if (rId.isEmpty) continue;

          final local = productByRemoteId[rId];
          if (local == null) continue;

          final remoteImages =
              _normalizeServerMedia(remote['image_urls'] as String?);
          if (remoteImages == null || local.imageUrls == remoteImages) {
            continue;
          }
          if (ImageUtils.hasDisplayableImage(local.imageUrls) &&
              !ImageUtils.hasDisplayableImage(remoteImages)) {
            continue;
          }

          batch.update(
            db.products,
            ProductsCompanion(imageUrls: Value(remoteImages)),
            where: (t) => t.id.equals(local.id),
          );
          repaired++;
        }

        for (final remote in remoteShops) {
          final dynamic rawRemoteId = remote['remote_id'];
          final rId = rawRemoteId != null && rawRemoteId.toString().isNotEmpty
              ? rawRemoteId.toString()
              : (remote['id']?.toString() ?? '');
          if (rId.isEmpty) continue;

          final local = shopByRemoteId[rId];
          if (local == null) continue;

          final remoteLogo =
              _normalizeServerMedia(remote['logo_url'] as String?);
          final remoteBanner =
              _normalizeServerMedia(remote['banner_url'] as String?);
          final remoteVideo =
              _normalizeServerMedia(remote['video_url'] as String?);

          final logoNeedsUpdate =
              remoteLogo != null && local.logoUrl != remoteLogo;
          final bannerNeedsUpdate =
              remoteBanner != null && local.bannerUrl != remoteBanner;
          final videoNeedsUpdate =
              remoteVideo != null && local.videoUrl != remoteVideo;

          if (!logoNeedsUpdate && !bannerNeedsUpdate && !videoNeedsUpdate) {
            continue;
          }

          batch.update(
            db.shops,
            ShopsCompanion(
              logoUrl: logoNeedsUpdate
                  ? Value(remoteLogo)
                  : const Value.absent(),
              bannerUrl: bannerNeedsUpdate
                  ? Value(remoteBanner)
                  : const Value.absent(),
              videoUrl: videoNeedsUpdate
                  ? Value(remoteVideo)
                  : const Value.absent(),
            ),
            where: (t) => t.id.equals(local.id),
          );
          repaired++;
        }
      });

      if (repaired > 0) {
        debugPrint('MEDIA REPAIR: refreshed $repaired records from server');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MEDIA REPAIR ERROR: $e');
    }
  }

  /// Prefetch only recent/visible media — skips files already cached.
  Future<void> _prefetchPriorityMedia({bool force = false}) async {
    if (liteMode && !force) return;
    if (!force &&
        _lastMediaPrefetch != null &&
        DateTime.now().difference(_lastMediaPrefetch!) <
            _mediaPrefetchCooldown) {
      return;
    }
    _lastMediaPrefetch = DateTime.now();

    try {
      final now = DateTime.now();
      final products = await (db.select(db.products)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(_priorityProductPrefetch))
          .get();
      final shops = await (db.select(db.shops)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(_priorityShopPrefetch))
          .get();
      final stories = await (db.select(db.stories)
            ..where((t) => t.expiresAt.isBiggerThanValue(now))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(_priorityStoryPrefetch))
          .get();

      final sources = <String?>[
        ...products.map((product) => product.imageUrls),
        ...shops.map((shop) => shop.logoUrl),
        ...shops.map((shop) => shop.bannerUrl),
        ...stories.map((story) => story.mediaUrl),
      ];

      await ImageUtils.prefetchUrls(
        sources,
        maxUrls: 80,
        concurrency: 6,
        skipCached: true,
      );
      debugPrint(
        'MEDIA PREFETCH: warmed up to ${sources.length} priority sources',
      );
    } catch (e) {
      debugPrint('Local media prefetch failed: $e');
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  Future<void> addToQueue(
    String action,
    String entityType,
    Map<String, dynamic> data,
  ) async {
    if (entityType == 'products' &&
        action == 'UPDATE' &&
        data['id'] == null) {
      final localId = data['local_id'] as int?;
      if (localId != null) {
        final merged = await _mergeIntoPendingProductCreate(localId, data);
        if (merged) {
          debugPrint(
            'QUEUE: merged products/UPDATE into pending CREATE '
            'for local_id=$localId',
          );
          await _updatePendingCount();
          return;
        }
      }
    }

    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            action: action,
            entityType: entityType,
            entityData: jsonEncode(data),
          ),
        );
    await _updatePendingCount();
  }

  /// When images finish uploading after a local CREATE, fold UPDATE fields
  /// into the pending CREATE row instead of enqueueing a second server write.
  Future<bool> _mergeIntoPendingProductCreate(
    int localId,
    Map<String, dynamic> updates,
  ) async {
    final queue = await db.select(db.syncQueue).get();
    for (final item in queue) {
      if (item.entityType != 'products' || item.action != 'CREATE') continue;
      try {
        final existing =
            jsonDecode(item.entityData) as Map<String, dynamic>;
        if (existing['local_id'] != localId) continue;

        final merged = Map<String, dynamic>.from(existing);
        for (final entry in updates.entries) {
          if (entry.key == 'local_id' || entry.key == 'id') continue;
          merged[entry.key] = entry.value;
        }

        await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
            .write(SyncQueueCompanion(entityData: Value(jsonEncode(merged))));
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Inject server [id] from local [remoteId]; defer UPDATE until CREATE lands.
  Future<Map<String, dynamic>?> _prepareProductPushPayload(
    String action,
    Map<String, dynamic> data,
  ) async {
    final localId = data['local_id'] as int?;
    if (localId != null) {
      final row = await (db.select(db.products)
            ..where((t) => t.id.equals(localId)))
          .getSingleOrNull();
      final remoteId = row?.remoteId;
      if ((data['id'] == null || '${data['id']}'.isEmpty) &&
          remoteId != null &&
          remoteId.isNotEmpty) {
        final parsed = int.tryParse(remoteId);
        if (parsed != null) {
          data['id'] = parsed;
        }
      }
    }

    if (action == 'UPDATE' &&
        (data['id'] == null || '${data['id']}'.isEmpty)) {
      return null;
    }

    return data;
  }

  Future<void> reportInteraction(
    int entityId,
    String type, {
    double? rating,
  }) async {
    try {
      final data = <String, dynamic>{'id': entityId, 'type': type};
      if (rating != null) {
        data['rating'] = rating;
      }

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
              'data': data,
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

  /// Resolve server product id from local row (required for cross-device stats).
  Future<int?> resolveRemoteProductId(int localProductId) async {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(localProductId)))
        .getSingleOrNull();
    if (product == null) return null;
    if (product.remoteId != null && product.remoteId!.isNotEmpty) {
      return int.tryParse(product.remoteId!) ?? localProductId;
    }
    return null;
  }

  /// Resolve server shop id from local row.
  Future<int?> resolveRemoteShopId(int localShopId) async {
    final shop = await (db.select(db.shops)
          ..where((t) => t.id.equals(localShopId)))
        .getSingleOrNull();
    if (shop == null) return null;
    if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
      return int.tryParse(shop.remoteId!) ?? localShopId;
    }
    return shop.id;
  }

  /// Track product view/share using local id; updates local counters + server.
  Future<void> reportProductStatByLocalId(
    int localProductId,
    String type, {
    double? rating,
  }) async {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(localProductId)))
        .getSingleOrNull();
    if (product == null) return;

    if (type == 'view') {
      await (db.update(db.products)..where((t) => t.id.equals(localProductId)))
          .write(ProductsCompanion(viewsCount: Value(product.viewsCount + 1)));
    } else if (type == 'share') {
      await (db.update(db.products)..where((t) => t.id.equals(localProductId)))
          .write(ProductsCompanion(sharesCount: Value(product.sharesCount + 1)));
    }

    final remoteId = await resolveRemoteProductId(localProductId);
    if (remoteId != null && isOnline) {
      unawaited(reportInteraction(remoteId, type, rating: rating));
    }
  }

  /// Sync a contact event to the server for seller stats on all devices.
  Future<void> reportContactStat({
    required int localShopId,
    required String contactType,
    int? localProductId,
    String? userPhone,
  }) async {
    if (!isOnline) return;

    final remoteShopId = await resolveRemoteShopId(localShopId);
    if (remoteShopId == null) return;

    int? remoteProductId;
    if (localProductId != null) {
      remoteProductId = await resolveRemoteProductId(localProductId);
    }

    await api.trackContact(
      shopId: remoteShopId,
      userPhone: (userPhone != null && userPhone.trim().isNotEmpty)
          ? userPhone.trim()
          : 'Client',
      contactType: contactType,
      productId: remoteProductId,
    );
  }

  /// Sync shop view / catalog-story-QR-status share to server.
  Future<void> reportShopInteractionByLocalId(
    int localShopId,
    String interactionType,
  ) async {
    if (!ShopStatsTypes.isSynced(interactionType) || !isOnline) return;

    final remoteShopId = await resolveRemoteShopId(localShopId);
    if (remoteShopId == null) return;

    unawaited(
      api.trackShopInteraction(
        shopId: remoteShopId,
        interactionType: interactionType,
      ),
    );
  }

  /// Fetch aggregated shop stats from server (likes, contacts, views…).
  Future<Map<String, int>?> fetchRemoteShopStats(int localShopId) async {
    if (!isOnline) return null;
    final remoteShopId = await resolveRemoteShopId(localShopId);
    if (remoteShopId == null) return null;
    return api.fetchShopStats(remoteShopId);
  }

  /// Retry products that were skipped because their shop was not mapped yet.
  Future<int> _retrySkippedProducts(
    List<Map<String, dynamic>> skippedProducts, {
    required Set<String> pendingProductRemoteIds,
  }) async {
    if (skippedProducts.isEmpty) return 0;

    final allShops = await db.select(db.shops).get();
    final shopIdMap = <String, int>{};
    for (final shop in allShops) {
      if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
        shopIdMap[shop.remoteId!] = shop.id;
      }
    }

    final allProducts = await db.select(db.products).get();
    final productIdMap = <String, int>{
      for (final p in allProducts)
        if (p.remoteId != null && p.remoteId!.isNotEmpty) p.remoteId!: p.id,
    };
    final localProductById = {for (final p in allProducts) p.id: p};

    var inserted = 0;
    for (final p in skippedProducts) {
      final dynamic rawRemoteId = p['remote_id'];
      final String rId =
          rawRemoteId != null && rawRemoteId.toString().isNotEmpty
          ? rawRemoteId.toString()
          : (p['id']?.toString() ?? '');
      if (rId.isNotEmpty && pendingProductRemoteIds.contains(rId)) {
        continue;
      }

      final localShopId = _resolveLocalShopIdForProduct(
        p,
        shopIdMap,
        allShops,
      );
      if (localShopId <= 0) continue;

      final sanitizedName = ((p['name'] as String?) ?? 'Produit').trim();
      final serverPrice = (p['price'] as num?)?.toDouble();
      final existingLocalId = _findExistingLocalProductIdForPull(
        remoteId: rId,
        localShopId: localShopId,
        sanitizedName: sanitizedName.isEmpty ? 'Produit' : sanitizedName,
        serverPrice: serverPrice,
        productIdMap: productIdMap,
        allProducts: allProducts,
      );
      if (existingLocalId != null) {
        productIdMap[rId] = existingLocalId;
      }
      final existingProduct = existingLocalId != null
          ? localProductById[existingLocalId]
          : null;

      await db.into(db.products).insert(
        ProductsCompanion(
          id: existingLocalId != null
              ? Value(existingLocalId)
              : const Value.absent(),
          remoteId: Value(rId),
          shopId: Value(localShopId),
          categoryId: Value(p['category_id'] as int?),
          name: Value(p['name'] as String? ?? 'Produit'),
          description: Value(p['description'] as String?),
          price: Value((p['price'] as num?)?.toDouble()),
          imageUrls: Value(
            _mergeImageUrlsForLocal(
              _coerceMediaField(p['image_urls']),
              existingProduct?.imageUrls,
            ),
          ),
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
          metadata: Value(
            _mergeProductSyncMetadata(
              p['metadata'] as String?,
              serverShopId: p['shop_id'],
            ),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
      inserted++;
    }
    return inserted;
  }

  /// Full pull of all shops from server — required before products can link.
  Future<void> ensureShopsSynced() async {
    if (!isOnline) return;
    try {
      debugPrint('ensureShopsSynced: starting...');
      final remoteShops = await _fetchAllShopsPaginated();
      if (remoteShops.isEmpty) {
        debugPrint('ensureShopsSynced: no shops fetched');
        return;
      }

      var allShops = await db.select(db.shops).get();
      final shopIdMap = <String, int>{
        for (final s in allShops)
          if (s.remoteId != null && s.remoteId!.isNotEmpty) s.remoteId!: s.id,
      };
      final ownerIdToLocalShopId = <String, int>{};
      for (final s in allShops) {
        _registerOwnerShopKeys(ownerIdToLocalShopId, s);
      }
      final localShopById = {for (final s in allShops) s.id: s};

      await _pullInsertShops(
        remoteShops: remoteShops,
        shopIdMap: shopIdMap,
        ownerIdToLocalShopId: ownerIdToLocalShopId,
        localShopById: localShopById,
        pendingShopRemoteIds: await _pendingRemoteIds('shops'),
        fullSync: false,
      );

      await repairProductShopLinks();
      debugPrint(
        'ensureShopsSynced: synced ${remoteShops.length} shops from server',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('ensureShopsSynced error: $e');
    }
  }

  /// Upsert a single category returned by the server (e.g. find-or-create).
  /// Returns the server category id for use in product payloads.
  Future<int?> upsertCategoryFromServer(Map<String, dynamic> cat) async {
    try {
      final dynamic rawRemoteId = cat['remote_id'];
      final int? serverId = _toInt(cat['id']);
      final String remoteId =
          rawRemoteId != null && rawRemoteId.toString().isNotEmpty
          ? rawRemoteId.toString()
          : (serverId?.toString() ?? '');

      if (remoteId.isEmpty) {
        debugPrint('upsertCategoryFromServer: missing remote id');
        return serverId;
      }

      final existing = await (db.select(db.categories)
            ..where((t) => t.remoteId.equals(remoteId)))
          .getSingleOrNull();

      await db.into(db.categories).insert(
        CategoriesCompanion(
          id: existing != null
              ? Value(existing.id)
              : const Value.absent(),
          remoteId: Value(remoteId),
          name: Value(cat['name'] as String? ?? 'Sans nom'),
          icon: Value(cat['icon'] as String?),
          level: Value(_toInt(cat['level']) ?? 1),
          parentId: Value(_toInt(cat['parent_id'])),
          sortOrder: Value(_toInt(cat['sort_order']) ?? 0),
          updatedAt: Value(
            DateTime.tryParse(cat['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );

      debugPrint(
        'upsertCategoryFromServer: ${cat['name']} serverId=$serverId remoteId=$remoteId',
      );
      return serverId;
    } catch (e) {
      debugPrint('upsertCategoryFromServer error: $e');
      return _toInt(cat['id']);
    }
  }

  Future<void> ensureCategoriesSynced() async {
    try {
      // Force a full pull of categories from server (no updated_since)
      debugPrint('ensureCategoriesSynced: starting...');
      List<Map<String, dynamic>> remoteCategories = [];
      try {
        remoteCategories = await api.fetchCategories().timeout(_requestTimeout);
        debugPrint(
          'ensureCategoriesSynced: fetched ${remoteCategories.length} from server',
        );
      } on TimeoutException {
        debugPrint('PULL TIMEOUT: categories (ensureCategoriesSynced)');
      } catch (e) {
        debugPrint('PULL ERROR (ensureCategoriesSynced): $e');
      }

      if (remoteCategories.isEmpty) {
        debugPrint('ensureCategoriesSynced: no categories fetched, aborting');
        return;
      }

      // Log first few categories for debugging
      for (var i = 0; i < remoteCategories.length && i < 3; i++) {
        debugPrint('ensureCategoriesSynced: cat[$i] = ${remoteCategories[i]}');
      }

      // Build map of existing categories by remoteId for proper upsert
      final existingCats = await db.select(db.categories).get();
      debugPrint(
        'ensureCategoriesSynced: ${existingCats.length} existing local categories',
      );
      final Map<String, int> categoryIdMap = {};
      for (final c in existingCats) {
        final rId = c.remoteId;
        if (rId != null && rId.isNotEmpty) {
          categoryIdMap[rId] = c.id;
        }
      }

      // Build a map of remote_id -> category data to calculate correct levels
      final Map<String, Map<String, dynamic>> remoteCatMap = {};
      for (var cat in remoteCategories) {
        final dynamic rawRemoteId = cat['remote_id'];
        final String rId =
            rawRemoteId != null && rawRemoteId.toString().isNotEmpty
            ? rawRemoteId.toString()
            : (cat['id']?.toString() ?? '');
        remoteCatMap[rId] = cat;
      }

      // Calculate correct levels based on parent-child relationships
      // First pass: identify root categories (parent_id is null)
      final Map<String, int> calculatedLevels = {};
      for (var entry in remoteCatMap.entries) {
        final rId = entry.key;
        final cat = entry.value;
        final parentId = cat['parent_id'];
        if (parentId == null) {
          calculatedLevels[rId] = 0;
        }
      }

      // Second pass: calculate levels iteratively
      bool changed = true;
      int maxIterations = 10; // Prevent infinite loops
      while (changed && maxIterations > 0) {
        changed = false;
        maxIterations--;
        for (var entry in remoteCatMap.entries) {
          final rId = entry.key;
          final cat = entry.value;
          if (calculatedLevels.containsKey(rId)) continue;

          final dynamic rawParentId = cat['parent_id'];
          if (rawParentId == null) {
            calculatedLevels[rId] = 0;
            changed = true;
            continue;
          }

          final String parentRemoteId = rawParentId.toString();
          if (calculatedLevels.containsKey(parentRemoteId)) {
            calculatedLevels[rId] = calculatedLevels[parentRemoteId]! + 1;
            changed = true;
          }
        }
      }

      debugPrint(
        'ensureCategoriesSynced: calculated levels for ${calculatedLevels.length} categories',
      );
      // Log first few calculated levels
      int logCount = 0;
      for (var entry in calculatedLevels.entries) {
        if (logCount >= 5) break;
        final cat = remoteCatMap[entry.key];
        if (cat != null) {
          debugPrint(
            '  Category: ${cat['name']}, remote_id=${entry.key}, calculated_level=${entry.value}, server_level=${cat['level']}',
          );
          logCount++;
        }
      }

      await db.batch((batch) {
        for (var cat in remoteCategories) {
          // Use remote_id if available, otherwise use id as fallback
          final dynamic rawRemoteId = cat['remote_id'];
          final String rId =
              rawRemoteId != null && rawRemoteId.toString().isNotEmpty
              ? rawRemoteId.toString()
              : (cat['id']?.toString() ?? '');
          final int? existingLocalId = categoryIdMap[rId];

          // Use calculated level if available, otherwise fall back to server value
          final int calculatedLevel =
              calculatedLevels[rId] ?? (_toInt(cat['level']) ?? 0);

          batch.insert(
            db.categories,
            CategoriesCompanion(
              id: existingLocalId != null
                  ? Value(existingLocalId)
                  : const Value.absent(),
              remoteId: Value(rId),
              name: Value(cat['name'] as String? ?? 'Sans nom'),
              icon: Value(cat['icon'] as String?),
              level: Value(calculatedLevel),
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
      });
      debugPrint('ensureCategoriesSynced: inserted to local DB');

      // Verify the insert worked
      final afterInsert = await db.select(db.categories).get();
      final rootCats = afterInsert.where((c) => c.level == 0).toList();
      debugPrint(
        'ensureCategoriesSynced: now ${afterInsert.length} total categories, ${rootCats.length} root (level=0)',
      );
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

  /// Map server-returned product ID back to local product record.
  /// Uses the local_id stored in the queue data to find the correct product.
  Future<void> _mapServerIdToLocalProduct(
    SyncQueueData item,
    String serverId,
  ) async {
    try {
      final data = jsonDecode(item.entityData) as Map<String, dynamic>;
      final localId = data['local_id'] as int?;

      if (localId == null) {
        debugPrint(
          '_mapServerIdToLocalProduct: missing local_id in queue item',
        );
        return;
      }

      await (db.update(db.products)..where((t) => t.id.equals(localId))).write(
        ProductsCompanion(remoteId: Value(serverId)),
      );
      debugPrint(
        '_mapServerIdToLocalProduct: mapped local product $localId → server ID $serverId',
      );
      if (productRepository != null) {
        final removed = await productRepository!.repairDisplayDuplicates();
        if (removed > 0) {
          debugPrint(
            '_mapServerIdToLocalProduct: removed $removed duplicate row(s)',
          );
        }
      }
    } catch (e) {
      debugPrint('_mapServerIdToLocalProduct error: $e');
    }
  }

  /// Map server-returned shop ID back to local shop record.
  /// This ensures shop.remoteId is set so products can reference the correct server shop.
  Future<void> _mapServerIdToLocalShop(
    SyncQueueData item,
    String serverId,
  ) async {
    try {
      final data = jsonDecode(item.entityData) as Map<String, dynamic>;
      final localId = data['local_id'] as int?;

      if (localId == null) {
        debugPrint('_mapServerIdToLocalShop: missing local_id in queue item');
        return;
      }

      await (db.update(db.shops)..where((t) => t.id.equals(localId))).write(
        ShopsCompanion(remoteId: Value(serverId)),
      );
      debugPrint(
        '_mapServerIdToLocalShop: mapped local shop $localId → server ID $serverId',
      );
    } catch (e) {
      debugPrint('_mapServerIdToLocalShop error: $e');
    }
  }

  Future<void> _mapServerIdToLocalOrder(
    SyncQueueData item,
    String serverId,
  ) async {
    try {
      final data = jsonDecode(item.entityData) as Map<String, dynamic>;
      final localId = data['local_id'] as int?;
      if (localId == null) return;

      await (db.update(db.orders)..where((t) => t.id.equals(localId))).write(
        OrdersCompanion(remoteId: Value(serverId), synced: const Value(1)),
      );
    } catch (e) {
      debugPrint('_mapServerIdToLocalOrder error: $e');
    }
  }

  Future<void> _mapServerIdToLocalDelivery(
    SyncQueueData item,
    String serverId,
  ) async {
    try {
      final data = jsonDecode(item.entityData) as Map<String, dynamic>;
      final localId = data['local_id'] as int?;
      if (localId == null) return;

      await (db.update(db.deliveries)..where((t) => t.id.equals(localId)))
          .write(
        DeliveriesCompanion(remoteId: Value(serverId), synced: const Value(1)),
      );
    } catch (e) {
      debugPrint('_mapServerIdToLocalDelivery error: $e');
    }
  }

  Future<void> _pullRemoteDeliveries({DateTime? updatedSince}) async {
    final repo = deliveryRepository;
    if (repo == null) return;

    try {
      final profile = await db.select(db.userProfiles).getSingleOrNull();
      final buyerPhone = profile?.phone;
      if (buyerPhone != null && buyerPhone.isNotEmpty) {
        await repo.pullRemote(
          apiService: api,
          buyerPhone: buyerPhone,
          updatedSince: updatedSince,
        );
      }

      final shops = await db.select(db.shops).get();
      for (final shop in shops) {
        if (shop.remoteId == null || shop.remoteId!.isEmpty) continue;
        final serverShopId = int.tryParse(shop.remoteId!);
        if (serverShopId == null) continue;
        await repo.pullRemote(
          apiService: api,
          shopId: serverShopId,
          updatedSince: updatedSince,
        );
      }
    } catch (e) {
      debugPrint('_pullRemoteDeliveries error: $e');
    }
  }

  Future<void> _pullRemoteOrders({DateTime? updatedSince}) async {
    final repo = orderRepository;
    if (repo == null) return;

    try {
      final profile = await db.select(db.userProfiles).getSingleOrNull();
      final buyerPhone = profile?.phone;
      if (buyerPhone != null && buyerPhone.isNotEmpty) {
        await repo.pullRemoteOrders(
          apiService: api,
          buyerPhone: buyerPhone,
          updatedSince: updatedSince,
        );
      }

      final shops = await db.select(db.shops).get();
      for (final shop in shops) {
        if (shop.remoteId == null || shop.remoteId!.isEmpty) continue;
        final serverShopId = int.tryParse(shop.remoteId!);
        if (serverShopId == null) continue;
        await repo.pullRemoteOrders(
          apiService: api,
          shopId: serverShopId,
          updatedSince: updatedSince,
        );
      }
    } catch (e) {
      debugPrint('_pullRemoteOrders error: $e');
    }
  }

  Future<void> _fireProductAlerts() async {
    final alerts = productAlertsService;
    if (alerts == null) return;

    try {
      final products = await db.select(db.products).get();
      final snapshot = <int, ({String name, double? price, bool isSold})>{};
      for (final p in products) {
        if (await alerts.isWatching(p.id)) {
          snapshot[p.id] = (
            name: p.name,
            price: p.price,
            isSold: p.isSold,
          );
        }
      }
      if (snapshot.isEmpty) return;
      await ProductAlertNotifier.checkAndNotify(
        products: snapshot,
        alerts: alerts,
      );
    } catch (e) {
      debugPrint('_fireProductAlerts error: $e');
    }
  }

  /// Hard-delete local products missing from the server list.
  Future<int> _purgeOrphanedLocalProducts(
    Set<String> serverProductRemoteIds, {
    Set<String> pendingRemoteIds = const {},
  }) async {
    final allLocalProducts = await db.select(db.products).get();
    final imageUrls = <String?>[];
    var purged = 0;

    for (final localProduct in allLocalProducts) {
      if (localProduct.remoteId == null || localProduct.remoteId!.isEmpty) {
        continue;
      }
      if (pendingRemoteIds.contains(localProduct.remoteId)) {
        continue;
      }
      if (serverProductRemoteIds.contains(localProduct.remoteId)) {
        continue;
      }

      imageUrls.add(localProduct.imageUrls);
      await (db.delete(db.products)
            ..where((t) => t.id.equals(localProduct.id)))
          .go();
      purged++;
      debugPrint(
        'Sync: Removed deleted product ${localProduct.name} (remoteId: ${localProduct.remoteId})',
      );
    }

    if (imageUrls.isNotEmpty) {
      await ImageUtils.evictCachedSources(imageUrls);
    }
    return purged;
  }

  /// Hard-delete local stories (and media) missing from the server list.
  Future<int> _purgeOrphanedLocalStories(Set<String> serverStoryRemoteIds) async {
    final allLocalStories = await db.select(db.stories).get();
    final mediaUrls = <String?>[];
    var purged = 0;

    for (final localStory in allLocalStories) {
      if (localStory.remoteId == null || localStory.remoteId!.isEmpty) {
        continue;
      }
      if (serverStoryRemoteIds.contains(localStory.remoteId)) {
        continue;
      }

      final mediaRows = await (db.select(db.storyMedia)
            ..where((t) => t.storyId.equals(localStory.id)))
          .get();
      mediaUrls.add(localStory.mediaUrl);
      mediaUrls.addAll(mediaRows.map((m) => m.mediaUrl));

      await db.transaction(() async {
        await (db.delete(db.storyMedia)
              ..where((t) => t.storyId.equals(localStory.id)))
            .go();
        await (db.delete(db.stories)
              ..where((t) => t.id.equals(localStory.id)))
            .go();
      });

      purged++;
      debugPrint(
        'Sync: Hard-deleted orphaned story (remoteId: ${localStory.remoteId})',
      );
    }

    if (mediaUrls.isNotEmpty) {
      await ImageUtils.evictCachedSources(mediaUrls);
    }
    return purged;
  }

  /// Local arrivages saved with isArrivage=false (single-photo bug before fix).
  Future<void> _repairMisclassifiedArrivages() async {
    final now = DateTime.now();
    const storyExpiry = Duration(hours: 24);
    final candidates = await (db.select(db.stories)..where(
          (t) =>
              t.isArrivage.equals(false) &
              t.expiresAt.isBiggerThanValue(now),
        ))
        .get();

    for (final story in candidates) {
      if (story.mediaUrl.isEmpty) continue;
      final lifespan = story.expiresAt.difference(story.createdAt);
      if (lifespan <= storyExpiry) continue;
      await (db.update(db.stories)..where((t) => t.id.equals(story.id))).write(
        const StoriesCompanion(isArrivage: Value(true)),
      );
      debugPrint(
        'Story repair: reclassified arrivage id=${story.id} (lifespan ${lifespan.inHours}h)',
      );
    }
  }

  /// Repair local stories that were skipped during pull (preserve UI state)
  /// but may have missing media or wrong isArrivage flag after a buggy create.
  Future<void> _repairExistingStoriesFromServer(
    List<Map<String, dynamic>> remoteStories,
    Map<String, Story> existingByRemoteId,
  ) async {
    for (final st in remoteStories) {
      final dynamic rawRemoteId = st['remote_id'];
      final String rId = rawRemoteId != null && rawRemoteId.toString().isNotEmpty
          ? rawRemoteId.toString()
          : (st['id']?.toString() ?? '');
      if (rId.isEmpty) continue;

      final localStory = existingByRemoteId[rId];
      if (localStory == null) continue;

      final rawMediaUrl = st['media_url'] as String? ?? '';
      final mergedMedia = _mergeMediaUrlForLocal(rawMediaUrl, localStory.mediaUrl);
      final serverIsArrivage = (_toInt(st['is_arrivage']) ?? 0) == 1;

      final needsMediaFix =
          localStory.mediaUrl.isEmpty &&
          mergedMedia != null &&
          mergedMedia.isNotEmpty;
      final needsArrivageFix = serverIsArrivage && !localStory.isArrivage;

      if (needsMediaFix || needsArrivageFix) {
        await (db.update(db.stories)..where((t) => t.id.equals(localStory.id)))
            .write(
          StoriesCompanion(
            mediaUrl: needsMediaFix ? Value(mergedMedia) : const Value.absent(),
            isArrivage: needsArrivageFix
                ? const Value(true)
                : const Value.absent(),
          ),
        );
        debugPrint(
          'Story repair: id=${localStory.id} remoteId=$rId '
          'mediaFix=$needsMediaFix arrivageFix=$needsArrivageFix',
        );
      }

      if (st['media_items'] is! List) continue;
      final existingMedia = await (db.select(
        db.storyMedia,
      )..where((t) => t.storyId.equals(localStory.id))).get();
      if (existingMedia.isNotEmpty) continue;

      for (final mi in st['media_items'] as List) {
        if (mi is! Map<String, dynamic>) continue;
        final childRaw = mi['media_url'] as String? ?? '';
        final childStored = _mergeMediaUrlForLocal(childRaw, null);
        if (childStored == null || childStored.isEmpty) continue;
        await db.into(db.storyMedia).insert(
              StoryMediaCompanion.insert(
                storyId: localStory.id,
                mediaUrl: childStored,
                mediaType: Value(mi['media_type'] as String? ?? 'image'),
                sortOrder: Value(mi['sort_order'] as int? ?? 0),
              ),
            );
      }
    }
  }

  /// Map server-returned story ID back to local story record.
  /// This prevents duplicate stories during pull sync.
  Future<void> _mapServerIdToLocalStory(
    SyncQueueData item,
    String serverId,
  ) async {
    try {
      final data = jsonDecode(item.entityData) as Map<String, dynamic>;
      final localId = data['local_id'] as int?;

      if (localId != null) {
        await (db.update(db.stories)..where((t) => t.id.equals(localId))).write(
          StoriesCompanion(remoteId: Value(serverId)),
        );
        debugPrint(
          '_mapServerIdToLocalStory: mapped local story $localId → server ID $serverId',
        );
        return;
      }

      final localShopId = data['local_shop_id'] as int?;
      if (localShopId == null) {
        debugPrint(
          '_mapServerIdToLocalStory: missing local_id and local_shop_id',
        );
        return;
      }

      final localStories =
          await (db.select(db.stories)
                ..where((t) => t.shopId.equals(localShopId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(5))
              .get();

      for (final localStory in localStories) {
        if (localStory.remoteId == null || localStory.remoteId!.isEmpty) {
          await (db.update(db.stories)
                ..where((t) => t.id.equals(localStory.id)))
              .write(StoriesCompanion(remoteId: Value(serverId)));
          debugPrint(
            '_mapServerIdToLocalStory: mapped local story ${localStory.id} to server ID $serverId',
          );
          return;
        }
      }

      debugPrint(
        '_mapServerIdToLocalStory: no local story without remoteId found for localShopId=$localShopId',
      );
    } catch (e) {
      debugPrint('_mapServerIdToLocalStory error: $e');
    }
  }

  Future<void> _pullProductUpdates({DateTime? updatedSince}) async {
    try {
      final rows = await api.fetchProductUpdates(updatedSince: updatedSince);
      if (rows.isEmpty) return;

      final repo = ProductUpdateRepository(db);
      for (final row in rows) {
        await repo.upsertFromServer(row);
      }

      await ProductUpdateNotifier(
        db: db,
        updateRepository: repo,
        notificationService: notificationService,
      ).notifyNewUpdates();

      debugPrint('PULL: product_updates → ${rows.length}');
    } catch (e) {
      debugPrint('_pullProductUpdates error: $e');
    }
  }
}
