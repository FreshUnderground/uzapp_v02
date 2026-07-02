import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/delivery_status_utils.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import '../components/async_content.dart';
import '../components/delivery_map_panel.dart';
import '../components/empty_state.dart';
import '../components/uza_badge.dart';

class SellerDeliveriesScreen extends StatefulWidget {
  final int shopId;

  const SellerDeliveriesScreen({super.key, required this.shopId});

  @override
  State<SellerDeliveriesScreen> createState() => _SellerDeliveriesScreenState();
}

class _SellerDeliveriesScreenState extends State<SellerDeliveriesScreen> {
  int? _selectedDeliveryId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DeliveryRepository>();
    final shopRepo = context.watch<ShopRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'seller_deliveries')),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () =>
                context.read<SyncService>().pullRemoteUpdates(),
          ),
        ],
      ),
      body: StreamBuilder<List<Delivery>>(
        stream: repo.watchPendingForShop(widget.shopId),
        builder: (context, snapshot) {
          return AsyncContent<List<Delivery>>(
            snapshot: snapshot,
            isEmpty: (list) => list.isEmpty,
            empty: () => EmptyState(
              icon: Icons.local_shipping_outlined,
              title: tr(context, 'delivery_no_pending'),
            ),
            builder: (deliveries) {
              return FutureBuilder<Shop?>(
                future: shopRepo.getShopById(widget.shopId),
                builder: (context, shopSnap) {
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: DeliveryMapPanel(
                          deliveries: deliveries,
                          shop: shopSnap.data,
                          selectedDeliveryId: _selectedDeliveryId,
                          onSelectDelivery: (id) {
                            setState(() => _selectedDeliveryId = id);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList.separated(
                          itemCount: deliveries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final delivery = deliveries[index];
                            final selected =
                                delivery.id == _selectedDeliveryId;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: selected
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: UzaColors.primary
                                              .withValues(alpha: 0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    )
                                  : null,
                              child: _DeliveryCard(
                                key: ValueKey(delivery.id),
                                delivery: delivery,
                                shopId: widget.shopId,
                                highlighted: selected,
                                onTap: () => setState(
                                  () => _selectedDeliveryId = delivery.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final int shopId;
  final bool highlighted;
  final VoidCallback? onTap;

  const _DeliveryCard({
    super.key,
    required this.delivery,
    required this.shopId,
    this.highlighted = false,
    this.onTap,
  });

  String _locationSummary() {
    if (DeliveryStatusUtils.hasCoordinates(
      delivery.latitude,
      delivery.longitude,
    )) {
      return '${delivery.latitude!.toStringAsFixed(5)}, ${delivery.longitude!.toStringAsFixed(5)}';
    }
    if (delivery.deliveryAddress?.isNotEmpty == true) {
      return delivery.deliveryAddress!;
    }
    if (delivery.deliveryCommune?.isNotEmpty == true) {
      return delivery.deliveryCommune!;
    }
    return '—';
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await context.read<DeliveryRepository>().updateStatus(
          delivery.id,
          status,
          syncService: context.read<SyncService>(),
        );
    unawaited(context.read<SyncService>().forcePush());
  }

  void _showDeliveryFlow(BuildContext context) {
    final hasGps = DeliveryStatusUtils.hasCoordinates(
      delivery.latitude,
      delivery.longitude,
    );
    final deliveryRepo = context.read<DeliveryRepository>();
    final syncService = context.read<SyncService>();
    final contactService = context.read<ContactService>();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ctx, 'delivery_client_location'),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(ctx, 'delivery_call_first'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                contactService.makeCall(
                  phone: delivery.buyerPhone,
                  entityType: 'delivery',
                  entityId: delivery.id,
                );
              },
              icon: const Icon(Icons.phone),
              label: Text(tr(ctx, 'delivery_call_client')),
              style: FilledButton.styleFrom(
                backgroundColor: UzaColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (hasGps) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  LocationService.getDirections(
                    latitude: delivery.latitude!,
                    longitude: delivery.longitude!,
                    destinationName: delivery.buyerName ?? delivery.buyerPhone,
                  );
                  if (delivery.status == DeliveryStatusUtils.pending ||
                      delivery.status == DeliveryStatusUtils.accepted) {
                    deliveryRepo.updateStatus(
                      delivery.id,
                      DeliveryStatusUtils.inTransit,
                      syncService: syncService,
                    );
                    unawaited(syncService.forcePush());
                  }
                },
                icon: const Icon(Icons.navigation_outlined),
                label: Text(tr(ctx, 'delivery_open_route')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = DeliveryStatusUtils.color(delivery.status);
    final items = context.read<DeliveryRepository>().parseItems(
          delivery.itemsJson,
        );

    return Card(
      elevation: highlighted ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlighted ? UzaColors.primary : Colors.grey.shade200,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(
                      DeliveryStatusUtils.icon(delivery.status),
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.buyerName?.isNotEmpty == true
                              ? delivery.buyerName!
                              : PhoneUtils.formatForDisplay(
                                  delivery.buyerPhone,
                                ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          PhoneUtils.formatForDisplay(delivery.buyerPhone),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UzaBadge(
                    label: DeliveryStatusUtils.label(delivery.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isNotEmpty)
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item['name'] ?? 'Article'} × ${item['quantity'] ?? 1}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationSummary(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (delivery.note?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  delivery.note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (delivery.status == DeliveryStatusUtils.pending)
                    _ActionChip(
                      label: tr(context, 'delivery_accept'),
                      icon: Icons.check,
                      color: UzaColors.secondary,
                      onTap: () => _updateStatus(
                        context,
                        DeliveryStatusUtils.accepted,
                      ),
                    ),
                  _ActionChip(
                    label: tr(context, 'delivery_call_client'),
                    icon: Icons.phone,
                    color: UzaColors.primary,
                    onTap: () => _showDeliveryFlow(context),
                  ),
                  if (DeliveryStatusUtils.hasCoordinates(
                    delivery.latitude,
                    delivery.longitude,
                  ))
                    _ActionChip(
                      label: tr(context, 'delivery_open_route'),
                      icon: Icons.map,
                      color: const Color(0xFF6C63FF),
                      onTap: () => _showDeliveryFlow(context),
                    ),
                  if (delivery.status == DeliveryStatusUtils.accepted ||
                      delivery.status == DeliveryStatusUtils.inTransit)
                    _ActionChip(
                      label: tr(context, 'delivery_complete'),
                      icon: Icons.done_all,
                      color: Colors.green,
                      onTap: () => _updateStatus(
                        context,
                        DeliveryStatusUtils.delivered,
                      ),
                    ),
                  if (delivery.status != DeliveryStatusUtils.delivered)
                    _ActionChip(
                      label: tr(context, 'delivery_cancel'),
                      icon: Icons.close,
                      color: Colors.red.shade400,
                      onTap: () => _updateStatus(
                        context,
                        DeliveryStatusUtils.cancelled,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
