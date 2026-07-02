import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/res/uza_colors.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'product_detail_screen.dart';
import 'shop_profile_screen.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/tr.dart';
import '../components/uza_secondary_app_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;

    return UzaBackScope(
      child: Scaffold(
      appBar: UzaSecondaryAppBar(
        title: tr(context, 'notifications'),
        actions: [
          TextButton(
            onPressed: () => notificationService.clearAll(),
            child: Text(tr(context, 'clear_all')),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text(tr(context, 'no_notifications')))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead
                        ? Colors.grey[200]
                        : UzaColors.secondary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.notifications,
                      color: notification.isRead ? Colors.grey : UzaColors.secondary,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM HH:mm',
                        ).format(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    notificationService.markAsRead(index);
                    final linkType = notification.linkType;
                    final linkId = notification.linkId;
                    if (linkType == null || linkId == null || !context.mounted) {
                      return;
                    }
                    if (linkType == 'shop') {
                      final shop = await context
                          .read<ShopRepository>()
                          .getShopById(linkId);
                      if (shop != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopProfileScreen(shop: shop),
                          ),
                        );
                      }
                    } else if (linkType == 'product') {
                      final product = await context
                          .read<ProductRepository>()
                          .getProductById(linkId);
                      if (product != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
      ),
    );
  }
}
