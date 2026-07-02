import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/delivery_status_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/async_content.dart';
import '../components/empty_state.dart';
import '../components/uza_badge.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final phone = user?.phoneNumber ?? '';
    final repo = context.watch<DeliveryRepository>();

    if (phone.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'my_deliveries'))),
        body: Center(child: Text(tr(context, 'login_deliveries_required'))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'my_deliveries'))),
      body: StreamBuilder<List<Delivery>>(
        stream: repo.watchForBuyer(phone),
        builder: (context, snapshot) {
          return AsyncContent<List<Delivery>>(
            snapshot: snapshot,
            isEmpty: (list) => list.isEmpty,
            empty: () => EmptyState(
              icon: Icons.inbox_outlined,
              title: tr(context, 'delivery_no_pending'),
            ),
            builder: (deliveries) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deliveries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _BuyerDeliveryTile(delivery: deliveries[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BuyerDeliveryTile extends StatelessWidget {
  final Delivery delivery;

  const _BuyerDeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final statusColor = DeliveryStatusUtils.color(delivery.status);
    final shopRepo = context.read<ShopRepository>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Shop?>(
              future: shopRepo.getShopById(delivery.shopId),
              builder: (context, snap) {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: UzaColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: UzaColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        snap.data?.name ?? 'Boutique',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    UzaBadge(
                      label: DeliveryStatusUtils.label(delivery.status),
                      color: statusColor,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (delivery.deliveryAddress?.isNotEmpty == true)
              _infoRow(Icons.home_outlined, delivery.deliveryAddress!),
            if (delivery.deliveryCommune?.isNotEmpty == true)
              _infoRow(Icons.location_city_outlined, delivery.deliveryCommune!),
            if (DeliveryStatusUtils.hasCoordinates(
              delivery.latitude,
              delivery.longitude,
            ))
              _infoRow(
                Icons.gps_fixed,
                '${delivery.latitude!.toStringAsFixed(4)}, ${delivery.longitude!.toStringAsFixed(4)}',
              ),
            if (delivery.note?.isNotEmpty == true)
              _infoRow(Icons.notes, delivery.note!),
            if (DeliveryStatusUtils.hasCoordinates(
              delivery.latitude,
              delivery.longitude,
            )) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => LocationService.openInMaps(
                    latitude: delivery.latitude!,
                    longitude: delivery.longitude!,
                    label: 'Livraison',
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(tr(context, 'delivery_open_route')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
