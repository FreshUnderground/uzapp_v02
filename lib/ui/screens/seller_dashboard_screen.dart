import 'package:flutter/material.dart';
import 'shop_dashboard_screen.dart';

/// Legacy entry point — redirects to unified [ShopDashboardScreen].
class SellerDashboardScreen extends StatelessWidget {
  final int shopId;
  const SellerDashboardScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return ShopDashboardScreen(shopId: shopId);
  }
}
