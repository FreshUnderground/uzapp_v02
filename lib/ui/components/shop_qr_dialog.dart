import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/utils/shop_qr_utils.dart';
import '../../core/utils/shop_share_messages.dart';
import '../../data/local/uza_database.dart';

class ShopQrDialog extends StatefulWidget {
  final Shop shop;

  const ShopQrDialog({super.key, required this.shop});

  static Future<void> show(BuildContext context, Shop shop) {
    return showDialog<void>(
      context: context,
      builder: (_) => ShopQrDialog(shop: shop),
    );
  }

  @override
  State<ShopQrDialog> createState() => _ShopQrDialogState();
}

class _ShopQrDialogState extends State<ShopQrDialog> {
  bool _isSharing = false;

  String get _url => ShopQrUtils.shopUrl(widget.shop);

  Future<void> _shareQr() async {
    setState(() => _isSharing = true);
    try {
      await context.read<ContactService>().shareShopQrCode(widget.shop);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Partage impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String get _shareMessage => ShopShareMessages.qrShare(widget.shop);

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié')),
    );
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: _shareMessage));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'QR Code — ${widget.shop.name}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data: _url,
              version: QrVersions.auto,
              size: 220,
              gapless: true,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              embeddedImage: ShopQrUtils.uzaLogoProvider,
              embeddedImageStyle: ShopQrUtils.embeddedImageStyleFor(220),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scannez pour ouvrir la boutique sur UzaApp',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Message à partager',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _copyMessage,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Copier',
                              style: TextStyle(
                                fontSize: 12,
                                color: UzaColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _shareMessage,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aperçu — le message complet sera envoyé au partage.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _copyUrl,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _url,
                      style: TextStyle(
                        fontSize: 12,
                        color: UzaColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy, size: 14, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSharing ? null : () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: _isSharing ? null : _shareQr,
          icon: _isSharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.share, size: 18),
          label: Text(kIsWeb ? 'Partager' : 'Partager le QR'),
          style: FilledButton.styleFrom(
            backgroundColor: UzaColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
