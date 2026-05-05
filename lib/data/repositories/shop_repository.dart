import 'package:drift/drift.dart';
import '../local/uza_database.dart';
import 'location_data.dart';
import 'paginated_result.dart';

class ShopRepository {
  final UzaDatabase db;

  ShopRepository(this.db);

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

  Future<Shop?> getShopById(int id) {
    return (db.select(
      db.shops,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Shop?> watchUserShop(String userId) {
    return (db.select(
      db.shops,
    )..where((t) => t.ownerId.equals(userId))).watchSingleOrNull();
  }

  /// Watch all shops owned by a given user (by ownerId / phone number).
  Stream<List<Shop>> watchUserShops(String userId) {
    return (db.select(
      db.shops,
    )..where((t) => t.ownerId.equals(userId))).watch();
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

    // 2. Match by shop's phone field (owner might have used the same
    //    number for both the shop contact and their login).
    final phoneMatch = await (db.select(
      db.shops,
    )..where((t) => t.phone.equals(userId) | t.whatsapp.equals(userId))).get();
    for (final shop in phoneMatch) {
      if (shop.ownerId == null || shop.ownerId!.isEmpty) {
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(ownerId: Value(userId)),
        );
      }
    }

    // 3. Handle common DRC phone-number format differences.
    //    e.g. "0823456789" vs "+243823456789" vs "243823456789"
    final variations = _phoneVariations(userId);
    for (final variant in variations) {
      if (variant == userId) continue;
      final variantMatch = await (db.select(
        db.shops,
      )..where((t) => t.ownerId.equals(variant))).get();
      for (final shop in variantMatch) {
        // Normalise ownerId to the current uid format
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(ownerId: Value(userId)),
        );
      }
    }
  }

  /// Generate common phone-number format variations for DRC numbers.
  /// e.g. "+243823456789" → ["0823456789", "243823456789", "+243823456789"]
  List<String> _phoneVariations(String phone) {
    final variations = <String>[phone];
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('243') && digits.length >= 12) {
      // +243823456789 → 0823456789
      variations.add('0${digits.substring(3)}');
      variations.add(digits);
    } else if (digits.startsWith('0') && digits.length >= 10) {
      // 0823456789 → +243823456789 and 243823456789
      final withoutLeading0 = digits.substring(1);
      variations.add('243$withoutLeading0');
      variations.add('+243$withoutLeading0');
    }

    return variations.toSet().toList();
  }

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

    int totalViews = 0;
    int totalContacts = 0;
    int totalShares = 0;

    for (final a in allAnalytics) {
      switch (a.interactionType) {
        case 'view':
          totalViews++;
          break;
        case 'whatsapp':
        case 'call':
        case 'sms':
          totalContacts++;
          break;
        case 'share':
          totalShares++;
          break;
      }
    }

    // Also add global synced product views/shares from Products table
    for (final p in products) {
      totalViews += p.viewsCount;
      totalShares += p.sharesCount;
    }

    // Followers count
    final followersCount = await (db.select(
      db.followedShops,
    )..where((t) => t.shopId.equals(shopId))).get().then((rows) => rows.length);

    // Active stories count
    final now = DateTime.now();
    final storiesCount =
        (await (db.select(
              db.stories,
            )..where((t) => t.shopId.equals(shopId))).get())
            .where((s) => s.expiresAt.isAfter(now))
            .length;

    return {
      'totalViews': totalViews,
      'totalContacts': totalContacts,
      'totalShares': totalShares,
      'totalFollowers': followersCount,
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

  // Shop Following Methods
  Future<void> toggleFollowShop(int shopId) async {
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

  Stream<bool> watchIsFollowingShop(int shopId) {
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
