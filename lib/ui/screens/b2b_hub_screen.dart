import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../components/product_card.dart';
import 'product_detail_screen.dart';
import '../../core/res/uza_colors.dart';

class B2BHubScreen extends StatelessWidget {
  const B2BHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OFFRES B2B', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: UzaColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        // In a real app, we would filtering by B2B category or wholesale flag
        // For now, let's just show all products from wholesalers
        stream: productRepo.watchArrivals(), // Placeholder
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune offre B2B pour le moment.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
              );
            },
          );
        },
      ),
    );
  }
}
