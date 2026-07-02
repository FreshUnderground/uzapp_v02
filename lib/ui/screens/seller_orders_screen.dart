import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/res/uza_colors.dart';
import '../../core/utils/whatsapp_checkout_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/services/sync_service.dart';
import '../components/async_content.dart';
import '../components/empty_state.dart';

/// Seller view: incoming orders with status workflow + MM confirmation.
class SellerOrdersScreen extends StatelessWidget {
  final int shopId;

  const SellerOrdersScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final orderRepo = context.watch<OrderRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'orders_received'))),
      body: StreamBuilder<List<Order>>(
        stream: orderRepo.watchOrdersForShop(shopId),
        builder: (context, snapshot) {
          return AsyncContent<List<Order>>(
            snapshot: snapshot,
            isEmpty: (orders) => orders.isEmpty,
            empty: () => EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune commande',
              subtitle: 'Les demandes WhatsApp apparaîtront ici',
            ),
            builder: (orders) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _OrderCard(order: orders[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'confirmed':
        return Colors.green;
      case 'pending_payment':
        return Colors.orange;
      case 'delivered':
        return UzaColors.secondary;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Paiement en attente';
      case 'paid':
        return 'Payé';
      case 'confirmed':
        return 'Confirmée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Demandée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderRepo = context.read<OrderRepository>();
    final items = orderRepo.parseItems(order.itemsJson);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.buyerPhone,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.take(3).map(
                  (item) => Text(
                    '• ${item['name'] ?? 'Produit'} × ${item['quantity'] ?? 1}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            if (items.length > 3)
              Text('+ ${items.length - 3} autre(s)...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.status == 'requested' ||
                    order.status == 'pending_payment')
                  OutlinedButton(
                    onPressed: () => orderRepo.updateStatus(
                      order.id,
                      'confirmed',
                      syncService: context.read<SyncService>(),
                    ),
                    child: Text(tr(context, 'confirm')),
                  ),
                if (order.status == 'pending_payment')
                  FilledButton(
                    onPressed: () => orderRepo.updateStatus(
                      order.id,
                      'paid',
                      syncService: context.read<SyncService>(),
                    ),
                    child: Text(tr(context, 'payment_received')),
                  ),
                if (order.status == 'paid' || order.status == 'confirmed')
                  OutlinedButton(
                    onPressed: () => orderRepo.updateStatus(
                      order.id,
                      'delivered',
                      syncService: context.read<SyncService>(),
                    ),
                    child: Text(tr(context, 'delivered')),
                  ),
                TextButton.icon(
                  onPressed: () => _contactBuyer(context),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text(tr(context, 'whatsapp_label')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactBuyer(BuildContext context) async {
    final phone = WhatsAppCheckoutUtils.normalizePhone(order.buyerPhone);
    if (phone.isEmpty) return;
    final uri = WhatsAppCheckoutUtils.whatsAppUri(
      phone,
      'Bonjour, concernant votre commande UzaApp (#${order.id})…',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
