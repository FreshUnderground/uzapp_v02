import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';

import '../../core/res/uza_colors.dart';
import '../../core/utils/shop_share_messages.dart';
import '../../data/local/uza_database.dart';
import 'marketing_share_sheet.dart';
import 'shop_qr_dialog.dart';

/// Bottom sheet: partager le lien ou afficher le QR code de la boutique.
class ShopShareSheet extends StatelessWidget {
  final Shop shop;
  final BuildContext hostContext;

  const ShopShareSheet({
    super.key,
    required this.shop,
    required this.hostContext,
  });

  static Future<void> show(BuildContext context, Shop shop) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShopShareSheet(shop: shop, hostContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final previewMessage = ShopShareMessages.linkShare(shop);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    trf(context, 'share_shop_title', {'name': shop.name}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, 'share_choose_option'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.12),
                child:
                    const Icon(Icons.inventory_2_outlined, color: Colors.teal),
              ),
              title: Text(tr(context, 'share_catalog_title')),
              subtitle: Text(tr(context, 'share_catalog_subtitle')),
              onTap: () {
                Navigator.pop(context);
                MarketingShareSheet.showShopCatalog(hostContext, shop: shop);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.12),
                child: const Icon(Icons.share_outlined, color: Colors.blue),
              ),
              title: Text(tr(context, 'share_link_title')),
              subtitle: Text(tr(context, 'share_whatsapp_sms')),
              onTap: () {
                Navigator.pop(context);
                MarketingShareSheet.showShopLink(hostContext, shop: shop);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: UzaColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.qr_code_2, color: UzaColors.primary),
              ),
              title: Text(tr(context, 'share_qr_title')),
              subtitle: Text(tr(context, 'share_qr_subtitle')),
              onTap: () {
                Navigator.pop(context);
                ShopQrDialog.show(hostContext, shop);
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                previewMessage,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
