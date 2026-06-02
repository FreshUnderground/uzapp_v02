import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class OrderRepository {
  final UzaDatabase db;

  OrderRepository(this.db);

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
  }) {
    return db.into(db.orders).insert(
          OrdersCompanion.insert(
            buyerPhone: buyerPhone,
            shopId: shopId,
            itemsJson: jsonEncode(items),
            note: Value(note),
          ),
        );
  }

  Future<void> updateStatus(int orderId, String status) {
    return (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
