import '../../data/local/uza_database.dart';

/// Removes test/CRUD artifacts from the local Drift database after server cleanup.
class TestDataCleanup {
  TestDataCleanup._();

  static bool _isTestShop(Shop shop) {
    final owner = (shop.ownerId ?? '').toUpperCase();
    final name = shop.name.toUpperCase();
    if (owner.contains('CRUD')) return true;
    if (owner.startsWith('999888')) return true;
    if (owner.contains('777666555')) return true;
    if (name.contains('CRUD')) return true;
    if (name.contains('MINIMAL NAME UPDATE')) return true;
    return false;
  }

  static bool _isTestProduct(Product product) {
    final name = product.name.toUpperCase();
    if (name.contains('CRUD')) return true;
    if (name.contains('PROMO UPDATE TEST')) return true;
    if (name.contains('ID CHECK PRODUCT')) return true;
    if (name.contains('READTIMINGTEST')) return true;
    return false;
  }

  static Future<int> purgeLocal(UzaDatabase db) async {
    var removed = 0;

    final testShops = await db.select(db.shops).get();
    final testShopIds = testShops.where(_isTestShop).map((s) => s.id).toSet();

    if (testShopIds.isNotEmpty) {
      for (final shopId in testShopIds) {
        await (db.delete(db.products)..where((t) => t.shopId.equals(shopId)))
            .go();
        final storyIds = await (db.select(db.stories)
              ..where((t) => t.shopId.equals(shopId)))
            .map((s) => s.id)
            .get();
        for (final storyId in storyIds) {
          await (db.delete(db.storyMedia)
                ..where((t) => t.storyId.equals(storyId)))
              .go();
        }
        await (db.delete(db.stories)..where((t) => t.shopId.equals(shopId)))
            .go();
        await (db.delete(db.deliveries)..where((t) => t.shopId.equals(shopId)))
            .go();
        await (db.delete(db.orders)..where((t) => t.shopId.equals(shopId)))
            .go();
        await (db.delete(db.shops)..where((t) => t.id.equals(shopId))).go();
        removed++;
      }
    }

    final testProducts = await db.select(db.products).get();
    for (final p in testProducts.where(_isTestProduct)) {
      await (db.delete(db.products)..where((t) => t.id.equals(p.id))).go();
      removed++;
    }

    final testDeliveries = (await db.select(db.deliveries).get())
        .where((d) {
          final phone = d.buyerPhone.toUpperCase();
          return phone.contains('CRUD') ||
              phone.startsWith('999888') ||
              phone.contains('777666555');
        })
        .toList();
    for (final d in testDeliveries) {
      await (db.delete(db.deliveries)..where((t) => t.id.equals(d.id))).go();
      removed++;
    }

    return removed;
  }
}
