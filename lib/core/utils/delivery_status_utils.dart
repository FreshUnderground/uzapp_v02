import 'package:flutter/material.dart';
import '../res/uza_colors.dart';

/// Delivery workflow: pending → accepted → in_transit → delivered | cancelled
class DeliveryStatusUtils {
  DeliveryStatusUtils._();

  static const pending = 'pending';
  static const accepted = 'accepted';
  static const inTransit = 'in_transit';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static String label(String status) {
    switch (status) {
      case accepted:
        return 'Acceptée';
      case inTransit:
        return 'En cours';
      case delivered:
        return 'Livrée';
      case cancelled:
        return 'Annulée';
      default:
        return 'En attente';
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case accepted:
        return Icons.check_circle_outline;
      case inTransit:
        return Icons.local_shipping_outlined;
      case delivered:
        return Icons.done_all;
      case cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  static Color color(String status) {
    switch (status) {
      case accepted:
        return UzaColors.secondary;
      case inTransit:
        return const Color(0xFF6C63FF);
      case delivered:
        return Colors.green;
      case cancelled:
        return Colors.red.shade400;
      default:
        return Colors.orange;
    }
  }

  static bool isActive(String status) =>
      status != delivered && status != cancelled;

  static bool hasCoordinates(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() > 0.0001 &&
      lng.abs() > 0.0001;
}
