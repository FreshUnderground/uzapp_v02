import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/local/uza_database.dart';
import '../../../../data/services/sync_service.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/services/auth_service.dart';
import '../admin_moderation_actions.dart';
import 'admin_moderation_panel.dart';
import '../../../components/async_content.dart';
import '../../../components/empty_state.dart';
import 'package:drift/drift.dart' as drift;

/// Validation workflows: promotions, product boosts, shop verification.
class AdminValidationTab extends StatelessWidget {
  const AdminValidationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null || !user.isAdmin) {
      return Center(child: Text(tr(context, 'access_denied')));
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: tr(context, 'shops')),
              Tab(text: tr(context, 'products')),
              Tab(text: tr(context, 'verification')),
              Tab(text: tr(context, 'admin_moderation_products')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _PendingShopsList(),
                _PendingProductsList(),
                _ShopVerificationList(),
                AdminProductsModerationList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingShopsList extends StatelessWidget {
  const _PendingShopsList();

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.watch<ShopRepository>();

    return StreamBuilder<List<Shop>>(
      stream: shopRepo.watchPendingPromotions(),
      builder: (context, snapshot) {
        return AsyncContent<List<Shop>>(
          snapshot: snapshot,
          isEmpty: (shops) => shops.isEmpty,
          empty: () => EmptyState(
            icon: Icons.store_outlined,
            title: tr(context, 'no_pending_requests'),
          ),
          builder: (shops) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (shop.boostStatus == 1) ...[
                          _RequestBadge(
                            text: tr(context, 'admin_boost_request'),
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (shop.bannerStatus == 1) ...[
                          _RequestBadge(
                            text: tr(context, 'admin_banner_request'),
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tr(context, 'admin_banner_text')}: ${shop.bannerText ?? "N/A"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _handleAction(context, shop, false),
                              child: Text(
                                tr(context, 'reject'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _handleAction(context, shop, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(tr(context, 'approve')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleAction(BuildContext context, Shop shop, bool approve) async {
    final shopRepo = context.read<ShopRepository>();
    final syncService = context.read<SyncService>();
    final status = approve ? 2 : 3;

    final newBoostStatus = shop.boostStatus == 1 ? status : shop.boostStatus;
    final newBannerStatus =
        shop.bannerStatus == 1 ? status : shop.bannerStatus;

    final companion = ShopsCompanion(
      id: drift.Value(shop.id),
      boostStatus: drift.Value(newBoostStatus),
      bannerStatus: drift.Value(newBannerStatus),
    );

    await shopRepo.updateShop(companion);

    final remoteShopId =
        (shop.remoteId != null && shop.remoteId!.isNotEmpty)
            ? (int.tryParse(shop.remoteId!) ?? shop.id)
            : shop.id;

    await syncService.addToQueue('UPDATE', 'shops', {
      'local_id': shop.id,
      'id': remoteShopId,
      'name': shop.name,
      'owner_id': shop.ownerId ?? '',
      'phone': shop.phone,
      'type': shop.type,
      'boost_status': newBoostStatus,
      'banner_status': newBannerStatus,
      if (shop.bannerText != null && shop.bannerText!.isNotEmpty)
        'banner_text': shop.bannerText,
    });
    unawaited(syncService.forcePush());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? tr(context, 'admin_approved')
                : tr(context, 'admin_rejected'),
          ),
        ),
      );
    }
  }
}

class _PendingProductsList extends StatelessWidget {
  const _PendingProductsList();

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return StreamBuilder<List<Product>>(
      stream: productRepo.watchPendingBoosts(),
      builder: (context, snapshot) {
        return AsyncContent<List<Product>>(
          snapshot: snapshot,
          isEmpty: (products) => products.isEmpty,
          empty: () => EmptyState(
            icon: Icons.rocket_launch_outlined,
            title: tr(context, 'no_pending_requests'),
          ),
          builder: (products) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(tr(context, 'admin_boost_request')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              _handleAction(context, product, false),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () =>
                              _handleAction(context, product, true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    Product product,
    bool approve,
  ) async {
    final productRepo = context.read<ProductRepository>();
    final shopRepo = context.read<ShopRepository>();
    final syncService = context.read<SyncService>();
    final status = approve ? 2 : 3;

    final companion = ProductsCompanion(
      id: drift.Value(product.id),
      boostStatus: drift.Value(status),
    );

    await productRepo.updateProduct(companion);

    final shop = await shopRepo.getShopById(product.shopId);
    final remoteShopId =
        (shop?.remoteId != null && shop!.remoteId!.isNotEmpty)
            ? (int.tryParse(shop.remoteId!) ?? product.shopId)
            : product.shopId;

    final remoteProductId =
        (product.remoteId != null && product.remoteId!.isNotEmpty)
            ? int.tryParse(product.remoteId!)
            : null;

    await syncService.addToQueue('UPDATE', 'products', {
      if (remoteProductId != null) 'id': remoteProductId,
      'local_id': product.id,
      'shop_id': remoteShopId,
      'name': product.name,
      'price': product.price ?? 0,
      'boost_status': status,
    });
    unawaited(syncService.forcePush());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? tr(context, 'admin_product_boosted')
                : tr(context, 'admin_rejected'),
          ),
        ),
      );
    }
  }
}

class _ShopVerificationList extends StatelessWidget {
  const _ShopVerificationList();

  @override
  Widget build(BuildContext context) {
    final db = context.read<UzaDatabase>();

    return StreamBuilder<List<Shop>>(
      stream:
          (db.select(db.shops)
                ..where((t) => t.isVerified.equals(false))
                ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)]))
              .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(tr(context, 'admin_no_verification')));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final shop = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            tr(context, 'admin_unverified'),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tr(context, 'phone')}: ${shop.phone ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (shop.address != null && shop.address!.isNotEmpty)
                      Text(
                        '${tr(context, 'address')}: ${shop.address}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => AdminModerationActions.setShopVerified(
                            context,
                            shop,
                            false,
                          ),
                          child: Text(
                            tr(context, 'reject'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => AdminModerationActions.setShopVerified(
                            context,
                            shop,
                            true,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(tr(context, 'admin_verify')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _RequestBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
