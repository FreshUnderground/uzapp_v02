import 'package:url_launcher/url_launcher.dart';

/// Mobile Money providers available in DRC / East Africa.
enum MobileMoneyProvider {
  orange('Orange Money', '*144#'),
  mpesa('M-Pesa', '*150#'),
  airtel('Airtel Money', '*501#');

  final String label;
  final String ussdCode;
  const MobileMoneyProvider(this.label, this.ussdCode);
}

/// Handles Mobile Money payment initiation with WhatsApp fallback.
class MobileMoneyService {
  /// Attempt payment via USSD deeplink; returns pending state for manual confirmation.
  Future<MobileMoneyResult> initiatePayment({
    required String phone,
    required double amount,
    required String currency,
    required MobileMoneyProvider provider,
    String? orderReference,
  }) async {
    final ref = orderReference ?? 'UZA-${DateTime.now().millisecondsSinceEpoch}';
    final formattedAmount = amount.toStringAsFixed(0);

    // Try opening USSD dialer for the selected provider
    final ussdUri = Uri.parse('tel:${provider.ussdCode}');
    bool ussdLaunched = false;
    try {
      if (await canLaunchUrl(ussdUri)) {
        ussdLaunched = await launchUrl(ussdUri);
      }
    } catch (_) {}

    return MobileMoneyResult(
      success: false,
      pending: true,
      transactionId: ref,
      ussdLaunched: ussdLaunched,
      message: ussdLaunched
          ? 'Composez ${provider.ussdCode} et payez $formattedAmount $currency (réf: $ref) via ${provider.label}.'
          : 'Paiement ${provider.label}: $formattedAmount $currency (réf: $ref). '
              'Utilisez ${provider.ussdCode} ou contactez le vendeur via WhatsApp.',
    );
  }

  /// Build a WhatsApp message for payment fallback.
  String buildWhatsAppFallbackMessage({
    required double amount,
    required String currency,
    required String orderReference,
    required List<String> productNames,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('💳 *PAIEMENT MOBILE MONEY - UZAAPP*');
    buffer.writeln('Référence: $orderReference');
    buffer.writeln('Montant: ${amount.toStringAsFixed(0)} $currency');
    buffer.writeln('Produits: ${productNames.join(", ")}');
    buffer.writeln('\nJe souhaite finaliser ce paiement. Merci de confirmer.');
    return buffer.toString();
  }
}

class MobileMoneyResult {
  final bool success;
  final bool pending;
  final String? transactionId;
  final String message;
  final bool ussdLaunched;

  const MobileMoneyResult({
    required this.success,
    this.pending = false,
    this.transactionId,
    required this.message,
    this.ussdLaunched = false,
  });
}
