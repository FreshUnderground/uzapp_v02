import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';

/// Keeps user profile name/avatar and shop name/logo in sync.
class ProfileShopSync {
  static Future<void> syncToShop(
    BuildContext context, {
    required Shop shop,
    String? name,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    if (name == null && logoUrl == null && bannerUrl == null) return;

    final shopRepo = context.read<ShopRepository>();
    final syncService = context.read<SyncService>();
    final storedLogo = logoUrl != null && logoUrl.isNotEmpty
        ? CryptoUtils.encrypt(logoUrl)
        : null;
    final storedBanner = bannerUrl != null && bannerUrl.isNotEmpty
        ? CryptoUtils.encrypt(bannerUrl)
        : null;

    await shopRepo.updateShop(
      ShopsCompanion(
        id: drift.Value(shop.id),
        name: name != null ? drift.Value(name) : const drift.Value.absent(),
        logoUrl: storedLogo != null
            ? drift.Value(storedLogo)
            : const drift.Value.absent(),
        bannerUrl: storedBanner != null
            ? drift.Value(storedBanner)
            : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    try {
      await syncService.addToQueue('UPDATE', 'shops', {
        'local_id': shop.id,
        'id':
            (shop.remoteId != null && shop.remoteId!.isNotEmpty)
            ? (int.tryParse(shop.remoteId!) ?? shop.id)
            : shop.id,
        if (name != null) 'name': name,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
      });
      syncService.forcePush();
    } catch (_) {}
  }

  static Future<void> syncToProfile(
    BuildContext context, {
    String? name,
    String? avatarUrl,
  }) async {
    if (name == null && avatarUrl == null) return;

    final authRepo = context.read<AuthRepository>();
    final authService = context.read<AuthService>();
    final syncService = context.read<SyncService>();

    await authRepo.updateProfile(name: name, avatarUrl: avatarUrl);

    try {
      final profile = await authRepo.getCurrentUser();
      if (profile != null) {
        await syncService.addToQueue('UPDATE', 'users', {
          'remote_id': profile.remoteId ?? profile.phone,
          'phone': profile.phone,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        });
      }
    } catch (_) {}

    if (avatarUrl != null) authService.updatePhotoUrl(avatarUrl);
    if (name != null) authService.updateDisplayName(name);
  }
}
