import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/cart_repository.dart';
import '../../../core/res/uza_colors.dart';

class CartScreen extends StatefulWidget {
  final bool showAppBar;
  const CartScreen({super.key, this.showAppBar = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartRepo = context.read<CartRepository>();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Ma Sélection'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: UzaColors.primary,
            )
          : null,
      body: StreamBuilder<List<CartItemWithProduct>>(
        stream: cartRepo.watchCartWithProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre sélection est vide',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Explorer le catalogue'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.product.imageUrls
                                    .split(',')
                                    .first,
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
                                  Text(
                                    item.product.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Prix sur demande',
                                    style: TextStyle(
                                      color: UzaColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: item.cartItem.quantity > 1
                                            ? () => cartRepo.updateQuantity(
                                                item.cartItem.id,
                                                item.cartItem.quantity - 1,
                                              )
                                            : null,
                                      ),
                                      Text(
                                        '${item.cartItem.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            cartRepo.updateQuantity(
                                              item.cartItem.id,
                                              item.cartItem.quantity + 1,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  cartRepo.removeFromCart(item.cartItem.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nombre d\'articles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: UzaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _validateOnWhatsApp(context, items),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text(
                        'Discuter des prix sur WhatsApp',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _validateOnWhatsApp(
    BuildContext context,
    List<CartItemWithProduct> items,
  ) async {
    String message = "🌟 *DEMANDE DE DEVIS UZAAPP*\n";
    message +=
        "Bonjour, je souhaite discuter des prix pour ma sélection showroom :\n\n";

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      message += "📦 *${item.product.name}*\n";
      message += "   Quantité : ${item.cartItem.quantity}\n";
      if (item.product.remoteId != null) {
        message += "   Réf : ${item.product.remoteId}\n";
      }
      message += "\n";
    }

    message += "----------- \n";
    message += "Pouvez-vous me proposer vos meilleurs tarifs (Gros/Détail) ?\n";
    message += "_Envoyé via mon showroom Uzaapp_";

    final url = Uri.parse(
      "https://wa.me/243975955375?text=${Uri.encodeComponent(message)}",
    );

    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Success
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'ouvrir WhatsApp. Vérifiez que l\'application est installée.',
            ),
          ),
        );
      }
    }
  }
}
