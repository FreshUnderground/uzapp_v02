import 'package:drift/drift.dart';

import '../local/uza_database.dart';

class ProductUpdateRepository {
  final UzaDatabase db;

  ProductUpdateRepository(this.db);

  Stream<List<ProductUpdate>> watchRecent({int limit = 30}) {
    return (db.select(db.productUpdates)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<List<ProductUpdate>> getRecent({int limit = 30}) {
    return (db.select(db.productUpdates)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<List<ProductUpdate>> getSince(DateTime since) {
    return (db.select(db.productUpdates)
          ..where((t) => t.createdAt.isBiggerThanValue(since))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> insertUpdate(ProductUpdatesCompanion row) {
    return db.into(db.productUpdates).insert(row);
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final remoteId = row['id']?.toString();
    if (remoteId == null || remoteId.isEmpty) return;

    final existing = await (db.select(db.productUpdates)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();

    final serverProductId = _toInt(row['product_id']);
    final serverShopId = _toInt(row['shop_id']);
    if (serverProductId == null || serverShopId == null) return;

    final localProductId = await _resolveLocalProductId(serverProductId);
    final localShopId = await _resolveLocalShopId(serverShopId);
    if (localProductId == null || localShopId == null) return;

    final companion = ProductUpdatesCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      remoteId: Value(remoteId),
      productId: Value(localProductId),
      shopId: Value(localShopId),
      updateType: Value(row['update_type']?.toString() ?? 'note'),
      message: Value(row['message'] as String?),
      productName: Value(row['product_name']?.toString() ?? 'Produit'),
      shopName: Value(row['shop_name']?.toString() ?? 'Boutique'),
      synced: const Value(1),
      createdAt: Value(
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );

    await db.into(db.productUpdates).insertOnConflictUpdate(companion);
  }

  Future<int?> _resolveLocalProductId(int serverProductId) async {
    final byRemote = await (db.select(db.products)
          ..where((t) => t.remoteId.equals('$serverProductId')))
        .getSingleOrNull();
    if (byRemote != null) return byRemote.id;

    final byId = await (db.select(db.products)
          ..where((t) => t.id.equals(serverProductId)))
        .getSingleOrNull();
    return byId?.id;
  }

  Future<int?> _resolveLocalShopId(int serverShopId) async {
    final byRemote = await (db.select(db.shops)
          ..where((t) => t.remoteId.equals('$serverShopId')))
        .getSingleOrNull();
    if (byRemote != null) return byRemote.id;

    final byId = await (db.select(db.shops)
          ..where((t) => t.id.equals(serverShopId)))
        .getSingleOrNull();
    return byId?.id;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
