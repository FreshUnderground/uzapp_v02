import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';

/// Diagnostic screen to check category and product data
class CategoryDiagnosticScreen extends StatelessWidget {
  const CategoryDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Catégories'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Root categories
          _buildSection(
            'Catégories Racine',
            StreamBuilder<List<Category>>(
              stream: productRepo.watchRootCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return const Text('Aucune catégorie racine');
                }
                return Column(
                  children: categories.map((cat) {
                    return _buildCategoryTile(context, cat, 0);
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // All products
          _buildSection(
            'Tous les Produits',
            StreamBuilder<List<Product>>(
              stream: productRepo.watchProductsFiltered(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Text('Aucun produit');
                }
                return Column(
                  children: products.map((product) {
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          'Catégorie ID: ${product.categoryId ?? "NULL"}\n'
                          'Catégorie (legacy): ${product.category ?? "NULL"}',
                        ),
                        trailing: Text(
                          product.categoryId != null
                              ? 'ID: ${product.categoryId}'
                              : '⚠️ Pas de categoryId',
                          style: TextStyle(
                            color: product.categoryId != null
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: UzaColors.primary,
          ),
        ),
        const Divider(),
        content,
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category,
    int level,
  ) {
    final productRepo = Provider.of<ProductRepository>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            level == 0
                ? Icons.folder
                : level == 1
                ? Icons.folder_open
                : Icons.article,
            color: level == 0 ? UzaColors.primary : Colors.grey,
          ),
          title: Text(
            '${'  ' * level}${category.name}',
            style: TextStyle(
              fontWeight: level == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text('ID: ${category.id} | Parent: ${category.parentId}'),
          trailing: StreamBuilder<List<Product>>(
            stream: productRepo.watchProductsFiltered(categoryId: category.id),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Badge(
                label: Text('$count'),
                child: const Icon(Icons.inventory),
              );
            },
          ),
          onTap: () {
            // Show subcategories
          },
        ),
        // Show subcategories
        StreamBuilder<List<Category>>(
          stream: productRepo.watchCategoriesByParent(category.id),
          builder: (context, snapshot) {
            final subcategories = snapshot.data ?? [];
            if (subcategories.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(left: level * 16.0),
              child: Column(
                children: subcategories.map((sub) {
                  return _buildCategoryTile(context, sub, level + 1);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
