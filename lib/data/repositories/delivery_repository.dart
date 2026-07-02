import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/uza_database.dart';
import '../../core/services/api_service.dart';
import '../../core/services/delivery_notification_helper.dart';
import '../../data/services/sync_service.dart';

class DeliveryRepository {
  final UzaDatabase db;

  DeliveryRepository(this.db);

  Stream<List<Delivery>> watchForBuyer(String buyerPhone) {
    return (db.select(db.deliveries)
          ..where((t) => t.buyerPhone.equals(buyerPhone))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Delivery>> watchForShop(int shopId) {
    return (db.select(db.deliveries)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Delivery>> watchPendingForShop(int shopId) {
    return (db.select(db.deliveries)
          ..where(
            (t) =>
                t.shopId.equals(shopId) &
                t.status.isIn([
                  'pending',
                  'accepted',
                  'in_transit',
                ]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<int> createDelivery({
    required String buyerPhone,
    String? buyerName,
    required int shopId,
    int? productId,
    List<Map<String, dynamic>> items = const [],
    String? deliveryAddress,
    String? deliveryCommune,
    double? latitude,
    double? longitude,
    String locationMode = 'commune',
    String? note,
    SyncService? syncService,
  }) async {
    final id = await db.into(db.deliveries).insert(
          DeliveriesCompanion.insert(
            buyerPhone: buyerPhone,
            buyerName: Value(buyerName),
            shopId: shopId,
            productId: Value(productId),
            itemsJson: Value(jsonEncode(items)),
            deliveryAddress: Value(deliveryAddress),
            deliveryCommune: Value(deliveryCommune),
            latitude: Value(latitude),
            longitude: Value(longitude),
            locationMode: Value(locationMode),
            note: Value(note),
            synced: const Value(0),
          ),
        );

    await _queueSync(
      syncService: syncService,
      action: 'CREATE',
      localId: id,
      buyerPhone: buyerPhone,
      buyerName: buyerName,
      shopId: shopId,
      productId: productId,
      items: items,
      status: 'pending',
      deliveryAddress: deliveryAddress,
      deliveryCommune: deliveryCommune,
      latitude: latitude,
      longitude: longitude,
      locationMode: locationMode,
      note: note,
    );
    return id;
  }

  Future<void> updateStatus(
    int deliveryId,
    String status, {
    SyncService? syncService,
  }) async {
    final row = await (db.select(db.deliveries)
          ..where((t) => t.id.equals(deliveryId)))
        .getSingleOrNull();
    if (row == null) return;

    await (db.update(db.deliveries)..where((t) => t.id.equals(deliveryId)))
        .write(
      DeliveriesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        synced: const Value(0),
      ),
    );

    await _queueSync(
      syncService: syncService,
      action: 'UPDATE',
      localId: deliveryId,
      remoteId: row.remoteId,
      buyerPhone: row.buyerPhone,
      buyerName: row.buyerName,
      shopId: row.shopId,
      productId: row.productId,
      items: parseItems(row.itemsJson),
      status: status,
      deliveryAddress: row.deliveryAddress,
      deliveryCommune: row.deliveryCommune,
      latitude: row.latitude,
      longitude: row.longitude,
      locationMode: row.locationMode,
      note: row.note,
    );
  }

  Future<void> pullRemote({
    required ApiService apiService,
    String? buyerPhone,
    int? shopId,
    DateTime? updatedSince,
  }) async {
    final rows = await apiService.fetchDeliveries(
      buyerPhone: buyerPhone,
      shopId: shopId,
      updatedSince: updatedSince,
    );
    for (final row in rows) {
      await _upsertFromServer(
        row,
        localShopId: shopId,
        notifySeller: shopId != null,
      );
    }
  }

  Future<void> _upsertFromServer(
    Map<String, dynamic> row, {
    int? localShopId,
    bool notifySeller = false,
  }) async {
    final remoteId = row['id']?.toString();
    if (remoteId == null) return;

    final existing = await (db.select(db.deliveries)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();

    final serverShopId = _parseInt(row['shop_id']);
    var resolvedShopId = 0;
    if (serverShopId != null) {
      final shopByRemote = await (db.select(db.shops)
            ..where((t) => t.remoteId.equals(serverShopId.toString())))
          .getSingleOrNull();
      resolvedShopId =
          shopByRemote?.id ?? localShopId ?? serverShopId;
    } else if (localShopId != null) {
      resolvedShopId = localShopId;
    }

    int? localProductId;
    final serverProductId = _parseInt(row['product_id']);
    if (serverProductId != null) {
      final product = await (db.select(db.products)
            ..where((t) => t.remoteId.equals(serverProductId.toString())))
          .getSingleOrNull();
      localProductId = product?.id ?? serverProductId;
    }

    final companion = DeliveriesCompanion(
      buyerPhone: Value(row['buyer_phone']?.toString() ?? ''),
      buyerName: Value(row['buyer_name']?.toString()),
      shopId: Value(resolvedShopId),
      productId: Value(localProductId),
      status: Value(row['status']?.toString() ?? 'pending'),
      itemsJson: Value(
        row['items_json'] is String
            ? row['items_json'] as String
            : jsonEncode(row['items_json'] ?? []),
      ),
      deliveryAddress: Value(row['delivery_address']?.toString()),
      deliveryCommune: Value(row['delivery_commune']?.toString()),
      latitude: Value(_parseDouble(row['latitude'])),
      longitude: Value(_parseDouble(row['longitude'])),
      locationMode: Value(row['location_mode']?.toString() ?? 'commune'),
      note: Value(row['note']?.toString()),
      remoteId: Value(remoteId),
      synced: const Value(1),
      updatedAt: Value(
        DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );

    if (existing != null) {
      await (db.update(db.deliveries)..where((t) => t.id.equals(existing.id)))
          .write(companion);
    } else {
      final newId = await db.into(db.deliveries).insert(companion);
      final status = row['status']?.toString() ?? 'pending';
      if (notifySeller &&
          status == 'pending' &&
          resolvedShopId > 0) {
        final buyerLabel =
            row['buyer_name']?.toString().trim().isNotEmpty == true
            ? row['buyer_name'].toString()
            : (row['buyer_phone']?.toString() ?? 'Client');
        await DeliveryNotificationHelper.notifySellerNewDelivery(
          deliveryLocalId: newId,
          shopLocalId: resolvedShopId,
          buyerLabel: buyerLabel,
        );
      }
    }
  }

  Future<void> _queueSync({
    SyncService? syncService,
    required String action,
    required int localId,
    String? remoteId,
    required String buyerPhone,
    String? buyerName,
    required int shopId,
    int? productId,
    required List<Map<String, dynamic>> items,
    required String status,
    String? deliveryAddress,
    String? deliveryCommune,
    double? latitude,
    double? longitude,
    String? locationMode,
    String? note,
  }) async {
    if (syncService == null) return;

    int? serverShopId = shopId;
    final shop = await (db.select(db.shops)..where((t) => t.id.equals(shopId)))
        .getSingleOrNull();
    if (shop?.remoteId != null && shop!.remoteId!.isNotEmpty) {
      serverShopId = int.tryParse(shop.remoteId!) ?? shopId;
    }

    int? serverProductId;
    if (productId != null) {
      final product = await (db.select(db.products)
            ..where((t) => t.id.equals(productId)))
          .getSingleOrNull();
      if (product?.remoteId != null && product!.remoteId!.isNotEmpty) {
        serverProductId = int.tryParse(product.remoteId!);
      } else {
        serverProductId = productId;
      }
    }

    await syncService.addToQueue(action, 'deliveries', {
      if (remoteId != null) 'id': int.tryParse(remoteId),
      'local_id': localId,
      'buyer_phone': buyerPhone,
      if (buyerName != null) 'buyer_name': buyerName,
      'shop_id': serverShopId,
      if (serverProductId != null) 'product_id': serverProductId,
      'status': status,
      'items_json': jsonEncode(items),
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryCommune != null) 'delivery_commune': deliveryCommune,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationMode != null) 'location_mode': locationMode,
      if (note != null) 'note': note,
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
