import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import '../../core/l10n/tr.dart';
import 'package:drift/drift.dart' as drift;

class AdminValidationScreen extends StatelessWidget {
  const AdminValidationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'admin_validation')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr(context, 'shops')),
              Tab(text: tr(context, 'products')),
              Tab(text: tr(context, 'verification')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _PendingShopsList(),
            const _PendingProductsList(),
            _ShopVerificationList(),
          ],
        ),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune demande en attente.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final shop = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const _RequestBadge(
                        text: 'Demande de Boost 🚀',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (shop.bannerStatus == 1) ...[
                      const _RequestBadge(
                        text: 'Demande de Bannière 📺',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Texte: ${shop.bannerText ?? "N/A"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _handleAction(context, shop, false),
                          child: const Text(
                            'Refuser',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _handleAction(context, shop, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approuver'),
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

  void _handleAction(BuildContext context, Shop shop, bool approve) async {
    final shopRepo = context.read<ShopRepository>();
    final status = approve ? 2 : 3;

    final companion = ShopsCompanion(
      id: drift.Value(shop.id),
      boostStatus: shop.boostStatus == 1
          ? drift.Value(status)
          : drift.Value(shop.boostStatus),
      bannerStatus: shop.bannerStatus == 1
          ? drift.Value(status)
          : drift.Value(shop.bannerStatus),
    );

    await shopRepo.updateShop(companion);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Approuvé !' : 'Refusé !')),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun boost produit en attente.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(product.name),
                subtitle: const Text('Demande de Boost 🚀'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleAction(context, product, false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleAction(context, product, true),
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

  void _handleAction(
    BuildContext context,
    Product product,
    bool approve,
  ) async {
    final productRepo = context.read<ProductRepository>();
    final status = approve ? 2 : 3;

    final companion = ProductsCompanion(
      id: drift.Value(product.id),
      boostStatus: drift.Value(status),
    );

    await productRepo.updateProduct(companion);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Produit Boosté !' : 'Refusé !')),
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
          return const Center(
            child: Text('Aucune boutique en attente de vérification.'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final shop = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          child: const Text(
                            'Non vérifié',
                            style: TextStyle(
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
                      'Téléphone: ${shop.phone ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (shop.address != null && shop.address!.isNotEmpty)
                      Text(
                        'Adresse: ${shop.address}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _verifyShop(context, shop, false),
                          child: const Text(
                            'Rejeter',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _verifyShop(context, shop, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Vérifier'),
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

  void _verifyShop(BuildContext context, Shop shop, bool verify) async {
    final shopRepo = context.read<ShopRepository>();
    final syncService = context.read<SyncService>();

    final companion = ShopsCompanion(
      id: drift.Value(shop.id),
      isVerified: drift.Value(verify),
      verifiedAt: verify
          ? drift.Value(DateTime.now())
          : const drift.Value.absent(),
    );

    await shopRepo.updateShop(companion);

    // Queue sync update
    await syncService.addToQueue('UPDATE', 'shops', {
      'id': shop.id,
      'is_verified': verify ? 1 : 0,
      'verified_at': verify ? DateTime.now().toIso8601String() : null,
    });

    if (context.mounted) {
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
