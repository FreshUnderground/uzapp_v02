import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../utils/page_transitions.dart';
import '../screens/create_shop_screen.dart';
import '../screens/edit_product_screen.dart';

class HomeCTABanner extends StatelessWidget {
  const HomeCTABanner({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final shopRepo = context.read<ShopRepository>();
    final user = authService.firebaseUser;
    final userId = user?.uid;

    return StreamBuilder<Shop?>(
      stream: userId != null
          ? shopRepo.watchUserShop(userId)
          : Stream.value(null),
      builder: (context, snapshot) {
        final hasShop = snapshot.hasData && snapshot.data != null;

        if (!hasShop) {
          return _buildBanner(
            context,
            title: 'Créez votre boutique',
            subtitle:
                'Vendez vos produits à des milliers de clients localement.',
            buttonText: 'Ouvrir ma Boutique',
            color: UzaColors.secondary,
            icon: Icons.storefront,
            onTap: () {
              Navigator.push(
                context,
                SlideUpRoute(page: const CreateShopScreen()),
              );
            },
          );
        }

        final shop = snapshot.data!;
        return _buildBanner(
          context,
          title: 'Vendez plus aujourd\'hui',
          subtitle:
              'Ajoutez de nouveaux arrivages pour attirer plus de clients.',
          buttonText: 'Ajouter un Produit',
          color: Colors.green[700]!,
          icon: Icons.add_a_photo,
          onTap: () {
            Navigator.push(
              context,
              SlideUpRoute(page: EditProductScreen(shopId: shop.id)),
            );
          },
        );
      },
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              icon,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
