import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import '../../data/local/uza_database.dart';
import '../utils/crypto_utils.dart';
import '../utils/image_utils.dart';
import '../utils/phone_utils.dart';
import '../utils/product_price_utils.dart';

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
    bool hidePrice = false,
    String? condition,
  }) async {
    final cleanPhone = PhoneUtils.forWhatsApp(phone);

    if (cleanPhone.isEmpty) {
      debugPrint('launchWhatsApp: empty phone number, aborting launch');
      return;
    }

    // Build rich WhatsApp message
    final StringBuffer buf = StringBuffer();

    if (entityType == 'product' && name != null) {
      buf.writeln('Bonjour, je vous contacte depuis Uzaapp.');
      buf.writeln('Je suis très intéressé(e) par votre article :');
      buf.writeln('📌 *$name*');
      buf.writeln(
        ProductPriceUtils.shareLineFromValues(
          price: price,
          hidePrice: hidePrice,
        ),
      );
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

    debugPrint('Launching WhatsApp: $url');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        await _logInteraction(entityType, entityId, 'whatsapp');
      } else {
        debugPrint('Cannot launch WhatsApp URL');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> makeCall({
    required String phone,
    required String entityType,
    required int entityId,
  }) async {
    final tel = PhoneUtils.forTelUri(phone);
    if (tel.isEmpty) return;
    final url = Uri.parse('tel:$tel');
    debugPrint('Launching phone call: $url');

    try {
      if (await canLaunchUrl(url)) {
        // Use platformDefaultLaunchMode for tel: URLs to work on all platforms
        await launchUrl(url, mode: LaunchMode.platformDefault);
        await _logInteraction(entityType, entityId, 'call');
      } else {
        debugPrint('Cannot launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  Future<void> sendSMS({
    required String phone,
    String? message,
    required String entityType,
    required int entityId,
  }) async {
    final cleanPhone = PhoneUtils.forSms(phone);
    if (cleanPhone.isEmpty) return;
    final url = Uri.parse(
      "sms:+$cleanPhone?body=${Uri.encodeComponent(message ?? '')}",
    );
    debugPrint('Launching SMS: $url');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
        await _logInteraction(entityType, entityId, 'sms');
      } else {
        debugPrint('Cannot launch SMS app');
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
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
    final String url = "https://uzaapp.com/shop/${shop.id}";
    final String text =
        "💼 Vous cherchez à développer votre clientèle ?\n\n"
        "🛍️ Découvrez '${shop.name}' sur UzaApp - l'app qui révolutionne le commerce !\n\n"
        "${shop.description ?? 'Une boutique de qualité vous attend'}\n\n"
        "📍 ${shop.address ?? 'Kinshasa, RDC'}\n"
        "⭐ Produits de qualité\n"
        "📦 Nouveautés régulières\n"
        "💬 Service client réactif\n\n"
        "👉 Voir la boutique : $url\n\n"
        "🚀 VOUS AUSSI, CRÉEZ VOTRE BOUTIQUE GRATUITE !\n"
        "📱 Téléchargez UzaApp et touchez des milliers de clients potentiels\n"
        "💰 Augmentez vos ventes dès maintenant !\n\n"
        "#UzaApp #Commerce #BoutiqueEnLigne";

    if (shop.logoUrl != null && shop.logoUrl!.isNotEmpty) {
      try {
        final logoUrl = CryptoUtils.decrypt(shop.logoUrl!);
        if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
          final response = await http.get(Uri.parse(logoUrl));
          if (response.statusCode == 200) {
            final xfile = await _buildXFile(
              response.bodyBytes,
              'shop_logo_${shop.id}.jpg',
            );
            await Share.shareXFiles(
              [xfile.$1],
              text: text,
              subject: '🛍️ Découvrez ${shop.name} sur UzaApp',
            );
            await xfile.$2?.delete();
            await _logInteraction('shop', shop.id, 'share');
            return;
          }
        }
      } catch (e) {
        debugPrint('Shop image share failed: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'share');
  }

  Future<void> shareProduct(Product product, Shop? shop) async {
    Shop? actualShop = shop;
    actualShop ??= await (db.select(
      db.shops,
    )..where((t) => t.id.equals(product.shopId))).getSingleOrNull();

    final String productRef =
        (product.remoteId != null && product.remoteId!.isNotEmpty)
        ? product.remoteId!
        : product.id.toString();
    final String url = "https://uzaapp.com/product/$productRef";
    final String condition = product.condition == 'new'
        ? '🆕 État : Neuf'
        : '✅ État : Occasion';
    final String priceText = ProductPriceUtils.shareLine(product);
    final String descLine =
        (product.description != null && product.description!.isNotEmpty)
        ? '📝 ${product.description!.length > 120 ? '${product.description!.substring(0, 120)}...' : product.description}\n'
        : '';
    final String shopLine = actualShop != null
        ? '🏦 Boutique : ${actualShop.name}\n'
        : '';

    final String text =
        '✨ *${product.name.toUpperCase()}* ✨\n\n'
        '$descLine'
        '$condition\n'
        '$priceText\n'
        '$shopLine'
        '\n'
        '👉 Voir le produit sur UzaApp :\n$url\n\n'
        '📦 Des milliers de produits disponibles près de chez vous !\n'
        '📲 Téléchargez UzaApp — Le marché en ligne N°1 en RDC\n\n'
        '#UzaApp #Shopping #RDC #Kinshasa';

    // Try to share with product image (works on mobile & web)
    final images = ImageUtils.getDecryptedList(product.imageUrls);
    if (images.isNotEmpty && images.first.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(images.first));
        if (response.statusCode == 200) {
          final xfile = await _buildXFile(
            response.bodyBytes,
            'product_share_${product.id}.jpg',
          );
          await Share.shareXFiles(
            [xfile.$1],
            text: text,
            subject: '✨ ${product.name} | UzaApp',
          );
          await xfile.$2?.delete();
          await _logInteraction('product', product.id, 'share');
          return;
        }
      } catch (e) {
        debugPrint('Product image share failed, using text fallback: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('product', product.id, 'share');
  }

  /// Returns (XFile, File?) — File is non-null on mobile so caller can delete it.
  Future<(XFile, File?)> _buildXFile(List<int> bytes, String filename) async {
    if (kIsWeb) {
      // Web: in-memory XFile (no temp file needed)
      final xfile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'image/jpeg',
        name: filename,
      );
      return (xfile, null);
    } else {
      // Mobile / Desktop: write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(bytes);
      return (XFile(tempFile.path), tempFile);
    }
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
