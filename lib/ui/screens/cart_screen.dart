import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/cart_repository.dart';
import '../../../core/res/uza_colors.dart';
import '../components/skeletons.dart';
import '../../core/l10n/tr.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/mobile_money_sheet.dart';

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
              title: Text(tr(context, 'my_cart')),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: UzaColors.primary,
            )
          : null,
      body: StreamBuilder<List<CartItemWithProduct>>(
        stream: cartRepo.watchCartWithProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const ProductCardSkeleton(),
            );
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
                  Text(
                    tr(context, 'cart_empty'),
                    style: const TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr(context, 'browse_catalog')),
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
                              child: ImageUtils.buildCachedFirstProductImage(
                                item.product.imageUrls,
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showMobileMoney(context, items),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Mobile Money'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: UzaColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _validateOnWhatsApp(context, items),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(
                        tr(context, 'whatsapp_quote'),
                        style: const TextStyle(
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

  Future<void> _showMobileMoney(
    BuildContext context,
    List<CartItemWithProduct> items,
  ) async {
    if (items.isEmpty) return;
    final shopIds = items.map((i) => i.product.shopId).toSet();
    if (shopIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une seule boutique à la fois pour le paiement.'),
        ),
      );
      return;
    }
    final shop = await context.read<ShopRepository>().getShopById(shopIds.first);
    final phone = shop?.whatsapp?.trim().isNotEmpty == true
        ? shop!.whatsapp!.trim()
        : (shop?.phone?.trim() ?? '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro vendeur indisponible.')),
      );
      return;
    }
    final total = items.fold<double>(
      0,
      (sum, i) => sum + (i.product.price ?? 0) * i.cartItem.quantity,
    );
    await MobileMoneySheet.show(
      context,
      amount: total > 0 ? total : items.length * 1000,
      productNames: items.map((i) => i.product.name).toList(),
      whatsAppPhone: phone,
      buyerPhone: context.read<AuthService>().user?.phoneNumber,
    );
  }

  Future<void> _validateOnWhatsApp(
    BuildContext context,
    List<CartItemWithProduct> items,
  ) async {
    if (items.isEmpty) return;

    final shopIds = items.map((i) => i.product.shopId).toSet();
    if (shopIds.length > 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez valider votre panier pour une seule boutique à la fois.',
            ),
          ),
        );
      }
      return;
    }

    final shopId = shopIds.first;
    final shop = await context.read<ShopRepository>().getShopById(shopId);
    final targetPhoneRaw = shop?.whatsapp?.trim().isNotEmpty == true
        ? shop!.whatsapp!.trim()
        : (shop?.phone?.trim() ?? '');
    if (targetPhoneRaw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cette boutique n\'a pas de numéro WhatsApp ou téléphone valide.',
            ),
          ),
        );
      }
      return;
    }

    final targetPhone = targetPhoneRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (targetPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de contact invalide.')),
        );
      }
      return;
    }

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
      "https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}",
    );

    final buyerPhone = context.read<AuthService>().user?.phoneNumber ?? '';
    if (buyerPhone.isNotEmpty) {
      final orderRepo = context.read<OrderRepository>();
      await orderRepo.createOrder(
        buyerPhone: buyerPhone,
        shopId: shopId,
        items: items
            .map(
              (i) => {
                'product_id': i.product.id,
                'name': i.product.name,
                'quantity': i.cartItem.quantity,
              },
            )
            .toList(),
      );
    }

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
