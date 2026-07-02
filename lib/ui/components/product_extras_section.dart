import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';

import '../../core/services/product_alerts_service.dart';
import '../../core/utils/b2b_pricing_utils.dart';
import '../../core/utils/product_promo_utils.dart';
import '../../data/local/uza_database.dart';
import '../components/product_promo_display.dart';

/// Price alerts + B2B tier table on product detail.
class ProductExtrasSection extends StatefulWidget {
  final Product product;

  const ProductExtrasSection({super.key, required this.product});

  @override
  State<ProductExtrasSection> createState() => _ProductExtrasSectionState();
}

class _ProductExtrasSectionState extends State<ProductExtrasSection> {
  bool _watching = false;
  String? _alertType;

  @override
  void initState() {
    super.initState();
    _loadAlert();
  }

  Future<void> _loadAlert() async {
    final service = context.read<ProductAlertsService>();
    final watching = await service.isWatching(widget.product.id);
    final type = await service.alertType(widget.product.id);
    if (mounted) {
      setState(() {
        _watching = watching;
        _alertType = type;
      });
    }
  }

  Future<void> _togglePriceAlert() async {
    final service = context.read<ProductAlertsService>();
    if (_watching && _alertType == 'price_drop') {
      await service.unwatch(widget.product.id);
    } else {
      await service.watchPriceDrop(
        widget.product.id,
        widget.product.price ?? 0,
      );
    }
    await _loadAlert();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _alertType == 'price_drop'
              ? 'Alerte prix activée'
              : 'Alerte prix désactivée',
        ),
      ),
    );
  }

  Future<void> _toggleStockAlert() async {
    final service = context.read<ProductAlertsService>();
    if (_watching && _alertType == 'back_in_stock') {
      await service.unwatch(widget.product.id);
    } else {
      await service.watchBackInStock(widget.product.id);
    }
    await _loadAlert();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'stock_alert_saved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiers = B2bPricingUtils.parseTiers(widget.product);
    final hasPromo = ProductPromoUtils.isFlashProduct(widget.product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPromo) ...[
          ProductPromoDisplay(product: widget.product, fontSize: 20),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: Icon(
                _alertType == 'price_drop' ? Icons.notifications_active : Icons.notifications_none,
                size: 18,
              ),
              label: Text(tr(context, 'price_alert')),
              onPressed: _togglePriceAlert,
            ),
            if (widget.product.isSold)
              ActionChip(
                avatar: const Icon(Icons.inventory, size: 18),
                label: Text(tr(context, 'restock_alert')),
                onPressed: _toggleStockAlert,
              ),
          ],
        ),
        if (tiers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Tarifs gros',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...tiers.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '≥ ${t.minQty} unités : ${t.unitPrice.toInt()} FC / unité',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
