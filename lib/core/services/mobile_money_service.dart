/// Placeholder for Mobile Money integration (M-Pesa, Orange Money, Airtel).
/// Wire to a local payment aggregator when ready for production.
class MobileMoneyService {
  Future<MobileMoneyResult> initiatePayment({
    required String phone,
    required double amount,
    required String currency,
    required String provider,
    String? orderReference,
  }) async {
    return MobileMoneyResult(
      success: false,
      message:
          'Paiement Mobile Money non encore activé. Utilisez WhatsApp pour le moment.',
    );
  }
}

class MobileMoneyResult {
  final bool success;
  final String? transactionId;
  final String message;

  const MobileMoneyResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}
