import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/uza_database.dart';
import '../utils/phone_utils.dart';

/// Anti-spam limits for seller WhatsApp re-engagement campaigns.
const int kReengagementMaxContactsPerSession = 15;
const int kReengagementMinDaysBetweenCampaigns = 7;
const int kReengagementMinDaysPerContact = 14;

enum ReengagementTemplate { standard, promo, arrivage, inactive }

class ReengagementClient {
  final String phone;
  final String source;
  final DateTime? lastContact;
  final int contactCount;

  const ReengagementClient({
    required this.phone,
    required this.source,
    this.lastContact,
    this.contactCount = 1,
  });
}

class ClientReengagementService {
  final UzaDatabase db;

  ClientReengagementService(this.db);

  String _prefLastCampaign(int shopId) => 'reengagement_last_campaign_$shopId';
  String _prefContactSent(int shopId, String phone) =>
      'reengagement_sent_${shopId}_$phone';

  Future<List<ReengagementClient>> getEligibleClients(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final merged = <String, ReengagementClient>{};

    void addPhone(String? raw, String source, {DateTime? at}) {
      final phone = PhoneUtils.forWhatsApp(raw ?? '');
      if (phone.isEmpty || phone.length < 9) return;
      if (phone == 'Client') return;

      final lastSentStr = prefs.getString(_prefContactSent(shopId, phone));
      if (lastSentStr != null) {
        final lastSent = DateTime.tryParse(lastSentStr);
        if (lastSent != null &&
            now.difference(lastSent).inDays < kReengagementMinDaysPerContact) {
          return;
        }
      }

      final existing = merged[phone];
      if (existing == null) {
        merged[phone] = ReengagementClient(
          phone: phone,
          source: source,
          lastContact: at,
        );
      } else {
        merged[phone] = ReengagementClient(
          phone: phone,
          source: '${existing.source}, $source',
          lastContact: at != null &&
                  (existing.lastContact == null ||
                      at.isAfter(existing.lastContact!))
              ? at
              : existing.lastContact,
          contactCount: existing.contactCount + 1,
        );
      }
    }

    final orders = await (db.select(db.orders)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    for (final o in orders) {
      addPhone(o.buyerPhone, 'commande', at: o.createdAt);
    }

    final follows = await (db.select(db.shopFollows)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    for (final f in follows) {
      addPhone(f.userPhone, 'abonné', at: f.createdAt);
    }

    final chats = await (db.select(db.chatMessages)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    for (final m in chats) {
      addPhone(m.senderPhone, 'message', at: m.createdAt);
      addPhone(m.receiverPhone, 'message', at: m.createdAt);
    }

    final contacts = await (db.select(db.userContacts)
          ..where((t) => t.shopId.equals(shopId)))
        .get();
    for (final c in contacts) {
      addPhone(c.userPhone, c.contactType, at: c.createdAt);
    }

    final list = merged.values.toList()
      ..sort((a, b) {
        final ac = a.contactCount;
        final bc = b.contactCount;
        if (ac != bc) return bc.compareTo(ac);
        final at = a.lastContact;
        final bt = b.lastContact;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return list.take(kReengagementMaxContactsPerSession * 2).toList();
  }

  Future<({bool allowed, int daysRemaining})> canStartCampaign(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_prefLastCampaign(shopId));
    if (lastStr == null) return (allowed: true, daysRemaining: 0);

    final last = DateTime.tryParse(lastStr);
    if (last == null) return (allowed: true, daysRemaining: 0);

    final days = DateTime.now().difference(last).inDays;
    if (days >= kReengagementMinDaysBetweenCampaigns) {
      return (allowed: true, daysRemaining: 0);
    }
    return (
      allowed: false,
      daysRemaining: kReengagementMinDaysBetweenCampaigns - days,
    );
  }

  String buildMessage({
    required Shop shop,
    String? customBody,
    ReengagementTemplate template = ReengagementTemplate.standard,
  }) {
    if (customBody != null && customBody.trim().isNotEmpty) {
      return customBody.trim();
    }
    final shopUrl = 'https://uzaapp.com/shop/${shop.remoteId ?? shop.id}';
    switch (template) {
      case ReengagementTemplate.promo:
        return 'Bonjour 👋\n\n'
            '🔥 *PROMO chez ${shop.name}* cette semaine !\n'
            'Des prix imbattables sur UzaApp.\n\n'
            '👉 $shopUrl\n\n'
            '_Répondez STOP pour vous désabonner._';
      case ReengagementTemplate.arrivage:
        return 'Bonjour 👋\n\n'
            '📦 *Nouveaux arrivages* chez ${shop.name} !\n'
            'Découvrez les dernières nouveautés.\n\n'
            '👉 $shopUrl';
      case ReengagementTemplate.inactive:
        return 'Bonjour, ça fait un moment ! 👋\n\n'
            'Nous avons de nouveaux produits chez *${shop.name}*.\n'
            'Revenez nous voir sur UzaApp :\n$shopUrl';
      case ReengagementTemplate.standard:
        return 'Bonjour 👋\n\n'
            'C\'est *${shop.name}* sur UzaApp.\n'
            '📦 De nouveaux arrivages et offres vous attendent cette semaine !\n\n'
            '👉 Découvrez : $shopUrl\n\n'
            '_Répondez STOP pour ne plus recevoir nos messages._';
    }
  }

  static const messageTemplates = [
    (ReengagementTemplate.standard, 'Message standard'),
    (ReengagementTemplate.promo, 'Promo / soldes'),
    (ReengagementTemplate.arrivage, 'Nouveaux arrivages'),
    (ReengagementTemplate.inactive, 'Clients inactifs'),
  ];

  Future<bool> openWhatsAppForClient({
    required String phone,
    required String message,
  }) async {
    final clean = PhoneUtils.forWhatsApp(phone);
    if (clean.isEmpty) return false;
    final url = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('ClientReengagementService: wa launch failed: $e');
    }
    return false;
  }

  Future<void> recordContactSent(int shopId, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = PhoneUtils.forWhatsApp(phone);
    await prefs.setString(
      _prefContactSent(shopId, clean),
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> recordCampaignCompleted(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefLastCampaign(shopId),
      DateTime.now().toIso8601String(),
    );
  }
}
