import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/uza_database.dart';
import '../utils/app_share_messages.dart';

/// Simple referral codes stored locally until server sync exists.
class ReferralService {
  static const _kReferralCode = 'uza_referral_code';
  static const _kReferralCount = 'uza_referral_count';

  Future<String> getOrCreateCode(String userPhone) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kReferralCode);
    if (existing != null && existing.isNotEmpty) return existing;

    final digest = sha256.convert(utf8.encode(userPhone)).toString();
    final code = 'UZA-${digest.substring(0, 6).toUpperCase()}';
    await prefs.setString(_kReferralCode, code);
    return code;
  }

  Future<int> referralCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReferralCount) ?? 0;
  }

  Future<void> incrementReferralCount() async {
    final prefs = await SharedPreferences.getInstance();
    final n = (prefs.getInt(_kReferralCount) ?? 0) + 1;
    await prefs.setInt(_kReferralCount, n);
  }

  String inviteMessage({required String referralCode, String? shopName}) {
    final base = AppShareMessages.merchantInvite();
    final link = 'https://uzaapp.com/?ref=$referralCode';
    return '$base\n\n'
        '🎁 *Mon code parrain :* $referralCode\n'
        '🔗 $link\n'
        '${shopName != null ? 'Boutique : $shopName\n' : ''}'
        'Utilisez ce code à l\'inscription pour nous soutenir mutuellement !';
  }

  static String? parseCodeFromUri(Uri uri) {
    return uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
  }
}

const String kPendingReferralPref = 'uza_pending_referral_code';

Future<void> savePendingReferralCode(String code) async {
  if (code.trim().isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kPendingReferralPref, code.trim().toUpperCase());
}

Future<String?> consumePendingReferralCode() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(kPendingReferralPref);
  if (code != null) await prefs.remove(kPendingReferralPref);
  return code;
}

Future<void> applyPendingReferralToDb(UzaDatabase db) async {
  final code = await consumePendingReferralCode();
  if (code == null) return;
  await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
    AppPreferencesCompanion(pendingReferralCode: Value(code)),
  );
}
