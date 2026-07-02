import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/app_share_messages.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/product_share_messages.dart';
import '../../core/utils/shop_share_messages.dart';
import '../../core/utils/status_share_messages.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'share_preview_layout.dart';

/// Aperçu image + message marketing avant tout partage / publication.
class MarketingShareSheet extends StatefulWidget {
  final BuildContext hostContext;
  final String title;
  final String? subtitle;
  final String message;
  final String? imageUrl;
  final String shareLabel;
  final Future<void> Function() onShare;

  const MarketingShareSheet({
    super.key,
    required this.hostContext,
    required this.title,
    this.subtitle,
    required this.message,
    this.imageUrl,
    this.shareLabel = 'Partager',
    required this.onShare,
  });

  @override
  State<MarketingShareSheet> createState() => _MarketingShareSheetState();

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String message,
    String? imageUrl,
    String shareLabel = 'Partager',
    required Future<void> Function() onShare,
  }) {
    final host = context;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MarketingShareSheet(
        hostContext: host,
        title: title,
        subtitle: subtitle,
        message: message,
        imageUrl: imageUrl,
        shareLabel: shareLabel,
        onShare: onShare,
      ),
    );
  }

  static Future<void> showProduct(
    BuildContext context, {
    required Product product,
    Shop? shop,
    VoidCallback? onShared,
  }) async {
    final host = context;
    Shop? resolvedShop = shop;
    resolvedShop ??= await host.read<ShopRepository>().getShopById(
      product.shopId,
    );

    if (!host.mounted) return;
    final contact = host.read<ContactService>();
    final imageUrl = ImageUtils.getDecryptedList(product.imageUrls).firstOrNull;
    final composedImageFuture = contact.composeProductShareImage(product);

    await show(
      host,
      title: 'Partager ce produit',
      subtitle: product.name,
      message: ProductShareMessages.share(product, resolvedShop),
      imageUrl: imageUrl,
      onShare: () async {
        final composed = await composedImageFuture;
        await contact.shareProduct(
          product,
          resolvedShop,
          precomposedImage: composed,
        );
        onShared?.call();
      },
    );
  }

  static Future<void> showShopLink(
    BuildContext context, {
    required Shop shop,
  }) {
    final host = context;
    final contact = host.read<ContactService>();
    return show(
      host,
      title: 'Partager la boutique',
      subtitle: shop.name,
      message: ShopShareMessages.linkShare(shop),
      imageUrl: shop.logoUrl,
      onShare: () => contact.shareShop(shop),
    );
  }

  static Future<void> showShopCatalog(
    BuildContext context, {
    required Shop shop,
  }) async {
    final host = context;
    final locale = localeOf(host);
    final preparingLabel = trL('catalog_preparing', locale);
    final messenger = ScaffoldMessenger.of(host);
    messenger.showSnackBar(
      SnackBar(
        content: Text(preparingLabel),
        duration: const Duration(seconds: 2),
      ),
    );

    final db = host.read<UzaDatabase>();
    final productRepo = host.read<ProductRepository>();
    final contact = host.read<ContactService>();
    final catalog = await productRepo.getShareableCatalog(shop.id);
    final now = DateTime.now();
    final arrivageStories = await (db.select(db.stories)..where(
          (t) =>
              t.shopId.equals(shop.id) &
              t.isArrivage.equals(true) &
              t.expiresAt.isBiggerThanValue(now),
        ))
        .get();

    final message = ShopShareMessages.catalogShare(
      shop,
      arrivals: catalog.arrivals,
      products: catalog.products,
      activeArrivageStories: arrivageStories.length,
    );

    if (!host.mounted) return;
    await show(
      host,
      title: 'Partager le catalogue',
      subtitle: shop.name,
      message: message,
      imageUrl: shop.logoUrl,
      shareLabel: 'Partager le catalogue',
      onShare: () => contact.shareShopCatalog(shop),
    );
  }

  static Future<void> showStory(
    BuildContext context, {
    required Story story,
    required Shop shop,
    String? imageUrl,
  }) {
    final host = context;
    final contact = host.read<ContactService>();
    return show(
      host,
      title: story.isArrivage ? 'Partager l\'arrivage' : 'Partager la story',
      subtitle: shop.name,
      message: StatusShareMessages.storyShare(
        shop,
        isArrivage: story.isArrivage,
      ),
      imageUrl: imageUrl,
      onShare: () => contact.shareStory(
        story,
        shop,
        imageUrl: imageUrl,
      ),
    );
  }

  static Future<void> showStatusCollection(
    BuildContext context, {
    required Shop shop,
    required int imageCount,
    String? previewImageUrl,
    String shareLabel = 'Publier / partager',
    required Future<void> Function() onShare,
  }) {
    return show(
      context,
      title: 'Publier le statut WhatsApp',
      subtitle: shop.name,
      message: StatusShareMessages.collectionShare(
        shop,
        imageCount: imageCount,
      ),
      imageUrl: previewImageUrl,
      shareLabel: shareLabel,
      onShare: onShare,
    );
  }

  static Future<void> showShopQr(
    BuildContext context, {
    required Shop shop,
  }) {
    final host = context;
    final contact = host.read<ContactService>();
    return show(
      host,
      title: 'Partager le QR code',
      subtitle: shop.name,
      message: ShopShareMessages.qrShare(shop),
      imageUrl: shop.logoUrl,
      shareLabel: 'Partager le QR',
      onShare: () => contact.shareShopQrCode(shop),
    );
  }

  static Future<void> showReferralInvite(
    BuildContext context, {
    required String message,
  }) {
    return show(
      context,
      title: 'Inviter des amis',
      message: message,
      shareLabel: 'Envoyer l\'invitation',
      onShare: () async {
        if (kIsWeb) {
          await Clipboard.setData(ClipboardData(text: message));
          return;
        }
        await Share.share(message, subject: 'Rejoignez UzaApp');
      },
    );
  }

  static Future<void> showAppInvite(BuildContext context) {
    final host = context;
    final contact = host.read<ContactService>();
    final message = AppShareMessages.merchantInvite();
    return show(
      host,
      title: 'Inviter sur UzaApp',
      message: message,
      shareLabel: 'Envoyer l\'invitation',
      onShare: () => contact.shareAppInvite(),
    );
  }
}

class _MarketingShareSheetState extends State<MarketingShareSheet> {
  var _busy = false;
  late String _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = localeOf(widget.hostContext);
  }

  Future<void> _handleShare() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.onShare();
      if (navigator.mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            trfL(_locale, 'share_impossible_colon', {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty
        ? ImageUtils.buildCachedImage(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.campaign_outlined, size: 48),
            ),
          );

    return SharePreviewLayout(
      title: widget.title,
      subtitle: widget.subtitle,
      message: widget.message,
      messageLabel: 'Message marketing',
      messageAccent: UzaColors.primary,
      imageAspectRatio: widget.imageUrl != null &&
              widget.imageUrl!.contains('status')
          ? 9 / 16
          : 4 / 3,
      image: image,
      actions: [
        FilledButton.icon(
          onPressed: _busy ? null : _handleShare,
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.share_outlined, size: 20),
          label: Text(widget.shareLabel),
          style: FilledButton.styleFrom(
            backgroundColor: UzaColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
