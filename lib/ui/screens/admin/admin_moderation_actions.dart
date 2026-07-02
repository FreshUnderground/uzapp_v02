import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/tr.dart';
import '../../../data/local/uza_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/shop_repository.dart';
import '../../../data/services/sync_service.dart';

/// Shared admin actions: shop verification and product removal.
class AdminModerationActions {
  AdminModerationActions._();

  static Future<void> setShopVerified(
    BuildContext context,
    Shop shop,
    bool verify,
  ) async {
    final shopRepo = context.read<ShopRepository>();
    final syncService = context.read<SyncService>();

    await shopRepo.updateShop(
      ShopsCompanion(
        id: drift.Value(shop.id),
        isVerified: drift.Value(verify),
        verifiedAt: verify
            ? drift.Value(DateTime.now())
            : const drift.Value.absent(),
      ),
    );

    final remoteShopId =
        (shop.remoteId != null && shop.remoteId!.isNotEmpty)
            ? (int.tryParse(shop.remoteId!) ?? shop.id)
            : shop.id;

    await syncService.addToQueue('UPDATE', 'shops', {
      'local_id': shop.id,
      'id': remoteShopId,
      'name': shop.name,
      'owner_id': shop.ownerId ?? '',
      'is_verified': verify ? 1 : 0,
      'verified_at': verify ? DateTime.now().toIso8601String() : null,
    });
    unawaited(syncService.forcePush());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verify
              ? tr(context, 'shop_verified')
              : tr(context, 'verification_removed'),
        ),
      ),
    );
  }

  static Future<bool> confirmDeleteProduct(
    BuildContext context,
    String productName,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'admin_delete_product')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'admin_delete_product_confirm')),
            if (productName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'delete')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  static Future<bool> deleteProduct(
    BuildContext context, {
    int? localProductId,
    int? serverProductId,
    String? productName,
  }) async {
    if (productName != null &&
        productName.isNotEmpty &&
        !await confirmDeleteProduct(context, productName)) {
      return false;
    }

    final repo = context.read<ProductRepository>();
    final deleted = await repo.adminDeleteProduct(
      localId: localProductId,
      serverProductId: serverProductId,
    );

    if (!context.mounted) return deleted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? tr(context, 'admin_product_deleted')
              : tr(context, 'admin_delete_failed'),
        ),
      ),
    );
    return deleted;
  }
}
