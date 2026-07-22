import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../screens/create_shop_screen.dart';
import '../screens/seller_onboarding_screen.dart';
import 'page_transitions.dart';

/// Returns the user's shop after auth/shop checks, or null if the flow was cancelled.
Future<Shop?> resolveSellerShop(BuildContext context) async {
  final authService = context.read<AuthService>();
  var userId = authService.user?.uid;

  if (userId == null) {
    await SellerOnboardingScreen.open(context);
    if (!context.mounted) return null;
    userId = context.read<AuthService>().user?.uid;
    if (userId == null) return null;
  }

  final shopRepo = context.read<ShopRepository>();
  var shop = await shopRepo.watchUserShop(userId).first;
  if (!context.mounted) return null;

  if (shop == null) {
    await Navigator.push(
      context,
      SlideUpRoute(page: const CreateShopScreen()),
    );
    if (!context.mounted) return null;
    // Re-resolve after shop creation (session + ownership may have updated).
    userId = context.read<AuthService>().user?.uid;
    if (userId == null) return null;
    shop = await shopRepo.watchUserShop(userId).first;
    if (!context.mounted) return null;
    if (shop == null) {
      await context.read<AuthService>().refreshShopOwnership();
      if (!context.mounted) return null;
      shop = await shopRepo.watchUserShop(userId).first;
    }
  }

  return shop;
}
