import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/res/uza_colors.dart';
import '../../core/utils/delivery_status_utils.dart';
import '../../data/local/uza_database.dart';

/// OpenStreetMap panel showing shop + client delivery points.
class DeliveryMapPanel extends StatelessWidget {
  final List<Delivery> deliveries;
  final Shop? shop;
  final int? selectedDeliveryId;
  final ValueChanged<int>? onSelectDelivery;

  const DeliveryMapPanel({
    super.key,
    required this.deliveries,
    this.shop,
    this.selectedDeliveryId,
    this.onSelectDelivery,
  });

  List<Delivery> get _mappedDeliveries => deliveries
      .where(
        (d) => DeliveryStatusUtils.hasCoordinates(d.latitude, d.longitude),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[];
    final markers = <Marker>[];

    if (shop != null &&
        DeliveryStatusUtils.hasCoordinates(shop!.latitude, shop!.longitude)) {
      final shopPoint = LatLng(shop!.latitude!, shop!.longitude!);
      points.add(shopPoint);
      markers.add(
        Marker(
          point: shopPoint,
          width: 44,
          height: 44,
          child: const _MapPin(
            icon: Icons.storefront,
            color: UzaColors.secondary,
            label: 'Boutique',
          ),
        ),
      );
    }

    for (final d in _mappedDeliveries) {
      final point = LatLng(d.latitude!, d.longitude!);
      points.add(point);
      final selected = d.id == selectedDeliveryId;
      markers.add(
        Marker(
          point: point,
          width: selected ? 52 : 44,
          height: selected ? 52 : 44,
          child: GestureDetector(
            onTap: () => onSelectDelivery?.call(d.id),
            child: _MapPin(
              icon: Icons.person_pin_circle,
              color: selected ? UzaColors.primary : const Color(0xFF6C63FF),
              label: d.buyerName?.isNotEmpty == true
                  ? d.buyerName!.substring(
                      0,
                      d.buyerName!.length.clamp(0, 1),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    if (points.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Aucune position GPS sur les livraisons actives',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final center = _centerPoint(points);
    final zoom = _fitZoom(points);

    return Container(
      height: 240,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.uzaapp.uzaapp',
          ),
          if (points.length > 1)
            PolylineLayer(
              polylines: [
                if (shop != null &&
                    DeliveryStatusUtils.hasCoordinates(
                      shop!.latitude,
                      shop!.longitude,
                    ))
                  for (final d in _mappedDeliveries)
                    Polyline(
                      points: [
                        LatLng(shop!.latitude!, shop!.longitude!),
                        LatLng(d.latitude!, d.longitude!),
                      ],
                      color: UzaColors.primary.withValues(alpha: 0.35),
                      strokeWidth: 2,
                    ),
              ],
            ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  LatLng _centerPoint(List<LatLng> points) {
    if (points.length == 1) return points.first;
    var lat = 0.0;
    var lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  double _fitZoom(List<LatLng> points) {
    if (points.length <= 1) return 15;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    final span = (maxLat - minLat).abs() + (maxLng - minLng).abs();
    if (span < 0.01) return 14;
    if (span < 0.05) return 13;
    if (span < 0.2) return 12;
    return 11;
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;

  const _MapPin({
    required this.icon,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (label != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}
