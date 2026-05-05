import 'dart:async';
import 'package:flutter/foundation.dart';
import '../local/uza_database.dart';

/// Manages data lifecycle for low-end devices in the DRC market.
///
/// Periodically purges expired data, estimates database size, and
/// performs aggressive cleanup when the DB exceeds the size threshold.
class DataManagementService extends ChangeNotifier {
  final UzaDatabase db;
  Timer? _cleanupTimer;

  // Configuration — tuned for devices with limited storage
  static const int maxDbSizeMB = 50;
  static const int dataExpirationDays = 30;
  static const Duration cleanupInterval = Duration(hours: 6);

  int _estimatedSizeMB = 0;
  DateTime? _lastCleanup;

  int get estimatedSizeMB => _estimatedSizeMB;
  DateTime? get lastCleanup => _lastCleanup;

  DataManagementService({required this.db});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start periodic cleanup checks (runs immediately, then every 6 hours).
  void startPeriodicCleanup() {
    _runCleanupCycle();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _runCleanupCycle());
  }

  /// Full cleanup cycle executed periodically and on-demand.
  Future<void> _runCleanupCycle() async {
    try {
      await purgeExpiredData();
      await _estimateDatabaseSize();
      if (_estimatedSizeMB > maxDbSizeMB) {
        await _aggressiveCleanup();
      }
      _lastCleanup = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Cleanup cycle failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Standard expiration purge
  // ---------------------------------------------------------------------------

  /// Remove products older than [dataExpirationDays] that aren't in the
  /// wishlist or cart, expired stories, old analytics, and synced offline
  /// queue items.
  ///
  /// Returns the number of rows purged.
  Future<int> purgeExpiredData() async {
    final cutoff = DateTime.now().subtract(Duration(days: dataExpirationDays));
    final cutoffStr = cutoff.toIso8601String();
    final nowStr = DateTime.now().toIso8601String();
    int totalDeleted = 0;

    // Count then delete old products not referenced by wishlist or cart.
    // Products table uses `updated_at` (no `created_at` column).
    final productCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM products "
                  "WHERE updated_at < '$cutoffStr' "
                  "AND id NOT IN (SELECT product_id FROM wishlist_products) "
                  "AND id NOT IN (SELECT product_id FROM cart_items)",
                )
                .getSingle())
            .read<int>('c');
    totalDeleted += productCount;

    await db.customStatement(
      "DELETE FROM products "
      "WHERE updated_at < '$cutoffStr' "
      "AND id NOT IN (SELECT product_id FROM wishlist_products) "
      "AND id NOT IN (SELECT product_id FROM cart_items)",
    );

    // Count then delete expired stories
    final storyCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM stories WHERE expires_at < '$nowStr'",
                )
                .getSingle())
            .read<int>('c');
    totalDeleted += storyCount;

    await db.customStatement(
      "DELETE FROM stories WHERE expires_at < '$nowStr'",
    );

    // Count then delete old analytics (keep last 30 days)
    // Analytics table uses `created_at`, not `timestamp`.
    final analyticsCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM analytics WHERE created_at < '$cutoffStr'",
                )
                .getSingle())
            .read<int>('c');
    totalDeleted += analyticsCount;

    await db.customStatement(
      "DELETE FROM analytics WHERE created_at < '$cutoffStr'",
    );

    // Count then delete synced items from offline queue
    final queueCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM offline_queue WHERE status = 'synced'",
                )
                .getSingle())
            .read<int>('c');
    totalDeleted += queueCount;

    await db.customStatement(
      "DELETE FROM offline_queue WHERE status = 'synced'",
    );

    debugPrint('Data cleanup completed – $totalDeleted rows removed');
    return totalDeleted;
  }

  // ---------------------------------------------------------------------------
  // Size estimation
  // ---------------------------------------------------------------------------

  /// Estimate database size by counting rows × average row size.
  ///
  /// Products: ~500 B/row | Shops: ~300 B | Stories: ~200 B | Analytics: ~100 B
  Future<void> _estimateDatabaseSize() async {
    try {
      final productCount =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM products')
                  .getSingle())
              .read<int>('c');
      final shopCount =
          (await db.customSelect('SELECT COUNT(*) AS c FROM shops').getSingle())
              .read<int>('c');
      final storyCount =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM stories')
                  .getSingle())
              .read<int>('c');
      final analyticsCount =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM analytics')
                  .getSingle())
              .read<int>('c');

      final totalBytes =
          (productCount * 500) +
          (shopCount * 300) +
          (storyCount * 200) +
          (analyticsCount * 100);

      _estimatedSizeMB = (totalBytes / (1024 * 1024)).ceil();
      debugPrint('Estimated DB size: $_estimatedSizeMB MB');
    } catch (e) {
      debugPrint('Size estimation failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Aggressive cleanup (DB exceeds threshold)
  // ---------------------------------------------------------------------------

  /// More aggressive cleanup when the database exceeds [maxDbSizeMB].
  Future<void> _aggressiveCleanup() async {
    debugPrint('Aggressive cleanup triggered (DB > ${maxDbSizeMB}MB)');

    final cutoff15 = DateTime.now().subtract(const Duration(days: 15));
    final cutoff7 = DateTime.now().subtract(const Duration(days: 7));
    final cutoff30 = DateTime.now().subtract(const Duration(days: 30));

    // Delete products older than 15 days (half the normal expiration)
    await db.customStatement(
      "DELETE FROM products "
      "WHERE updated_at < '${cutoff15.toIso8601String()}' "
      "AND id NOT IN (SELECT product_id FROM wishlist_products) "
      "AND id NOT IN (SELECT product_id FROM cart_items)",
    );

    // Delete all analytics older than 7 days
    await db.customStatement(
      "DELETE FROM analytics WHERE created_at < '${cutoff7.toIso8601String()}'",
    );

    // Delete old user contacts (> 30 days) to free extra space
    await db.customStatement(
      "DELETE FROM user_contacts WHERE created_at < '${cutoff30.toIso8601String()}'",
    );

    // Delete old product reviews for deleted products (orphan cleanup)
    await db.customStatement(
      "DELETE FROM product_reviews "
      "WHERE product_id NOT IN (SELECT id FROM products)",
    );

    // Delete old sync queue entries
    await db.customStatement(
      "DELETE FROM offline_queue WHERE created_at < '${cutoff15.toIso8601String()}'",
    );

    debugPrint('Consider clearing image cache as well');
    await _estimateDatabaseSize();
  }

  // ---------------------------------------------------------------------------
  // Stats for UI
  // ---------------------------------------------------------------------------

  /// Returns a map of data statistics useful for a storage-management screen.
  Future<Map<String, int>> getDataStats() async {
    try {
      final products =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM products')
                  .getSingle())
              .read<int>('c');
      final shops =
          (await db.customSelect('SELECT COUNT(*) AS c FROM shops').getSingle())
              .read<int>('c');
      final stories =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM stories')
                  .getSingle())
              .read<int>('c');
      final queue =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) AS c FROM offline_queue WHERE status != 'synced'",
                  )
                  .getSingle())
              .read<int>('c');
      final wishlist =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM wishlist_products')
                  .getSingle())
              .read<int>('c');
      final cart =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM cart_items')
                  .getSingle())
              .read<int>('c');
      final analytics =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM analytics')
                  .getSingle())
              .read<int>('c');

      return {
        'products': products,
        'shops': shops,
        'stories': stories,
        'pendingSync': queue,
        'wishlist': wishlist,
        'cart': cart,
        'analytics': analytics,
        'estimatedSizeMB': _estimatedSizeMB,
      };
    } catch (e) {
      debugPrint('Failed to get data stats: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Manual trigger
  // ---------------------------------------------------------------------------

  /// Manually trigger a full cleanup cycle.
  Future<void> forceCleanup() async {
    await _runCleanupCycle();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
