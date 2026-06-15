import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/shop_share_messages.dart';
import '../../data/local/uza_database.dart';
import 'shop_qr_dialog.dart';

/// Bottom sheet: partager le lien ou afficher le QR code de la boutique.
class ShopShareSheet extends StatelessWidget {
  final Shop shop;

  const ShopShareSheet({super.key, required this.shop});

  static Future<void> show(BuildContext context, Shop shop) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShopShareSheet(shop: shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Partager ${shop.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez comment faire connaître votre boutique',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Message d\'accompagnement',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: ShopShareMessages.linkShare(shop),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message copié')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copier'),
                        style: TextButton.styleFrom(
                          foregroundColor: UzaColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ShopShareMessages.linkShare(shop),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aperçu — le message complet sera envoyé au partage.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.12),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.teal),
              ),
              title: const Text('Partager le catalogue'),
              subtitle: const Text('Produits et arrivages avec liens'),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Préparation du catalogue…'),
                    duration: Duration(seconds: 2),
                  ),
                );
                try {
                  await context.read<ContactService>().shareShopCatalog(shop);
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de partager le catalogue'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.12),
                child: const Icon(Icons.share_outlined, color: Colors.blue),
              ),
              title: const Text('Partager le lien'),
              subtitle: const Text('WhatsApp, SMS, réseaux sociaux…'),
              onTap: () {
                Navigator.pop(context);
                context.read<ContactService>().shareShop(shop);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: UzaColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.qr_code_2, color: UzaColors.primary),
              ),
              title: const Text('QR Code de la boutique'),
              subtitle: const Text('Afficher, partager ou imprimer'),
              onTap: () {
                Navigator.pop(context);
                ShopQrDialog.show(context, shop);
              },
            ),
          ],
        ),
      ),
    );
  }
}
