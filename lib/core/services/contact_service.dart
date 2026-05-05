import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/uza_database.dart';

class ContactService {
  final UzaDatabase db;

  ContactService(this.db);

  Future<void> launchWhatsApp({
    required String phone,
    required String entityType,
    required int entityId,
    String? name,
    String? category,
    String? imageUrl,
    String? productUrl,
    double? price,
    String? condition,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.isEmpty) {
      debugPrint('launchWhatsApp: empty phone number, aborting launch');
      return;
    }

    // Build rich WhatsApp message
    final StringBuffer buf = StringBuffer();

    if (entityType == 'product' && name != null) {
      buf.writeln('Bonjour, je vous contacte depuis Uzaapp.');
      buf.writeln('Je suis très intéressé(e) par votre article :');
      buf.writeln('📌 *${name}*');
      buf.writeln();
      final productLink = productUrl ?? 'https://uzaapp.com/product/$entityId';
      buf.writeln('🔗 Lien : $productLink');
      buf.writeln();
      buf.write('Cet article est-il toujours disponible ?');
    } else if (entityType == 'shop' && name != null) {
      // Shop-specific format
      buf.writeln('🏪 *$name*');
      if (productUrl != null && productUrl.isNotEmpty) {
        buf.writeln('🔗 Voir la boutique: $productUrl');
        buf.writeln();
      }
      buf.write('Envoyé depuis Uzaapp');
    } else {
      // Generic / support format
      buf.write('Bonjour, je suis intéressé par ce produit sur Uzaapp');
    }

    final message = buf.toString();
    final url = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      await _logInteraction(entityType, entityId, 'whatsapp');
    }
  }

  Future<void> makeCall({
    required String phone,
    required String entityType,
    required int entityId,
  }) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      await _logInteraction(entityType, entityId, 'call');
    }
  }

  Future<void> sendSMS({
    required String phone,
    String? message,
    required String entityType,
    required int entityId,
  }) async {
    final url = Uri.parse(
      "sms:$phone?body=${Uri.encodeComponent(message ?? '')}",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      await _logInteraction(entityType, entityId, 'sms');
    }
  }

  Future<void> launchSocial({
    required String urlString,
    required String entityType,
    required int entityId,
  }) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      await _logInteraction(entityType, entityId, 'social_click');
    }
  }

  Future<void> _logInteraction(
    String entityType,
    int entityId,
    String type,
  ) async {
    // 1. Log to generic analytics table
    await db
        .into(db.analytics)
        .insert(
          AnalyticsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            interactionType: type,
          ),
        );

    // 2. If it's a contact type, record in user_contacts for shop history
    if (['whatsapp', 'call', 'sms'].contains(type)) {
      int? shopId;
      int? productId;

      if (entityType == 'shop') {
        shopId = entityId;
      } else if (entityType == 'product') {
        productId = entityId;
        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(entityId))).getSingleOrNull();
        shopId = product?.shopId;
      }

      if (shopId != null) {
        await db
            .into(db.userContacts)
            .insert(
              UserContactsCompanion.insert(
                shopId: shopId,
                userPhone: 'Client', // Future: get from active user profile
                contactType: type,
                productId: drift.Value(productId),
              ),
            );
      }
    }
  }

  Future<void> shareShop(Shop shop) async {
    final String url = "https://uzaapp.com/#/shop/${shop.id}";
    final String text =
        "🛍️ Découvrez la boutique '${shop.name}' sur Uzaapp !\n\n"
        "${shop.description ?? ''}\n"
        "📍 Adresse : ${shop.address ?? 'Kinshasa'}\n"
        "🔗 Voir la boutique : $url\n\n"
        "${shop.logoUrl ?? ''}"; // Adding URL at the end helps social previews

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'share');
  }

  Future<void> shareProduct(Product product, Shop? shop) async {
    // If shop is null, try to fetch it from DB
    Shop? actualShop = shop;
    if (actualShop == null) {
      actualShop = await (db.select(
        db.shops,
      )..where((t) => t.id.equals(product.shopId))).getSingleOrNull();
    }

    final String url = "https://uzaapp.com/product/${product.id}";

    final String text =
        "*${product.name}*\n"
        "${product.price != null && product.price! > 0 ? 'Prix: ${product.price} \$\n' : 'Prix sur demande\n'}"
        "\n"
        "Voir le produit: $url\n"
        "\n"
        "Envoyé depuis UzaApp";

    await _shareText(text);
    await _logInteraction('product', product.id, 'share');
  }

  Future<void> _shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      debugPrint('Share plugin failed, trying fallback: $e');
      final String encodedText = Uri.encodeComponent(text);
      final url = Uri.parse("https://wa.me/?text=$encodedText");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}
