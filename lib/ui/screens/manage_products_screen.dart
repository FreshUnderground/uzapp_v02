import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import '../../core/res/uza_colors.dart';

import 'edit_product_screen.dart';
import 'seller_dashboard_screen.dart';

import '../components/responsive_layout.dart';

class ManageProductsScreen extends StatelessWidget {
  final int shopId;
  const ManageProductsScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Tableau de bord',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerDashboardScreen(shopId: shopId),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: productRepo.watchProductsByShop(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Aucun produit. Ajoutez-en un !'));
          }

          return ResponsiveLayout(
            mobile: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _ProductManagementCard(product: products[index]);
              },
            ),
            desktop: GridView.builder(
              padding: const EdgeInsets.all(32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisExtent: 140,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _ProductManagementCard(product: products[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProductScreen(shopId: shopId)),
        ),
        backgroundColor: UzaColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductManagementCard extends StatelessWidget {
  final Product product;
  const _ProductManagementCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isSold ? 0.5 : 1.0,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrls.split(',').first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (product.isSold)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VENDU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${product.price} \$',
                      style: const TextStyle(color: UzaColors.primary),
                    ),
                    const SizedBox(height: 4),
                    _ProductMetricsRow(productId: product.id),
                    const SizedBox(height: 4),
                    _StockBadge(product: product),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      product.isSold ? Icons.refresh : Icons.check_circle,
                      color: product.isSold ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    tooltip: product.isSold
                        ? 'Remettre en vente'
                        : 'Marquer vendu',
                    onPressed: () {
                      final repo = context.read<ProductRepository>();
                      if (product.isSold) {
                        repo.markProductAsAvailable(product.id);
                      } else {
                        repo.markProductAsSold(product.id);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductScreen(
                          shopId: product.shopId,
                          product: product,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final repo = context.read<ProductRepository>();
              final syncService = context.read<SyncService>();
              Navigator.pop(context);
              await repo.deleteProductWithSync(product.id);
              await syncService.forcePush();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProductMetricsRow extends StatefulWidget {
  final int productId;

  const _ProductMetricsRow({required this.productId});

  @override
  State<_ProductMetricsRow> createState() => _ProductMetricsRowState();
}

class _ProductMetricsRowState extends State<_ProductMetricsRow> {
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = context.read<ProductRepository>();
    final stats = await repo.getProductStats(widget.productId);
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const SizedBox.shrink();
    }
    final views = _stats!['views'] ?? 0;
    final contacts = _stats!['contacts'] ?? 0;
    if (views == 0 && contacts == 0) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.visibility_outlined,
          size: 12,
          color: UzaColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          '$views',
          style: const TextStyle(
            fontSize: 11,
            color: UzaColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.phone_android_rounded,
          size: 12,
          color: UzaColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          '$contacts',
          style: const TextStyle(
            fontSize: 11,
            color: UzaColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Product product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final stock = product.stockCount;
    return InkWell(
      onTap: () => _showStockDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: stock == null
              ? Colors.grey[100]
              : (stock > 5 ? Colors.green[50] : Colors.red[50]),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          stock == null ? 'Gérer le stock' : 'Stock: $stock',
          style: TextStyle(
            fontSize: 12,
            color: stock == null
                ? Colors.grey
                : (stock > 5 ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context) {
    final controller = TextEditingController(
      text: product.stockCount?.toString() ?? '0',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre à jour le stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantité disponible'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 0;
              context.read<ProductRepository>().updateStock(
                product.id,
                quantity,
              );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
