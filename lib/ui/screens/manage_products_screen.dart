import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import '../../core/res/uza_colors.dart';
import '../../core/l10n/tr.dart';
import '../../core/utils/image_utils.dart';

import 'edit_product_screen.dart';
import 'update_product_screen.dart';
import 'shop_stats_screen.dart';

import '../components/async_content.dart';
import '../components/custom_refresh_indicator.dart';
import '../components/empty_state.dart';
import '../components/responsive_layout.dart';
import '../components/skeletons.dart';

class ManageProductsScreen extends StatefulWidget {
  final int shopId;
  const ManageProductsScreen({super.key, required this.shopId});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'my_products')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              height: 48,
              icon: const Icon(Icons.format_list_bulleted, size: 20),
              text: tr(context, 'products_view_list'),
            ),
            Tab(
              height: 48,
              icon: const Icon(Icons.view_carousel_outlined, size: 20),
              text: tr(context, 'gallery'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: tr(context, 'show_stats'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShopStatsScreen(shopId: widget.shopId),
              ),
            ),
          ),
        ],
      ),
      body: UzaRefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncNow();
        },
        child: StreamBuilder<List<Product>>(
          stream: productRepo.watchProductsByShop(widget.shopId),
          builder: (context, snapshot) {
            return AsyncContent<List<Product>>(
              snapshot: snapshot,
              loading: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ProductCardSkeleton(),
                    ),
                  ),
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 260,
                        child: ProductCardSkeleton(),
                      ),
                    ),
                  ),
                ],
              ),
              isEmpty: (products) => products.isEmpty,
              empty: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: tr(context, 'no_products_manage'),
                      subtitle: tr(context, 'no_products_manage_hint'),
                      actionLabel: tr(context, 'retry'),
                      onAction: () =>
                          context.read<SyncService>().syncNow(),
                    ),
                  ),
                ],
              ),
              builder: (products) {
                return TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _VerticalProductsList(products: products),
                    _HorizontalProductsList(products: products),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProductScreen(shopId: widget.shopId),
          ),
        ),
        backgroundColor: UzaColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VerticalProductsList extends StatelessWidget {
  final List<Product> products;

  const _VerticalProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _ProductManagementCard(product: products[index]);
        },
      ),
      desktop: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
  }
}

class _HorizontalProductsList extends StatelessWidget {
  final List<Product> products;

  const _HorizontalProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width * 0.72).clamp(240.0, 320.0);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        return SizedBox(
          width: cardWidth,
          child: _ProductHorizontalCard(product: products[index]),
        );
      },
    );
  }
}

class _ProductHorizontalCard extends StatelessWidget {
  final Product product;

  const _ProductHorizontalCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isSold ? 0.55 : 1.0,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductScreen(
                shopId: product.shopId,
                product: product,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageUtils.buildCachedFirstProductImage(
                      product.imageUrls,
                      fit: BoxFit.cover,
                    ),
                    if (product.isSold)
                      Container(
                        color: Colors.black38,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VENDU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price} \$',
                      style: const TextStyle(
                        color: UzaColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ProductMetricsRow(productId: product.id),
                    const SizedBox(height: 6),
                    _StockBadge(product: product),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            product.isSold ? Icons.refresh : Icons.check_circle,
                            color: product.isSold ? Colors.orange : Colors.green,
                            size: 22,
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
                          icon: const Icon(Icons.update_rounded, size: 22),
                          color: const Color(0xFF0984E3),
                          tooltip: 'Mettre à jour le produit',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpdateProductScreen(
                                shopId: product.shopId,
                                product: product,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22),
                          tooltip: 'Modifier',
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
                            size: 22,
                          ),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ],
                ),
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
        title: Text(tr(context, 'delete_confirm_title')),
        content: Text(tr(context, 'delete_product_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              final repo = context.read<ProductRepository>();
              final syncService = context.read<SyncService>();
              Navigator.pop(context);
              await repo.deleteProductWithSync(product.id);
              await syncService.forcePush();
            },
            child: Text(tr(context, 'delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductScreen(
                shopId: product.shopId,
                product: product,
              ),
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageUtils.buildCachedFirstProductImage(
                  product.imageUrls,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
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
                    tooltip: 'Modifier',
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
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'delete_confirm_title')),
        content: Text(tr(context, 'delete_product_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              final repo = context.read<ProductRepository>();
              final syncService = context.read<SyncService>();
              Navigator.pop(context);
              await repo.deleteProductWithSync(product.id);
              await syncService.forcePush();
            },
            child: Text(tr(context, 'delete'), style: TextStyle(color: Colors.red)),
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
          color: UzaColors.onSurfaceSecondary(context),
        ),
        const SizedBox(width: 2),
        Text(
          '$views',
          style: TextStyle(
            fontSize: 11,
            color: UzaColors.onSurfaceSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.phone_android_rounded,
          size: 12,
          color: UzaColors.onSurfaceSecondary(context),
        ),
        const SizedBox(width: 2),
        Text(
          '$contacts',
          style: TextStyle(
            fontSize: 11,
            color: UzaColors.onSurfaceSecondary(context),
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
        title: Text(tr(context, 'update_stock')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantité disponible'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
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
            child: Text(tr(context, 'register')),
          ),
        ],
      ),
    );
  }
}
