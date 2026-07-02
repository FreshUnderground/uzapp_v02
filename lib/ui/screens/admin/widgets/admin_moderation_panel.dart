import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/local/uza_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../admin_moderation_actions.dart';

/// Quick moderation block for the admin dashboard.
class AdminDashboardModerationPanel extends StatefulWidget {
  final VoidCallback? onOpenModeration;

  const AdminDashboardModerationPanel({super.key, this.onOpenModeration});

  @override
  State<AdminDashboardModerationPanel> createState() =>
      _AdminDashboardModerationPanelState();
}

class _AdminDashboardModerationPanelState
    extends State<AdminDashboardModerationPanel> {
  Future<List<Map<String, dynamic>>>? _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    final phone = context.read<AuthService>().user?.phoneNumber;
    if (phone == null) return;
    setState(() {
      _reportsFuture = context.read<ApiService>().fetchAdminReports(
            adminPhone: phone,
            limit: 8,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<UzaDatabase>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr(context, 'admin_quick_moderation'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.onOpenModeration != null)
              TextButton(
                onPressed: widget.onOpenModeration,
                child: Text(tr(context, 'see_all')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          tr(context, 'admin_unverified_shops'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Shop>>(
          stream: (db.select(db.shops)
                ..where((t) => t.isVerified.equals(false))
                ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
                ..limit(5))
              .watch(),
          builder: (context, snapshot) {
            final shops = snapshot.data ?? [];
            if (shops.isEmpty) {
              return Text(
                tr(context, 'admin_no_verification'),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            }
            return Column(
              children: shops
                  .map((shop) => _UnverifiedShopTile(shop: shop))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          tr(context, 'admin_reported_products'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              );
            }
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return Text(
                tr(context, 'admin_no_reports'),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            }
            return Column(
              children: reports
                  .take(5)
                  .map((r) => _ReportedProductTile(
                        report: r,
                        onDeleted: _loadReports,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UnverifiedShopTile extends StatelessWidget {
  final Shop shop;

  const _UnverifiedShopTile({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          shop.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          shop.phone ?? shop.ownerId ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton(
          onPressed: () =>
              AdminModerationActions.setShopVerified(context, shop, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(tr(context, 'admin_verify')),
        ),
      ),
    );
  }
}

class _ReportedProductTile extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDeleted;

  const _ReportedProductTile({
    required this.report,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final productName = '${report['product_name'] ?? ''}';
    final shopName = '${report['shop_name'] ?? ''}';
    final reason = '${report['reason'] ?? ''}';
    final serverProductId = int.tryParse('${report['product_id'] ?? ''}');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$shopName · $reason',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: tr(context, 'admin_delete_product'),
              onPressed: serverProductId == null
                  ? null
                  : () async {
                      final ok = await AdminModerationActions.deleteProduct(
                        context,
                        serverProductId: serverProductId,
                        productName: productName,
                      );
                      if (ok) onDeleted();
                    },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full product catalog moderation list with search and delete.
class AdminProductsModerationList extends StatefulWidget {
  const AdminProductsModerationList({super.key});

  @override
  State<AdminProductsModerationList> createState() =>
      _AdminProductsModerationListState();
}

class _AdminProductsModerationListState
    extends State<AdminProductsModerationList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final shopRepo = context.read<ShopRepository>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr(context, 'search_hint'),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: productRepo.watchAllProductsAdmin(query: _query),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return Center(child: Text(tr(context, 'admin_no_data')));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return FutureBuilder<Shop?>(
                    future: shopRepo.getShopById(product.shopId),
                    builder: (context, shopSnap) {
                      final shopName = shopSnap.data?.name ?? '—';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: tr(context, 'admin_delete_product'),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final serverId = int.tryParse(
                                product.remoteId ?? '',
                              );
                              await AdminModerationActions.deleteProduct(
                                context,
                                localProductId: product.id,
                                serverProductId: serverId ?? product.id,
                                productName: product.name,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
