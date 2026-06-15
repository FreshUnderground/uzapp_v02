import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../local/uza_database.dart';
import 'location_data.dart';
import 'paginated_result.dart';
import '../services/sync_service.dart';
import '../../core/utils/phone_utils.dart';

class ShopRepository {
  final UzaDatabase db;
  final SyncService? syncService;

  ShopRepository(this.db, {this.syncService});

  Stream<List<Shop>> watchAllShops() {
    return db.select(db.shops).watch();
  }

  Stream<List<Shop>> watchFeaturedShops() {
    return db.select(db.shops).watch().map((items) {
      // Prioritize shops with ACTIVE boost status
      final boosted = items.where((s) => s.boostStatus == 2).toList()
        ..shuffle();
      final regular = items.where((s) => s.boostStatus != 2).toList()
        ..shuffle();
      return [...boosted, ...regular];
    });
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

  Future<Shop?> getShopById(int id) {
    return (db.select(
      db.shops,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Resolves a shop for deep links: local DB first, then public API.
  Future<Shop?> resolveShopById(int id) async {
    final local = await getShopById(id);
    if (local != null) return local;

    final byRemote = await (db.select(db.shops)
          ..where((t) => t.remoteId.equals(id.toString())))
        .getSingleOrNull();
    if (byRemote != null) return byRemote;

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
      await db.into(db.shops).insert(
        ShopsCompanion(
          id: Value(resolvedId),
          remoteId: Value(
            remoteId != null && remoteId.isNotEmpty
                ? remoteId
                : resolvedId.toString(),
          ),
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
        mode: InsertMode.insertOrReplace,
      );
      return getShopById(resolvedId);
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

    // 1. Direct match — ownerId already equals the user's uid
    final directMatch = await (db.select(
      db.shops,
    )..where((t) => t.ownerId.equals(userId))).get();
    if (directMatch.isNotEmpty) return; // Already linked

    // 2. Match by shop contact fields (owner might have used the same
    //    number for both the shop contact and their login), including
    //    common DRC phone-number format differences.
    final variations = _phoneVariations(userId);
    final allShops = await db.select(db.shops).get();
    for (final shop in allShops) {
      if (!_shopBelongsToUser(shop, userId)) continue;
      if (shop.ownerId != userId) {
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(ownerId: Value(userId)),
        );
      }
    }

    // 3. Handle ownerId-only variations missed above.
    for (final variant in variations) {
      if (variant == userId) continue;
      final variantMatch = await (db.select(
        db.shops,
      )..where((t) => t.ownerId.equals(variant))).get();
      for (final shop in variantMatch) {
        // Normalise ownerId to the current uid format
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(
            ownerId: Value(PhoneUtils.normalizeDrc(userId).isNotEmpty
                ? PhoneUtils.normalizeDrc(userId)
                : userId),
          ),
        );
      }
    }

    await syncService?.repairProductShopLinks();
  }

  bool _shopBelongsToUser(Shop shop, String userId) {
    final variations = _phoneVariations(userId);
    return _matchesAnyPhone(shop.ownerId, variations) ||
        _matchesAnyPhone(shop.phone, variations) ||
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

  Future<int> addShop(ShopsCompanion shop) {
    return db.into(db.shops).insert(shop);
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
    int totalContacts = 0;
    int totalShares = 0;
    int whatsappContacts = 0;
    int callContacts = 0;
    int smsContacts = 0;

    for (final a in allAnalytics) {
      switch (a.interactionType) {
        case 'view':
          if (a.entityType == 'shop') {
            shopViews++;
          } else {
            productViews++;
          }
          break;
        case 'whatsapp':
          totalContacts++;
          whatsappContacts++;
          break;
        case 'call':
          totalContacts++;
          callContacts++;
          break;
        case 'sms':
          totalContacts++;
          smsContacts++;
          break;
        case 'share':
          totalShares++;
          break;
      }
    }

    // Also add global synced product views/shares from Products table
    for (final p in products) {
      productViews += p.viewsCount;
      totalShares += p.sharesCount;
    }

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

    return {
      // Views
      'view': shopViews,
      'product_view_global': productViews,
      'totalViews': shopViews + productViews,
      // Contacts
      'contact_whatsapp': whatsappContacts,
      'contact_call': callContacts,
      'contact_sms': smsContacts,
      'totalContacts': totalContacts,
      // Engagement
      'totalFollowers': totalFollowers,
      'totalLikes': totalLikes,
      'totalShares': totalShares,
      'uniqueClients': uniqueClients,
      // Meta
      'productsCount': products.length,
      'storiesCount': storiesCount,
    };
  }

  /// Get weekly stats (last 7 days)
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

    int weeklyViews = 0;
    int weeklyContacts = 0;
    int weeklyShares = 0;

    for (final a in recentAnalytics) {
      switch (a.interactionType) {
        case 'view':
          weeklyViews++;
          break;
        case 'whatsapp':
        case 'call':
        case 'sms':
          weeklyContacts++;
          break;
        case 'share':
          weeklyShares++;
          break;
      }
    }

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

    final productIds = products.map((p) => p.id).toList();
    final viewCounts = <int, int>{};

    for (final p in products) {
      viewCounts[p.id] = p.viewsCount;
    }

    final localViews = await (db.select(db.analytics)..where(
          (t) =>
              t.entityType.equals('product') &
              t.entityId.isIn(productIds) &
              t.interactionType.equals('view'),
        ))
        .get();
    for (final a in localViews) {
      viewCounts[a.entityId] = (viewCounts[a.entityId] ?? 0) + 1;
    }

    final ranked = products
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'views': viewCounts[p.id] ?? 0,
          },
        )
        .toList()
      ..sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

    return ranked.take(limit).toList();
  }

  /// Funnel: views → WhatsApp contacts → orders (local analytics).
  Future<Map<String, dynamic>> getConversionMetrics(int shopId) async {
    final products = await (db.select(db.products)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    final productIds = products.map((p) => p.id).toList();
    final entityIds = <int>[shopId, ...productIds];

    int views = 0;
    int whatsapp = 0;
    if (entityIds.isNotEmpty) {
      final rows = await (db.select(db.analytics)
            ..where((t) => t.entityId.isIn(entityIds)))
          .get();
      for (final a in rows) {
        if (a.interactionType == 'view') views++;
        if (a.interactionType == 'whatsapp') whatsapp++;
      }
    }
    for (final p in products) {
      views += p.viewsCount;
    }

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
      return {'bestHour': 18, 'bestDay': 'Vendredi', 'hourCounts': List.filled(24, 0)};
    }

    final relevantTypes = {
      'view',
      'share',
      'whatsapp_status',
      'facebook_status',
      'tiktok_status',
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

    var bestHour = 18;
    var maxHour = -1;
    for (var h = 0; h < 24; h++) {
      if (hourCounts[h] > maxHour) {
        maxHour = hourCounts[h];
        bestHour = h;
      }
    }

    var bestDayIndex = 4;
    var maxDay = -1;
    for (var d = 0; d < 7; d++) {
      if (dayCounts[d] > maxDay) {
        maxDay = dayCounts[d];
        bestDayIndex = d;
      }
    }

    return {
      'bestHour': bestHour,
      'bestDay': dayNames[bestDayIndex],
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
          await syncService!.addToQueue('DELETE', 'shop_follows', {
            'shop_id': shopId,
            'user_phone': phone,
          });
        }
      } else {
        await db
            .into(db.shopFollows)
            .insert(
              ShopFollowsCompanion.insert(shopId: shopId, userPhone: phone),
            );
        if (syncService != null) {
          await syncService!.addToQueue('CREATE', 'shop_follows', {
            'shop_id': shopId,
            'user_phone': phone,
          });
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
}
