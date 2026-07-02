import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../local/uza_database.dart';
import 'location_data.dart';
import 'paginated_result.dart';
import '../services/sync_service.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/shop_visibility_utils.dart';
import '../../core/utils/shop_stats_types.dart';
import '../../core/models/shop_visibility_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopRepository {
  final UzaDatabase db;
  final SyncService? syncService;

  ShopRepository(this.db, {this.syncService});

  Stream<List<Shop>> watchAllShops() {
    return db.select(db.shops).watch();
  }

  Stream<List<Shop>> watchFeaturedShops() {
    return db.select(db.shops).watch().map((items) {
      final now = DateTime.now();
      return sortShopsByVisibility(items, now);
    });
  }

  /// Applies visibility rules: active today first; optionally hide inactive.
  List<Shop> applyDirectoryVisibility(
    List<Shop> shops, {
    required bool showAll,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final sorted = sortShopsByVisibility(shops, reference);
    if (showAll) return sorted;
    return sorted.where((s) => isShopActiveToday(s, reference)).toList();
  }

  int countActiveShopsToday(List<Shop> shops, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return shops.where((s) => isShopActiveToday(s, reference)).length;
  }

  Stream<List<Shop>> watchActiveBanners() {
    return (db.select(
      db.shops,
    )..where((t) => t.bannerStatus.equals(2))).watch();
  }

  Stream<List<Shop>> watchPendingPromotions() {
    return (db.select(db.shops)
          ..where((t) => t.boostStatus.equals(1) | t.bannerStatus.equals(1)))
        .watch();
  }

  Stream<Shop?> watchShopById(int id) {
    return (db.select(db.shops)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<Shop?> watchShopByRemoteId(String remoteId) {
    if (remoteId.isEmpty) return Stream.value(null);
    return (db.select(db.shops)..where((t) => t.remoteId.equals(remoteId)))
        .watchSingleOrNull();
  }

  /// Stream that follows the canonical local row for [shop] (server id when synced).
  Stream<Shop?> watchShop(Shop shop) {
    if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
      return watchShopByRemoteId(shop.remoteId!);
    }
    return watchShopById(shop.id);
  }

  Future<Shop?> getShopById(int id) {
    return (db.select(
      db.shops,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Shop?> getShopByRemoteId(String remoteId) {
    if (remoteId.isEmpty) return Future.value(null);
    return (db.select(db.shops)..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();
  }

  /// Resolves a shop from the server-side id stored on synced products.
  Future<Shop?> resolveShopByServerId(int serverShopId) {
    return getShopByRemoteId(serverShopId.toString());
  }

  /// [storedId] is usually a local row id; when missing locally, treats it as a
  /// server shop id (legacy rows where server id was saved in [shopId]).
  Future<Shop?> resolveShopForStoredId(int storedId) async {
    final local = await getShopById(storedId);
    if (local != null) return local;
    return getShopByRemoteId(storedId.toString());
  }

  /// Resolves a shop for deep links: remote id first, then public API.
  Future<Shop?> resolveShopById(int id) async {
    final serverKey = id.toString();

    final byRemote = await (db.select(db.shops)
          ..where((t) => t.remoteId.equals(serverKey)))
        .getSingleOrNull();
    if (byRemote != null) return byRemote;

    final local = await getShopById(id);
    if (local != null && local.remoteId == serverKey) return local;

    try {
      final uri = Uri.parse(
        'https://uzaapp.com/api/shop_page.php?id=$id&format=json',
      );
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final data = body['shop'] as Map<String, dynamic>?;
      if (data == null) return null;

      final remoteId = data['remote_id']?.toString();
      final resolvedId = _toInt(data['id']) ?? id;
      final rId = remoteId != null && remoteId.isNotEmpty
          ? remoteId
          : resolvedId.toString();

      final existing = await (db.select(db.shops)
            ..where((t) => t.remoteId.equals(rId)))
          .getSingleOrNull();
      if (existing != null) return existing;

      final localId = await db.into(db.shops).insert(
        ShopsCompanion(
          remoteId: Value(rId),
          name: Value((data['name'] as String? ?? 'Boutique').trim()),
          description: Value(data['description'] as String?),
          logoUrl: Value(data['logo_url'] as String?),
          type: Value(
            data['type'] == 'wholesale' ? ShopType.wholesale : ShopType.retail,
          ),
          ownerId: Value(data['owner_id'] as String?),
          address: Value(data['address'] as String?),
          whatsapp: Value(data['whatsapp'] as String?),
          phone: Value(data['phone'] as String?),
          email: Value(data['email'] as String?),
          instagramUrl: Value(data['instagram_url'] as String?),
          tiktokUrl: Value(data['tiktok_url'] as String?),
          facebookUrl: Value(data['facebook_url'] as String?),
          youtubeUrl: Value(data['youtube_url'] as String?),
          bannerUrl: Value(data['banner_url'] as String?),
          videoUrl: Value(data['video_url'] as String?),
          updatedAt: Value(
            DateTime.tryParse(data['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
          isBoosted: Value(_toBool(data['is_boosted'])),
          boostStatus: Value(_toInt(data['boost_status']) ?? 0),
          bannerStatus: Value(_toInt(data['banner_status']) ?? 0),
          bannerText: Value(data['banner_text'] as String?),
          isVerified: Value(_toBool(data['is_verified'])),
          responseTimeMinutes: Value(_toInt(data['response_time_minutes'])),
          commune: Value(data['commune'] as String?),
          city: Value(data['city'] as String?),
          latitude: Value((data['latitude'] as num?)?.toDouble()),
          longitude: Value((data['longitude'] as num?)?.toDouble()),
        ),
      );
      return getShopById(localId);
    } catch (e) {
      debugPrint('resolveShopById error: $e');
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

  Stream<Shop?> watchUserShop(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return watchAllShops().map((shops) {
      for (final shop in shops) {
        if (_shopBelongsToUser(shop, userId)) return shop;
      }
      return null;
    });
  }

  Future<Shop?> getUserShop(String userId) async {
    if (userId.isEmpty) return null;
    final shops = await db.select(db.shops).get();
    for (final shop in shops) {
      if (_shopBelongsToUser(shop, userId)) return shop;
    }
    return null;
  }

  /// Watch all shops owned by a given user (by ownerId / phone number).
  Stream<List<Shop>> watchUserShops(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return watchAllShops().map(
      (shops) =>
          shops.where((shop) => _shopBelongsToUser(shop, userId)).toList(),
    );
  }

  /// Ensure that local shops owned by [userId] (phone number) are
  /// properly linked so that [watchUserShop] / [watchUserShops] can
  /// find them after an app update or re-login.
  ///
  /// If any shop has a null or empty [ownerId] but its [phone] field
  /// matches [userId], we backfill [ownerId] so the shop is visible.
  /// Also normalises [ownerId] for common phone-number format
  /// differences (with / without country-code prefix).
  Future<void> reconnectShopsForUser(String userId) async {
    if (userId.isEmpty) return;

    // 1. Direct match — ownerId already equals the user's uid (any format)
    final variations = _phoneVariations(userId);
    final allShops = await db.select(db.shops).get();
    for (final shop in allShops) {
      if (_matchesAnyPhone(shop.ownerId, variations)) return;
    }

    // 2. Backfill ownerId only when empty and shop contact matches login phone.
    for (final shop in allShops) {
      if (!_shopBelongsToUser(shop, userId)) continue;
      if (shop.ownerId != null && shop.ownerId!.trim().isNotEmpty) continue;
      await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
        ShopsCompanion(
          ownerId: Value(
            PhoneUtils.normalizeDrc(userId).isNotEmpty
                ? PhoneUtils.normalizeDrc(userId)
                : userId,
          ),
        ),
      );
    }

    // 3. Normalise ownerId format for shops already owned by this user.
    for (final shop in allShops) {
      if (!_matchesAnyPhone(shop.ownerId, variations)) continue;
      final normalized = PhoneUtils.normalizeDrc(userId).isNotEmpty
          ? PhoneUtils.normalizeDrc(userId)
          : userId;
      if (shop.ownerId != normalized) {
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(ownerId: Value(normalized)),
        );
      }
    }

    await syncService?.repairProductShopLinks();
  }

  bool _shopBelongsToUser(Shop shop, String userId) {
    final variations = _phoneVariations(userId);
    if (_matchesAnyPhone(shop.ownerId, variations)) return true;
    final ownerEmpty = shop.ownerId == null || shop.ownerId!.trim().isEmpty;
    if (!ownerEmpty) return false;
    return _matchesAnyPhone(shop.phone, variations) ||
        _matchesAnyPhone(shop.whatsapp, variations);
  }

  bool _matchesAnyPhone(String? value, List<String> variations) {
    if (value == null || value.trim().isEmpty) return false;
    final valueVariations = _phoneVariations(value);
    return valueVariations.any(variations.contains);
  }

  /// Generate common phone-number format variations for DRC numbers.
  /// e.g. "+243823456789" → ["0823456789", "243823456789", "+243823456789"]
  List<String> _phoneVariations(String phone) => PhoneUtils.lookupKeys(phone);

  Future<int> addShop(ShopsCompanion shop) async {
    final id = await db.into(db.shops).insert(shop);
    unawaited(recordShopActivity(id));
    return id;
  }

  Future<bool> updateShop(ShopsCompanion shop) {
    return (db.update(db.shops)..where((t) => t.id.equals(shop.id.value)))
        .write(shop)
        .then((rows) => rows > 0);
  }

  Future<void> logShopInteraction(int shopId, String type) async {
    await db
        .into(db.analytics)
        .insert(
          AnalyticsCompanion.insert(
            entityType: 'shop',
            entityId: shopId,
            interactionType: type,
          ),
        );
    if (ShopStatsTypes.isSynced(type)) {
      syncService?.reportShopInteractionByLocalId(shopId, type);
    }
  }

  Future<Map<String, int>> _countContactsByType(int shopId) async {
    final rows = await (db.select(db.userContacts)
          ..where((t) => t.shopId.equals(shopId)))
        .get();

    var whatsapp = 0;
    var call = 0;
    var sms = 0;
    for (final row in rows) {
      switch (row.contactType) {
        case 'whatsapp':
          whatsapp++;
          break;
        case 'call':
          call++;
          break;
        case 'sms':
          sms++;
          break;
      }
    }

    return {
      'whatsapp': whatsapp,
      'call': call,
      'sms': sms,
      'total': whatsapp + call + sms,
    };
  }

  int _maxInt(int a, int b) => a > b ? a : b;

  void _mergeRemoteShopStats(Map<String, int> local, Map<String, int> remote) {
    local['totalFollowers'] = _maxInt(
      local['totalFollowers'] ?? 0,
      remote['followers'] ?? 0,
    );
    local['totalLikes'] = _maxInt(
      local['totalLikes'] ?? 0,
      remote['likes'] ?? 0,
    );
    local['contact_whatsapp'] = _maxInt(
      local['contact_whatsapp'] ?? 0,
      remote['whatsapp_contacts'] ?? 0,
    );
    local['contact_call'] = _maxInt(
      local['contact_call'] ?? 0,
      remote['call_contacts'] ?? 0,
    );
    local['contact_sms'] = _maxInt(
      local['contact_sms'] ?? 0,
      remote['sms_contacts'] ?? 0,
    );
    local['totalContacts'] = _maxInt(
      local['totalContacts'] ?? 0,
      remote['total_contacts'] ?? 0,
    );
    local['uniqueClients'] = _maxInt(
      local['uniqueClients'] ?? 0,
      remote['unique_clients'] ?? 0,
    );

    final localProductViews = local['product_view_global'] ?? 0;
    local['product_view_global'] = _maxInt(
      localProductViews,
      remote['product_views'] ?? 0,
    );

    local['view'] = _maxInt(local['view'] ?? 0, remote['shop_views'] ?? 0);

    final shopShares = _maxInt(
      local['shop_shares'] ?? 0,
      remote['shop_shares'] ?? 0,
    );
    local['shop_shares'] = shopShares;

    final mergedProductShares = _maxInt(
      local['product_shares'] ?? 0,
      remote['product_shares'] ?? 0,
    );
    local['product_shares'] = mergedProductShares;
    local['totalShares'] = mergedProductShares + shopShares;
    local['totalViews'] = (local['view'] ?? 0) + local['product_view_global']!;
  }

  Future<void> recordContact(
    int shopId,
    String phone,
    String type, {
    int? productId,
  }) async {
    await db
        .into(db.userContacts)
        .insert(
          UserContactsCompanion.insert(
            shopId: shopId,
            userPhone: phone,
            contactType: type,
            productId: Value(productId),
          ),
        );
    await logShopInteraction(shopId, 'contact_$type');
    syncService?.reportContactStat(
      localShopId: shopId,
      contactType: type,
      localProductId: productId,
      userPhone: phone,
    );
  }

  Stream<List<UserContact>> watchRecentContacts(int shopId) {
    return (db.select(db.userContacts)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(10))
        .watch();
  }

  /// Get comprehensive shop statistics for the seller dashboard
  Future<Map<String, int>> getShopStats(int shopId) async {
    // Collect all analytics rows for this shop + its products in one pass
    final products = await (db.select(
      db.products,
    )..where((t) => t.shopId.equals(shopId))).get();
    final productIds = products.map((p) => p.id).toList();

    // Build the list of entity IDs we care about: shop itself + its products
    final entityIds = <int>[shopId, ...productIds];

    // Fetch all analytics for shop and its products
    final allAnalytics = entityIds.isNotEmpty
        ? await (db.select(
            db.analytics,
          )..where((t) => t.entityId.isIn(entityIds))).get()
        : <Analytic>[];

    int shopViews = 0;
    int productViews = 0;
    int shopShares = 0;

    for (final a in allAnalytics) {
      switch (a.interactionType) {
        case 'view':
          if (a.entityType == 'shop') {
            shopViews++;
          }
          break;
        case 'share':
        case 'catalog_share':
        case 'qr_share':
        case 'story_share':
        case 'whatsapp_status':
        case 'facebook_status':
        case 'tiktok_status':
          if (a.entityType == 'shop') {
            shopShares++;
          }
          break;
      }
    }

    // Product views/shares: authoritative counters (synced from server on pull).
    int productShares = 0;
    for (final p in products) {
      productViews += p.viewsCount;
      productShares += p.sharesCount;
    }

    final contacts = await _countContactsByType(shopId);

    // Followers count from ShopFollows table (user-tracked)
    final followersCount = await (db.select(
      db.shopFollows,
    )..where((t) => t.shopId.equals(shopId))).get().then((rows) => rows.length);

    // Also count from legacy FollowedShops table
    final legacyFollowersCount = await (db.select(
      db.followedShops,
    )..where((t) => t.shopId.equals(shopId))).get().then((rows) => rows.length);

    final totalFollowers = followersCount + legacyFollowersCount;

    // Likes count across all products of this shop
    int totalLikes = 0;
    if (productIds.isNotEmpty) {
      final likeCountExpr = db.productLikes.id.count();
      final likeResult =
          await (db.selectOnly(db.productLikes)
                ..addColumns([likeCountExpr])
                ..where(db.productLikes.productId.isIn(productIds)))
              .getSingle();
      totalLikes = likeResult.read(likeCountExpr) ?? 0;
    }

    // Unique clients (unique phone numbers from contacts)
    final uniqueClients =
        await (db.selectOnly(db.userContacts)
              ..addColumns([db.userContacts.userPhone.count()])
              ..where(db.userContacts.shopId.equals(shopId)))
            .get()
            .then(
              (rows) => rows
                  .map((r) => r.read(db.userContacts.userPhone))
                  .toSet()
                  .length,
            );

    // Active stories count
    final now = DateTime.now();
    final storiesCount =
        (await (db.select(
              db.stories,
            )..where((t) => t.shopId.equals(shopId))).get())
            .where((s) => s.expiresAt.isAfter(now))
            .length;

    final stats = {
      // Views
      'view': shopViews,
      'product_view_global': productViews,
      'totalViews': shopViews + productViews,
      // Contacts
      'contact_whatsapp': contacts['whatsapp'] ?? 0,
      'contact_call': contacts['call'] ?? 0,
      'contact_sms': contacts['sms'] ?? 0,
      'totalContacts': contacts['total'] ?? 0,
      // Engagement
      'totalFollowers': totalFollowers,
      'totalLikes': totalLikes,
      'product_shares': productShares,
      'shop_shares': shopShares,
      'totalShares': productShares + shopShares,
      'uniqueClients': uniqueClients,
      // Meta
      'productsCount': products.length,
      'storiesCount': storiesCount,
    };

    try {
      final remote = await syncService?.fetchRemoteShopStats(shopId);
      if (remote != null) {
        _mergeRemoteShopStats(stats, remote);
      }
    } catch (e) {
      debugPrint('getShopStats remote merge error: $e');
    }

    return stats;
  }

  /// Get weekly stats (last 7 days) from real local events only.
  Future<Map<String, int>> getWeeklyStats(int shopId) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final products = await (db.select(
      db.products,
    )..where((t) => t.shopId.equals(shopId))).get();
    final productIds = products.map((p) => p.id).toList();
    final entityIds = <int>[shopId, ...productIds];

    if (entityIds.isEmpty) {
      return {'weeklyViews': 0, 'weeklyContacts': 0, 'weeklyShares': 0};
    }

    final recentAnalytics =
        await (db.select(db.analytics)..where(
              (t) =>
                  t.entityId.isIn(entityIds) &
                  t.createdAt.isBiggerOrEqualValue(weekAgo),
            ))
            .get();

    var weeklyViews = 0;
    var weeklyShares = 0;

    for (final a in recentAnalytics) {
      if (a.interactionType == 'view') {
        weeklyViews++;
      } else if (ShopStatsTypes.isShare(a.interactionType)) {
        weeklyShares++;
      }
    }

    final weeklyContacts = await (db.select(db.userContacts)..where(
          (t) =>
              t.shopId.equals(shopId) &
              t.createdAt.isBiggerOrEqualValue(weekAgo),
        ))
        .get()
        .then((rows) => rows.length);

    return {
      'weeklyViews': weeklyViews,
      'weeklyContacts': weeklyContacts,
      'weeklyShares': weeklyShares,
    };
  }

  /// Daily breakdown for the last 7 days (views per day).
  Future<List<int>> getDailyViewsBreakdown(int shopId) async {
    final products = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    final entityIds = <int>[shopId, ...products.map((p) => p.id)];
    if (entityIds.isEmpty) return List.filled(7, 0);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final analytics = await (db.select(db.analytics)..where(
          (t) =>
              t.entityId.isIn(entityIds) &
              t.interactionType.equals('view') &
              t.createdAt.isBiggerOrEqualValue(
                DateTime(weekAgo.year, weekAgo.month, weekAgo.day),
              ),
        ))
        .get();

    final counts = List.filled(7, 0);
    for (final a in analytics) {
      final dayIndex = a.createdAt.difference(
        DateTime(weekAgo.year, weekAgo.month, weekAgo.day),
      ).inDays;
      if (dayIndex >= 0 && dayIndex < 7) counts[dayIndex]++;
    }
    return counts;
  }

  /// Get regular clients (phones that contacted this shop multiple times)
  Future<List<Map<String, dynamic>>> getRegularClients(int shopId) async {
    final contacts =
        await (db.select(db.userContacts)
              ..where((t) => t.shopId.equals(shopId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    // Group by phone
    final phoneMap = <String, Map<String, dynamic>>{};
    for (final c in contacts) {
      final phone = c.userPhone;
      if (phoneMap.containsKey(phone)) {
        phoneMap[phone]!['contactCount'] =
            (phoneMap[phone]!['contactCount'] as int) + 1;
        // Keep the most recent contact time
        if (c.createdAt.isAfter(phoneMap[phone]!['lastContact'] as DateTime)) {
          phoneMap[phone]!['lastContact'] = c.createdAt;
        }
      } else {
        phoneMap[phone] = {
          'phone': phone,
          'contactCount': 1,
          'lastContact': c.createdAt,
        };
      }
    }

    // Only return phones with more than 1 contact, sorted by count descending
    final regulars =
        phoneMap.values.where((m) => (m['contactCount'] as int) > 1).toList()
          ..sort(
            (a, b) =>
                (b['contactCount'] as int).compareTo(a['contactCount'] as int),
          );

    return regulars;
  }

  /// Get recent activity for the activity timeline (last N interactions)
  Future<List<Map<String, dynamic>>> getRecentActivity(
    int shopId, {
    int limit = 10,
  }) async {
    final products = await (db.select(
      db.products,
    )..where((t) => t.shopId.equals(shopId))).get();
    final productIds = products.map((p) => p.id).toList();
    final entityIds = <int>[shopId, ...productIds];

    if (entityIds.isEmpty) return [];

    // Build a product name lookup
    final productNameMap = {for (final p in products) p.id: p.name};

    final recentAnalytics =
        await (db.select(db.analytics)
              ..where((t) => t.entityId.isIn(entityIds))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();

    return recentAnalytics.map((a) {
      final isContact = ['whatsapp', 'call', 'sms'].contains(a.interactionType);
      final productName = a.entityType == 'product'
          ? productNameMap[a.entityId] ?? 'Produit'
          : null;

      return {
        'interactionType': a.interactionType,
        'entityType': a.entityType,
        'entityId': a.entityId,
        'productName': productName,
        'isContact': isContact,
        'createdAt': a.createdAt,
      };
    }).toList();
  }

  /// Top products by local + synced view counts.
  Future<List<Map<String, dynamic>>> getTopViewedProducts(
    int shopId, {
    int limit = 5,
  }) async {
    final products = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    if (products.isEmpty) return [];

    final ranked = products
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'views': p.viewsCount,
          },
        )
        .toList()
      ..sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

    return ranked.take(limit).toList();
  }

  /// Funnel: views → WhatsApp contacts → orders (local analytics).
  Future<Map<String, dynamic>> getConversionMetrics(int shopId) async {
    final stats = await getShopStats(shopId);
    final views = stats['totalViews'] ?? 0;
    final whatsapp = stats['contact_whatsapp'] ?? 0;

    final ordersCount = await (db.select(db.orders)
          ..where((t) => t.shopId.equals(shopId)))
        .get()
        .then((rows) => rows.length);

    double rate(int numerator, int denominator) =>
        denominator == 0 ? 0 : (numerator / denominator) * 100;

    return {
      'views': views,
      'whatsapp': whatsapp,
      'orders': ordersCount,
      'viewToContact': rate(whatsapp, views),
      'contactToOrder': rate(ordersCount, whatsapp),
      'viewToOrder': rate(ordersCount, views),
    };
  }

  /// Best hours/days to publish (from views + shares + status events).
  Future<Map<String, dynamic>> getBestPublishTimes(int shopId) async {
    final products = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    final productIds = products.map((p) => p.id).toList();
    final entityIds = <int>[shopId, ...productIds];
    if (entityIds.isEmpty) {
      return {
        'hasData': false,
        'bestHour': null,
        'bestDay': null,
        'hourCounts': List<int>.filled(24, 0),
        'dayCounts': List<int>.filled(7, 0),
      };
    }

    final relevantTypes = {
      'view',
      ...ShopStatsTypes.synced.where((t) => t != ShopStatsTypes.view),
    };
    final rows = await (db.select(db.analytics)
          ..where((t) => t.entityId.isIn(entityIds)))
        .get();

    final hourCounts = List.filled(24, 0);
    final dayCounts = List.filled(7, 0);
    const dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    for (final a in rows) {
      if (!relevantTypes.contains(a.interactionType)) continue;
      hourCounts[a.createdAt.hour]++;
      final weekday = a.createdAt.weekday - 1;
      if (weekday >= 0 && weekday < 7) dayCounts[weekday]++;
    }

    var bestHour = 0;
    var maxHour = -1;
    for (var h = 0; h < 24; h++) {
      if (hourCounts[h] > maxHour) {
        maxHour = hourCounts[h];
        bestHour = h;
      }
    }

    var bestDayIndex = 0;
    var maxDay = -1;
    for (var d = 0; d < 7; d++) {
      if (dayCounts[d] > maxDay) {
        maxDay = dayCounts[d];
        bestDayIndex = d;
      }
    }

    final hasData = maxHour >= 0 && maxDay >= 0;

    return {
      'hasData': hasData,
      'bestHour': hasData ? bestHour : null,
      'bestDay': hasData ? dayNames[bestDayIndex] : null,
      'hourCounts': hourCounts,
      'dayCounts': dayCounts,
    };
  }

  /// Shops with GPS coordinates, sorted by distance when [userLat]/[userLng] set.
  Future<List<({Shop shop, double? distanceKm})>> getShopsByDistance({
    double? userLat,
    double? userLng,
  }) async {
    final shops = await (db.select(db.shops)).get();
    final withCoords = shops
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();

    if (userLat == null || userLng == null) {
      return withCoords.map((s) => (shop: s, distanceKm: null)).toList();
    }

    double distanceKm(Shop s) {
      const earthRadius = 6371.0;
      final dLat = _toRad(s.latitude! - userLat);
      final dLng = _toRad(s.longitude! - userLng);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_toRad(userLat)) *
              math.cos(_toRad(s.latitude!)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadius * c;
    }

    final ranked = withCoords
        .map((s) => (shop: s, distanceKm: distanceKm(s)))
        .toList()
      ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

    return ranked;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  // Shop Following Methods (using ShopFollows table with user tracking)
  Future<void> toggleFollowShop(int shopId, {String? userPhone}) async {
    final phone = userPhone ?? '';
    if (phone.isNotEmpty) {
      // New path: use ShopFollows table with user tracking
      final existing =
          await (db.select(db.shopFollows)..where(
                (t) => t.shopId.equals(shopId) & t.userPhone.equals(phone),
              ))
              .getSingleOrNull();

      if (existing != null) {
        await (db.delete(
          db.shopFollows,
        )..where((t) => t.id.equals(existing.id))).go();
        if (syncService != null) {
          final remoteShopId =
              await syncService!.resolveRemoteShopId(shopId);
          if (remoteShopId != null) {
            await syncService!.addToQueue('DELETE', 'shop_follows', {
              'shop_id': remoteShopId,
              'user_phone': phone,
            });
          }
        }
      } else {
        await db
            .into(db.shopFollows)
            .insert(
              ShopFollowsCompanion.insert(shopId: shopId, userPhone: phone),
            );
        if (syncService != null) {
          final remoteShopId =
              await syncService!.resolveRemoteShopId(shopId);
          if (remoteShopId != null) {
            await syncService!.addToQueue('CREATE', 'shop_follows', {
              'shop_id': remoteShopId,
              'user_phone': phone,
            });
          }
        }
      }
    } else {
      // Legacy path: use FollowedShops table (no user tracking)
      final entry = await (db.select(
        db.followedShops,
      )..where((t) => t.shopId.equals(shopId))).getSingleOrNull();

      if (entry != null) {
        await (db.delete(
          db.followedShops,
        )..where((t) => t.id.equals(entry.id))).go();
      } else {
        await db
            .into(db.followedShops)
            .insert(FollowedShopsCompanion.insert(shopId: shopId));
      }
    }
  }

  Stream<bool> watchIsFollowingShop(int shopId, {String? userPhone}) {
    final phone = userPhone ?? '';
    if (phone.isNotEmpty) {
      // New path: check ShopFollows table
      return (db.select(db.shopFollows)
            ..where((t) => t.shopId.equals(shopId) & t.userPhone.equals(phone)))
          .watch()
          .map((list) => list.isNotEmpty);
    }
    // Legacy path: check FollowedShops table
    return (db.select(db.followedShops)..where((t) => t.shopId.equals(shopId)))
        .watch()
        .map((list) => list.isNotEmpty);
  }

  Stream<List<Shop>> watchFollowedShops() {
    final query = db.select(db.shops).join([
      innerJoin(
        db.followedShops,
        db.followedShops.shopId.equalsExp(db.shops.id),
      ),
    ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(db.shops)).toList(),
    );
  }

  /// Get the follower count for a shop (from both ShopFollows and FollowedShops)
  Future<int> getFollowerCount(int shopId) async {
    final shopFollowsCount = await (db.select(
      db.shopFollows,
    )..where((t) => t.shopId.equals(shopId))).get().then((rows) => rows.length);
    final legacyFollowsCount = await (db.select(
      db.followedShops,
    )..where((t) => t.shopId.equals(shopId))).get().then((rows) => rows.length);
    return shopFollowsCount + legacyFollowsCount;
  }

  /// Watch follower count for a shop (reactive).
  Stream<int> watchFollowerCount(int shopId) {
    return (db.select(db.shopFollows)..where((t) => t.shopId.equals(shopId)))
        .watch()
        .map((rows) => rows.length);
  }

  /// Get unsynced shop follows for batch sync.
  Future<List<ShopFollow>> getUnsyncedFollows() {
    return (db.select(db.shopFollows)..where((t) => t.synced.equals(0))).get();
  }

  /// Mark follows as synced by their IDs.
  Future<void> markFollowsSynced(List<int> followIds) async {
    for (final id in followIds) {
      await (db.update(db.shopFollows)..where((t) => t.id.equals(id))).write(
        const ShopFollowsCompanion(synced: Value(1)),
      );
    }
  }

  /// Get shops in a specific commune
  Future<List<Shop>> getShopsByCommune(String commune) async {
    return (db.select(db.shops)..where((t) => t.commune.equals(commune))).get();
  }

  /// Get shops in neighboring communes (communes in the same city)
  Future<List<Shop>> getNearbyShops(String commune, {int limit = 10}) async {
    final neighbors = LocationData.getNeighboringCommunes(commune);
    if (neighbors.isEmpty) return [];

    return (db.select(db.shops)
          ..where((t) => t.commune.isIn(neighbors))
          ..limit(limit))
        .get();
  }

  /// Get shops in the same city (by commune lookup)
  Future<List<Shop>> getShopsInCity(String commune, {int limit = 20}) async {
    final city = LocationData.getCityForCommune(commune);
    if (city == null) return [];
    final communesInCity = LocationData.cities[city]!;

    return (db.select(db.shops)
          ..where((t) => t.commune.isIn(communesInCity))
          ..limit(limit))
        .get();
  }

  /// Get user's stored commune preference
  Future<String?> getUserCommune() async {
    final prefs = await (db.select(
      db.appPreferences,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    return prefs?.userCommune;
  }

  /// Set user's commune preference
  Future<void> setUserCommune(String commune) async {
    await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
      AppPreferencesCompanion(userCommune: Value(commune)),
    );
  }

  /// Fetch shops from local DB with pagination
  Future<PaginatedResult<Shop>> getShopsPaginated({
    int page = 1,
    int perPage = 20,
    String? searchQuery,
  }) async {
    final offset = (page - 1) * perPage;

    // Build predicate
    Expression<bool> predicate = const Constant(true);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = '%${searchQuery.toLowerCase()}%';
      predicate &=
          db.shops.name.lower().like(lowerQuery) |
          db.shops.description.lower().like(lowerQuery);
    }

    // Count total
    final countExpr = db.shops.id.count();
    final countResult =
        await (db.selectOnly(db.shops)
              ..addColumns([countExpr])
              ..where(predicate))
            .getSingle();
    final total = countResult.read(countExpr) ?? 0;

    // Fetch data
    final data =
        await (db.select(db.shops)
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

  static String _lastRankPrefKey(int shopId) => 'shop_last_rank_$shopId';

  /// Marks the shop as active now and syncs [last_active_at] to the server.
  Future<void> recordShopActivity(int shopId) async {
    final shop = await getShopById(shopId);
    if (shop == null) return;

    final now = DateTime.now();
    await (db.update(db.shops)..where((t) => t.id.equals(shopId))).write(
      ShopsCompanion(
        lastActiveAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    try {
      final ranking = await getLocalRanking(shopId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastRankPrefKey(shopId), ranking.rank);
    } catch (e) {
      debugPrint('recordShopActivity rank cache error: $e');
    }

    if (syncService == null) return;

    final remoteShopId =
        (shop.remoteId != null && shop.remoteId!.isNotEmpty)
            ? (int.tryParse(shop.remoteId!) ?? shop.id)
            : shop.id;

    await syncService!.addToQueue('UPDATE', 'shops', {
      'local_id': shop.id,
      'id': remoteShopId,
      'name': shop.name,
      'owner_id': shop.ownerId ?? '',
      'last_active_at': now.toIso8601String(),
    });
    unawaited(syncService!.forcePush());
  }

  Future<ShopTodayStats> getTodayStats(int shopId) async {
    final now = DateTime.now();
    final dayStart = startOfToday(now);

    final products = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    final productIds = products.map((p) => p.id).toList();
    final entityIds = <int>[shopId, ...productIds];

    var todayViews = 0;

    if (entityIds.isNotEmpty) {
      final rows = await (db.select(db.analytics)..where(
            (t) =>
                t.entityId.isIn(entityIds) &
                t.createdAt.isBiggerOrEqualValue(dayStart),
          ))
          .get();

      for (final row in rows) {
        if (row.interactionType == 'view') {
          todayViews++;
        }
      }
    }

    final todayWhatsapp = await (db.select(db.userContacts)..where(
          (t) =>
              t.shopId.equals(shopId) &
              t.contactType.equals('whatsapp') &
              t.createdAt.isBiggerOrEqualValue(dayStart),
        ))
        .get()
        .then((rows) => rows.length);

    final activeProducts = products.where((p) => !p.isSold).length;

    return ShopTodayStats(
      todayViews: todayViews,
      todayWhatsappClicks: todayWhatsapp,
      activeProducts: activeProducts,
    );
  }

  Future<Map<int, int>> _todayViewsByShopIds(
    Iterable<int> shopIds, {
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final dayStart = startOfToday(reference);
    final ids = shopIds.toSet().toList();
    if (ids.isEmpty) return {};

    final products = await (db.select(db.products)
          ..where((t) => t.shopId.isIn(ids)))
        .get();

    final shopByProduct = <int, int>{};
    for (final product in products) {
      shopByProduct[product.id] = product.shopId;
    }

    final views = {for (final id in ids) id: 0};

    final shopAnalytics = await (db.select(db.analytics)..where(
          (t) =>
              t.entityType.equals('shop') &
              t.entityId.isIn(ids) &
              t.interactionType.equals('view') &
              t.createdAt.isBiggerOrEqualValue(dayStart),
        ))
        .get();
    for (final row in shopAnalytics) {
      views[row.entityId] = (views[row.entityId] ?? 0) + 1;
    }

    if (shopByProduct.isNotEmpty) {
      final productIds = shopByProduct.keys.toList();
      final productAnalytics = await (db.select(db.analytics)..where(
            (t) =>
                t.entityType.equals('product') &
                t.entityId.isIn(productIds) &
                t.interactionType.equals('view') &
                t.createdAt.isBiggerOrEqualValue(dayStart),
          ))
          .get();
      for (final row in productAnalytics) {
        final shopId = shopByProduct[row.entityId];
        if (shopId != null) {
          views[shopId] = (views[shopId] ?? 0) + 1;
        }
      }
    }

    return views;
  }

  Future<ShopLocalRanking> getLocalRanking(int shopId) async {
    final shop = await getShopById(shopId);
    if (shop == null) {
      return const ShopLocalRanking(
        rank: 0,
        totalShops: 0,
        averageTodayViews: 0,
      );
    }

    final allShops = await db.select(db.shops).get();
    final commune = shop.commune?.trim();
    final peers = commune != null && commune.isNotEmpty
        ? allShops
              .where(
                (s) => (s.commune ?? '').toLowerCase() == commune.toLowerCase(),
              )
              .toList()
        : allShops;

    if (peers.isEmpty) {
      return ShopLocalRanking(
        rank: 1,
        totalShops: 1,
        averageTodayViews: 0,
        communeLabel: commune,
      );
    }

    final now = DateTime.now();
    final viewsByShop = await _todayViewsByShopIds(
      peers.map((s) => s.id),
      now: now,
    );

    final ranked = peers.map((s) {
      return (shop: s, views: viewsByShop[s.id] ?? 0);
    }).toList()
      ..sort((a, b) {
        final viewCompare = b.views.compareTo(a.views);
        if (viewCompare != 0) return viewCompare;
        final aActive = isShopActiveToday(a.shop, now);
        final bActive = isShopActiveToday(b.shop, now);
        if (aActive != bActive) return aActive ? -1 : 1;
        return a.shop.name.compareTo(b.shop.name);
      });

    var rank = ranked.length;
    for (var i = 0; i < ranked.length; i++) {
      if (ranked[i].shop.id == shopId) {
        rank = i + 1;
        break;
      }
    }

    final viewValues = viewsByShop.values.where((v) => v > 0).toList();
    final average = viewValues.isEmpty
        ? 0
        : (viewValues.reduce((a, b) => a + b) / viewValues.length).round();

    final prefs = await SharedPreferences.getInstance();
    final previousRank = prefs.getInt(_lastRankPrefKey(shopId));

    return ShopLocalRanking(
      rank: rank,
      totalShops: peers.length,
      averageTodayViews: average,
      communeLabel: commune,
      previousRank: previousRank,
    );
  }

  Future<ShopVisibilityInsight> getVisibilityInsight(int shopId) async {
    final shop = await getShopById(shopId);
    if (shop == null) {
      return ShopVisibilityInsight(
        today: const ShopTodayStats(
          todayViews: 0,
          todayWhatsappClicks: 0,
          activeProducts: 0,
        ),
        ranking: const ShopLocalRanking(
          rank: 0,
          totalShops: 0,
          averageTodayViews: 0,
        ),
        isActiveToday: false,
        daysSinceActivity: 0,
      );
    }

    final now = DateTime.now();
    final today = await getTodayStats(shopId);
    final ranking = await getLocalRanking(shopId);

    return ShopVisibilityInsight(
      today: today,
      ranking: ranking,
      isActiveToday: isShopActiveToday(shop, now),
      daysSinceActivity: daysSinceLastActivity(shop, now),
    );
  }
}
