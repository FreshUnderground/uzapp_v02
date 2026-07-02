import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/local/uza_database.dart';
import 'share_preview_layout.dart';

/// Bottom sheet: product/shop image + marketing message preview before WhatsApp.
class ContactSellerSheet extends StatefulWidget {
  final Shop shop;
  final Product? product;
  final ContactPreview preview;

  const ContactSellerSheet({
    super.key,
    required this.shop,
    required this.preview,
    this.product,
  });

  static Future<void> show(
    BuildContext context, {
    required Shop shop,
    Product? product,
    ContactPreview? preview,
    String? imageUrlOverride,
    int? storyId,
  }) {
    final contactService = context.read<ContactService>();
    final resolved = preview ??
        (product != null
            ? contactService.buildProductContactPreview(product, shop)
            : storyId != null && imageUrlOverride != null
            ? contactService.buildArrivageContactPreview(
                shop: shop,
                storyId: storyId,
                imageUrl: imageUrlOverride,
              )
            : contactService.buildShopContactPreview(
                shop,
                imageUrl: imageUrlOverride,
              ));

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ContactSellerSheet(
        shop: shop,
        product: product,
        preview: resolved,
      ),
    );
  }

  @override
  State<ContactSellerSheet> createState() => _ContactSellerSheetState();
}

class _ContactSellerSheetState extends State<ContactSellerSheet> {
  var _busy = false;
  Uint8List? _precomposedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareImage());
  }

  Future<void> _prepareImage() async {
    final contact = context.read<ContactService>();
    final bytes = await contact.composePreviewImage(widget.preview);
    if (mounted) setState(() => _precomposedImage = bytes);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action();
      if (navigator.mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(trf(context, 'action_impossible_colon', {'error': '$e'}))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final preview = widget.preview;
    final product = widget.product;
    final contactPhone = PhoneUtils.shopWhatsAppNumber(
      whatsapp: shop.whatsapp,
      phone: shop.phone,
    );
    final hasPhone = PhoneUtils.isValidDrc(PhoneUtils.forWhatsApp(shop.phone));
    final contactService = context.read<ContactService>();
    final buyerPhone = context.read<AuthService>().user?.phoneNumber;

    final previewImage = preview.imageUrl != null &&
            preview.imageUrl!.trim().isNotEmpty
        ? ImageUtils.buildCachedImage(
            preview.imageUrl,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.storefront_outlined, size: 48),
            ),
          );

    final actions = <Widget>[];

    if (contactPhone != null) {
      actions.add(
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _runAction(
                    () => contactService.sendContactPreview(
                      phone: contactPhone,
                      preview: preview,
                      buyerPhone: buyerPhone,
                      precomposedImage: _precomposedImage,
                    ),
                  ),
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
          label: Text(tr(context, 'contact_on_whatsapp')),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      actions.add(
        Text(
          'Ce vendeur n\'a pas de numéro WhatsApp',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (hasPhone) {
      actions.addAll([
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _runAction(
                    () => contactService.makeCall(
                      phone: shop.phone!,
                      entityType: preview.entityType,
                      entityId: preview.entityId,
                      buyerPhone: buyerPhone,
                    ),
                  ),
          icon: const Icon(Icons.phone_outlined),
          label: Text(tr(context, 'direct_call')),
          style: OutlinedButton.styleFrom(
            foregroundColor: UzaColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ]);
      if (product != null) {
        actions.add(
          const SizedBox(height: 8),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _runAction(
                      () => contactService.sendSMS(
                        phone: shop.phone!,
                        message:
                            'Est-ce que le produit ${product.name.toUpperCase()} est toujours disponible ?',
                        entityType: preview.entityType,
                        entityId: preview.entityId,
                        buyerPhone: buyerPhone,
                      ),
                    ),
            icon: const Icon(Icons.sms_outlined),
            label: Text(tr(context, 'send_sms')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      }
    }

    return SharePreviewLayout(
      title: tr(context, 'contact_seller'),
      subtitle: 'Choisissez comment joindre le vendeur',
      message: preview.message,
      messageLabel: 'Message envoyé au vendeur',
      messageAccent: const Color(0xFF25D366),
      image: previewImage,
      actions: actions,
    );
  }
}
