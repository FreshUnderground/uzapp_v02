import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/uza_database.dart';
import '../../core/services/api_service.dart';
import '../../data/services/sync_service.dart';

class OrderRepository {
  final UzaDatabase db;
  final ApiService? api;

  OrderRepository(this.db, {this.api});

  Stream<List<Order>> watchOrdersForBuyer(String buyerPhone) {
    return (db.select(db.orders)
          ..where((t) => t.buyerPhone.equals(buyerPhone))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Order>> watchOrdersForShop(int shopId) {
    return (db.select(db.orders)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<int> createOrder({
    required String buyerPhone,
    required int shopId,
    required List<Map<String, dynamic>> items,
    String? note,
    String status = 'requested',
    SyncService? syncService,
  }) async {
    final id = await db.into(db.orders).insert(
          OrdersCompanion.insert(
            buyerPhone: buyerPhone,
            shopId: shopId,
            itemsJson: jsonEncode(items),
            note: Value(note),
            status: Value(status),
            synced: const Value(0),
          ),
        );

    await _queueSync(
      syncService: syncService,
      action: 'CREATE',
      localId: id,
      buyerPhone: buyerPhone,
      shopId: shopId,
      items: items,
      note: note,
      status: status,
    );
    return id;
  }

  Future<void> updateStatus(
    int orderId,
    String status, {
    SyncService? syncService,
  }) async {
    final order = await (db.select(db.orders)
          ..where((t) => t.id.equals(orderId)))
        .getSingleOrNull();
    if (order == null) return;

    await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        synced: const Value(0),
      ),
    );

    await _queueSync(
      syncService: syncService,
      action: 'UPDATE',
      localId: orderId,
      remoteId: order.remoteId,
      buyerPhone: order.buyerPhone,
      shopId: order.shopId,
      items: parseItems(order.itemsJson),
      note: order.note,
      status: status,
    );
  }

  Future<void> markPendingPayment(int orderId, {SyncService? syncService}) =>
      updateStatus(orderId, 'pending_payment', syncService: syncService);

  Future<void> pullRemoteOrders({
    required ApiService apiService,
    String? buyerPhone,
    int? shopId,
    DateTime? updatedSince,
  }) async {
    final rows = await apiService.fetchOrders(
      buyerPhone: buyerPhone,
      shopId: shopId,
      updatedSince: updatedSince,
    );
    for (final row in rows) {
      await _upsertFromServer(row, localShopId: shopId);
    }
  }

  Future<void> _upsertFromServer(
    Map<String, dynamic> row, {
    int? localShopId,
  }) async {
    final remoteId = row['id']?.toString();
    if (remoteId == null) return;

    final existing = await (db.select(db.orders)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();

    final serverShopId = (row['shop_id'] as num?)?.toInt();
    var resolvedShopId = localShopId ?? serverShopId ?? 0;
    if (localShopId == null && serverShopId != null) {
      final shop = await (db.select(db.shops)
            ..where((t) => t.remoteId.equals(serverShopId.toString())))
          .getSingleOrNull();
      if (shop != null) resolvedShopId = shop.id;
    }

    final companion = OrdersCompanion(
      buyerPhone: Value(row['buyer_phone']?.toString() ?? ''),
      shopId: Value(resolvedShopId),
      status: Value(row['status']?.toString() ?? 'requested'),
      itemsJson: Value(
        row['items_json'] is String
            ? row['items_json'] as String
            : jsonEncode(row['items_json'] ?? []),
      ),
      note: Value(row['note']?.toString()),
      remoteId: Value(remoteId),
      synced: const Value(1),
      updatedAt: Value(
        DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );

    if (existing != null) {
      await (db.update(db.orders)..where((t) => t.id.equals(existing.id)))
          .write(companion);
    } else {
      await db.into(db.orders).insert(companion);
    }
  }

  Future<void> _queueSync({
    SyncService? syncService,
    required String action,
    required int localId,
    String? remoteId,
    required String buyerPhone,
    required int shopId,
    required List<Map<String, dynamic>> items,
    String? note,
    required String status,
  }) async {
    if (syncService == null) return;

    int? serverShopId = shopId;
    final shop = await (db.select(db.shops)..where((t) => t.id.equals(shopId)))
        .getSingleOrNull();
    if (shop?.remoteId != null && shop!.remoteId!.isNotEmpty) {
      serverShopId = int.tryParse(shop.remoteId!) ?? shopId;
    }

    await syncService.addToQueue(action, 'orders', {
      if (remoteId != null) 'id': int.tryParse(remoteId),
      'local_id': localId,
      'buyer_phone': buyerPhone,
      'shop_id': serverShopId,
      'status': status,
      'items_json': jsonEncode(items),
      'note': note,
    });
  }

  List<Map<String, dynamic>> parseItems(String itemsJson) {
    try {
      final decoded = jsonDecode(itemsJson);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
