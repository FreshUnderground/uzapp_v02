import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/mobile_money_service.dart';

/// Bottom sheet to choose a Mobile Money provider with WhatsApp fallback.
class MobileMoneySheet extends StatefulWidget {
  final double amount;
  final String currency;
  final List<String> productNames;
  final String whatsAppPhone;
  final String? buyerPhone;
  final int? orderId;

  const MobileMoneySheet({
    super.key,
    required this.amount,
    this.currency = 'CDF',
    required this.productNames,
    required this.whatsAppPhone,
    this.buyerPhone,
    this.orderId,
  });

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required List<String> productNames,
    required String whatsAppPhone,
    String? buyerPhone,
    int? orderId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MobileMoneySheet(
        amount: amount,
        productNames: productNames,
        whatsAppPhone: whatsAppPhone,
        buyerPhone: buyerPhone,
        orderId: orderId,
      ),
    );
  }

  @override
  State<MobileMoneySheet> createState() => _MobileMoneySheetState();
}

class _MobileMoneySheetState extends State<MobileMoneySheet> {
  MobileMoneyProvider _provider = MobileMoneyProvider.orange;
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    final service = MobileMoneyService();
    final phone = widget.buyerPhone ?? '';
    final result = await service.initiatePayment(
      phone: phone,
      amount: widget.amount,
      currency: widget.currency,
      provider: _provider,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (widget.orderId != null && result.pending) {
      // Order already created with pending_payment status from cart.
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'mobile_money_payment')),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(context, 'ok')),
          ),
          if (!result.success)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _fallbackWhatsApp(service, result.transactionId ?? '');
              },
              child: Text(tr(context, 'whatsapp_label')),
            ),
        ],
      ),
    );
  }

  Future<void> _fallbackWhatsApp(
    MobileMoneyService service,
    String orderRef,
  ) async {
    final message = service.buildWhatsAppFallbackMessage(
      amount: widget.amount,
      currency: widget.currency,
      orderReference: orderRef,
      productNames: widget.productNames,
    );
    final phone = widget.whatsAppPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Payer via Mobile Money',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(0)} ${widget.currency}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UzaColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          ...MobileMoneyProvider.values.map((p) => RadioListTile<MobileMoneyProvider>(
            value: p,
            groupValue: _provider,
            title: Text(p.label),
            subtitle: Text('Code: ${p.ussdCode}'),
            onChanged: (v) => setState(() => _provider = v!),
          )),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _pay,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr(context, 'pay_now')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _fallbackWhatsApp(
              MobileMoneyService(),
              'UZA-${DateTime.now().millisecondsSinceEpoch}',
            ),
            icon: const Icon(Icons.chat),
            label: Text(tr(context, 'continue_whatsapp')),
          ),
        ],
      ),
    );
  }
}
