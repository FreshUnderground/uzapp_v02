import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../ui/screens/shop_dashboard_screen.dart';

/// Unified post-login / post-OTP destination: shop dashboard if owned shop, else home.
Future<void> goToPostAuthDestination(BuildContext context) async {
  if (!context.mounted) return;

  final auth = context.read<AuthService>();
  final userId = auth.user?.uid;
  if (userId == null || userId.isEmpty) {
    context.go('/');
    return;
  }

  try {
    final shop = await context.read<ShopRepository>().watchUserShop(userId).first;
    if (!context.mounted) return;
    if (shop != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShopDashboardScreen()),
        (route) => false,
      );
      return;
    }
  } catch (_) {
    // Fall through to home
  }

  if (context.mounted) {
    context.go('/');
  }
}
