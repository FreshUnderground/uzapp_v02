/// Normalizes DRC (+243) phone numbers for WhatsApp, calls and SMS.
class PhoneUtils {
  static const String countryCode = '243';

  static String digitsOnly(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Returns international digits without "+" (e.g. 243975955375).
  static String normalizeDrc(String? phone) {
    var digits = digitsOnly(phone);
    if (digits.isEmpty) return '';

    // 243243XXXXXXXX → 243XXXXXXXX
    while (digits.startsWith('$countryCode$countryCode') &&
        digits.length > 12) {
      digits = digits.substring(countryCode.length);
    }

    // 2430XXXXXXXXX → 243XXXXXXXXX (0 local après l'indicatif)
    if (digits.startsWith('${countryCode}0') && digits.length > 12) {
      final withoutTrunk = countryCode + digits.substring(countryCode.length + 1);
      if (withoutTrunk.length >= 12) {
        digits = withoutTrunk.length > 12
            ? withoutTrunk.substring(0, 12)
            : withoutTrunk;
      }
    }

    if (digits.startsWith(countryCode) && digits.length >= 11) {
      return digits.length > 12 ? digits.substring(0, 12) : digits;
    }

    if (digits.startsWith('00$countryCode') && digits.length >= 13) {
      digits = digits.substring(2);
      return digits.length > 12 ? digits.substring(0, 12) : digits;
    }

    if (digits.startsWith('0') && digits.length >= 10) {
      return '$countryCode${digits.substring(1)}';
    }

    if (digits.length == 9) {
      return '$countryCode$digits';
    }

    return digits;
  }

  /// wa.me expects digits only, with country code and no "+".
  static String forWhatsApp(String? phone) => normalizeDrc(phone);

  /// First valid WhatsApp number from shop fields (whatsapp, then phone).
  static String? shopWhatsAppNumber({String? whatsapp, String? phone}) {
    for (final raw in [whatsapp, phone]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final normalized = forWhatsApp(raw);
      if (isValidDrc(normalized)) return normalized;
    }
    return null;
  }

  /// tel: URI with leading "+".
  static String forTelUri(String? phone) {
    final normalized = normalizeDrc(phone);
    return normalized.isEmpty ? '' : '+$normalized';
  }

  static String forSms(String? phone) => normalizeDrc(phone);

  static String formatForDisplay(String? phone) {
    final normalized = normalizeDrc(phone);
    if (normalized.length < 12) return phone?.trim() ?? '';
    final local = normalized.substring(3);
    if (local.length == 9) {
      return '+243 ${local.substring(0, 2)} '
          '${local.substring(2, 5)} '
          '${local.substring(5, 7)} '
          '${local.substring(7)}';
    }
    return '+$normalized';
  }

  static bool isValidDrc(String? phone) {
    final normalized = normalizeDrc(phone);
    return normalized.startsWith(countryCode) && normalized.length == 12;
  }

  /// Common formats for matching owner/shop phone fields across local & server.
  static List<String> lookupKeys(String? phone) {
    if (phone == null || phone.trim().isEmpty) return const [];
    final trimmed = phone.trim();
    final normalized = normalizeDrc(phone);
    final keys = <String>{trimmed, normalized, '+$normalized'};
    if (normalized.startsWith(countryCode) && normalized.length >= 12) {
      final local = normalized.substring(3);
      keys.add(local);
      keys.add('0$local');
    }
    keys.removeWhere((k) => k.isEmpty);
    return keys.toList();
  }
}
