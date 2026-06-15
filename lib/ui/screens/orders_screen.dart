import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../core/services/auth_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/empty_state.dart';
import '../components/async_content.dart';
import '../components/custom_refresh_indicator.dart';
import '../../data/services/sync_service.dart';
import '../utils/page_transitions.dart';
import 'auth/login_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthService>().user?.phoneNumber ?? '';

    if (phone.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'my_orders'))),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: tr(context, 'orders_empty'),
          subtitle: tr(context, 'login_prompt'),
          actionLabel: tr(context, 'login'),
          onAction: () => Navigator.push(
            context,
            SlideUpRoute(page: const LoginScreen()),
          ),
        ),
      );
    }

    final orderRepo = context.watch<OrderRepository>();
    final shopRepo = context.watch<ShopRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'my_orders'))),
      body: UzaRefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncNow();
        },
        child: StreamBuilder<List<Order>>(
          stream: orderRepo.watchOrdersForBuyer(phone),
          builder: (context, snapshot) {
            return AsyncContent<List<Order>>(
              snapshot: snapshot,
              builder: (orders) {
                if (orders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: tr(context, 'orders_empty'),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return FutureBuilder<Shop?>(
                      future: shopRepo.getShopById(order.shopId),
                      builder: (context, shopSnap) {
                        final shopName = shopSnap.data?.name ?? '…';
                        return Card(
                          child: ListTile(
                            title: Text(shopName),
                            subtitle: Text(
                              '${tr(context, 'order_status')}: ${_statusLabel(context, order.status)}',
                            ),
                            trailing: Text(
                              _formatDate(order.updatedAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'confirmed':
        return tr(context, 'order_confirmed');
      case 'delivered':
        return tr(context, 'order_delivered');
      case 'cancelled':
        return tr(context, 'order_cancelled');
      default:
        return tr(context, 'order_requested');
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
