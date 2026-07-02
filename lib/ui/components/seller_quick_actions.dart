import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';
import '../../data/local/uza_database.dart';
import '../utils/page_transitions.dart';
import '../screens/edit_product_screen.dart';
import '../screens/create_story_screen.dart';
import '../screens/manage_products_screen.dart';
import '../screens/whatsapp_status_screen.dart';
import '../screens/quick_post_screen.dart';
import '../screens/update_product_screen.dart';
import '../screens/seller_orders_screen.dart';
import '../screens/seller_deliveries_screen.dart';
import '../screens/client_reengagement_screen.dart';
import '../screens/shop_stats_screen.dart';
import '../components/marketing_share_sheet.dart';
import 'shop_share_sheet.dart';

/// 2x2 quick action grid for seller dashboard.
class SellerQuickActions extends StatelessWidget {
  final Shop shop;

  const SellerQuickActions({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        icon: Icons.update_rounded,
        label: 'Mettre à jour',
        color: const Color(0xFF0984E3),
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: UpdateProductScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.add_shopping_cart_outlined,
        label: 'Produit',
        color: UzaColors.primary,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: EditProductScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.analytics_outlined,
        label: 'Statistiques',
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: ShopStatsScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.flash_on_outlined,
        label: 'Rapide',
        color: Colors.deepOrange,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: QuickPostScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.camera_alt_outlined,
        label: 'Story',
        color: UzaColors.secondary,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: CreateStoryScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.local_shipping_outlined,
        label: 'Arrivage',
        color: const Color(0xFF6C63FF),
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(
            page: CreateStoryScreen(shopId: shop.id, isArrivage: true),
          ),
        ),
      ),
      _Action(
        icon: Icons.inventory_2_outlined,
        label: 'Produits',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: ManageProductsScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.receipt_long_outlined,
        label: 'Commandes',
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: SellerOrdersScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.delivery_dining_outlined,
        label: 'Livraisons',
        color: const Color(0xFF00897B),
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: SellerDeliveriesScreen(shopId: shop.id)),
        ),
      ),
      _Action(
        icon: Icons.collections_outlined,
        label: 'Statut WA',
        color: const Color(0xFF25D366),
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: WhatsAppStatusScreen(shop: shop)),
        ),
      ),
      _Action(
        icon: Icons.share_outlined,
        label: 'Partager',
        color: Colors.blue,
        onTap: () => ShopShareSheet.show(context, shop),
      ),
      _Action(
        icon: Icons.list_alt_outlined,
        label: 'Catalogue',
        color: Colors.teal,
        onTap: () => MarketingShareSheet.showShopCatalog(context, shop: shop),
      ),
      _Action(
        icon: Icons.campaign_outlined,
        label: 'Relance WA',
        color: const Color(0xFF128C7E),
        onTap: () => Navigator.push(
          context,
          SlideUpRoute(page: ClientReengagementScreen(shop: shop)),
        ),
      ),
      _Action(
        icon: Icons.group_add_outlined,
        label: 'Inviter',
        color: Colors.green,
        onTap: () => MarketingShareSheet.showAppInvite(context),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _Action action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final background = Color.alphaBlend(
      action.color.withValues(alpha: 0.14),
      surface,
    );

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 28),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: action.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
