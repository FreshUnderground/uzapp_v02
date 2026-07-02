import 'dart:io';
import 'dart:ui' show Rect;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/sync_service.dart';
import '../utils/shop_stats_types.dart';
import '../utils/image_utils.dart';
import '../utils/phone_utils.dart';
import '../utils/product_price_utils.dart';
import '../utils/shop_qr_utils.dart';
import '../utils/app_share_messages.dart';
import '../utils/shop_share_messages.dart';
import '../utils/product_share_messages.dart';
import '../utils/share_message_labels.dart';
import '../utils/status_image_composer.dart';
import '../utils/status_share_messages.dart';
import '../utils/status_web_download.dart';
import '../utils/web_native_share.dart';
import '../utils/web_whatsapp_launcher.dart';
import '../utils/whatsapp_platform_share.dart';
import '../utils/status_slideshow_video.dart' show StatusSlideshowExport, StatusSlideshowVideo;
import '../utils/status_temp_files.dart';

/// Preview of what the buyer sends when contacting a seller on WhatsApp.
class ContactPreview {
  final String message;
  final String? imageUrl;
  final String entityType;
  final int entityId;

  const ContactPreview({
    required this.message,
    required this.imageUrl,
    required this.entityType,
    required this.entityId,
  });
}

class ContactService {
  final UzaDatabase db;
  final SyncService? syncService;

  ContactService(this.db, {this.syncService});

  ContactPreview buildProductContactPreview(Product product, Shop shop) {
    return ContactPreview(
      message: _buildProductContactMessage(product, shop),
      imageUrl: ImageUtils.getDecryptedList(product.imageUrls).firstOrNull,
      entityType: 'product',
      entityId: product.id,
    );
  }

  ContactPreview buildShopContactPreview(Shop shop, {String? imageUrl}) {
    return ContactPreview(
      message: _buildShopBuyerContactMessage(shop),
      imageUrl: imageUrl ?? shop.logoUrl,
      entityType: 'shop',
      entityId: shop.id,
    );
  }

  ContactPreview buildArrivageContactPreview({
    required Shop shop,
    required int storyId,
    required String imageUrl,
  }) {
    return ContactPreview(
      message: _buildArrivageBuyerContactMessage(shop),
      imageUrl: imageUrl,
      entityType: 'arrivage',
      entityId: storyId,
    );
  }

  Future<void> sendContactPreview({
    required String phone,
    required ContactPreview preview,
    String? buyerPhone,
    Uint8List? precomposedImage,
  }) {
    return launchWhatsApp(
      phone: phone,
      entityType: preview.entityType,
      entityId: preview.entityId,
      buyerPhone: buyerPhone,
      imageUrl: preview.imageUrl,
      preview: preview,
      precomposedImage: precomposedImage,
    );
  }

  /// Prépare l'image marketing (logo UzaApp) pour l'aperçu contact / partage web.
  Future<Uint8List?> composePreviewImage(ContactPreview preview) {
    return _composeBrandedShareImage(
      entityType: preview.entityType,
      imageUrl: preview.imageUrl,
    );
  }

  Future<Uint8List?> composeProductShareImage(Product product) {
    final source = ImageUtils.getDecryptedList(product.imageUrls).firstOrNull;
    return _composeBrandedShareImage(
      entityType: 'product',
      imageUrl: source,
    );
  }

  Future<void> launchWhatsApp({
    required String phone,
    required String entityType,
    required int entityId,
    String? buyerPhone,
    String? name,
    String? category,
    String? imageUrl,
    String? productUrl,
    double? price,
    bool hidePrice = false,
    String? condition,
    ContactPreview? preview,
    Uint8List? precomposedImage,
  }) async {
    final cleanPhone = PhoneUtils.forWhatsApp(phone);

    if (!PhoneUtils.isValidDrc(cleanPhone)) {
      throw Exception('Numéro WhatsApp invalide pour ce vendeur');
    }

    final resolved = preview ??
        await _resolveWhatsAppContactPayload(
          entityType: entityType,
          entityId: entityId,
          name: name,
          category: category,
          imageUrl: imageUrl,
          productUrl: productUrl,
          price: price,
          hidePrice: hidePrice,
          condition: condition,
        );
    final message = resolved.message;
    final imageSource = resolved.imageUrl;

    final composedImage = precomposedImage ??
        await _composeBrandedShareImage(
          entityType: entityType,
          imageUrl: imageSource,
        );

    // Android : conversation directe avec image dans le chat vendeur.
    if (composedImage != null &&
        composedImage.isNotEmpty &&
        !kIsWeb &&
        Platform.isAndroid) {
      final sharedWithImage = await _shareWhatsAppWithImage(
        cleanPhone: cleanPhone,
        message: message,
        composedImage: composedImage,
        entityId: entityId,
      );
      if (sharedWithImage) {
        await _logInteraction(
          entityType,
          entityId,
          'whatsapp',
          buyerPhone: buyerPhone,
        );
        return;
      }
    }

    // Web/PWA : télécharger l'image puis ouvrir le chat du vendeur (pas le menu partage).
    if (kIsWeb &&
        composedImage != null &&
        composedImage.isNotEmpty) {
      try {
        await downloadStatusImages(entityId, [composedImage]);
      } catch (e) {
        debugPrint('Contact image download failed: $e');
      }
    }

    await _openWhatsAppDirect(cleanPhone: cleanPhone, message: message);
    await _logInteraction(
      entityType,
      entityId,
      'whatsapp',
      buyerPhone: buyerPhone,
    );
  }

  /// Ouvre directement la conversation WhatsApp avec [cleanPhone] (pas le menu partage).
  Future<void> _openWhatsAppDirect({
    required String cleanPhone,
    required String message,
  }) async {
    if (kIsWeb) {
      await _launchWhatsAppWeb(cleanPhone: cleanPhone, message: message);
      return;
    }

    final webUrl = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
    final appUrl = Uri.parse(
      'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
    );

    debugPrint('Launching WhatsApp direct: $webUrl');

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          if (await canLaunchUrl(appUrl)) {
            await launchUrl(appUrl, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          debugPrint('WhatsApp app scheme failed: $e');
        }
      }

      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      rethrow;
    }
  }

  Future<void> _launchWhatsAppWeb({
    String? cleanPhone,
    required String message,
  }) async {
    if (kIsWeb) {
      final opened = await openWhatsAppShare(
        phone: cleanPhone,
        message: message,
      );
      if (opened) return;
    }

    final digits = cleanPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final url = digits.isNotEmpty
        ? Uri.parse(
            'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
          )
        : Uri.parse(
            'https://wa.me/?text=${Uri.encodeComponent(message)}',
          );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      debugPrint('WhatsApp external launch failed: $e');
    }

    try {
      final launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      if (launched) return;
    } catch (e) {
      debugPrint('WhatsApp platform launch failed: $e');
    }

    await Clipboard.setData(ClipboardData(text: message));
    throw Exception(
      'Impossible d\'ouvrir WhatsApp — le message a été copié',
    );
  }

  Future<bool> _shareWhatsAppWithImage({
    required String cleanPhone,
    required String message,
    required Uint8List composedImage,
    required int entityId,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;

    File? tempFile;
    try {
      final xfile = await _buildXFile(
        composedImage,
        'uza_contact_$entityId.jpg',
      );
      tempFile = xfile.$2;

      final shared = await WhatsappPlatformShare.shareToChat(
        phone: cleanPhone,
        text: message,
        imagePath: tempFile?.path,
      );
      if (shared && tempFile != null) {
        // WhatsApp reads the file asynchronously after startActivity().
        final fileToDelete = tempFile;
        Future<void>.delayed(const Duration(minutes: 2), () async {
          if (await fileToDelete.exists()) {
            await fileToDelete.delete();
          }
        });
        tempFile = null;
      }
      return shared;
    } catch (e) {
      debugPrint('WhatsApp image share failed: $e');
      return false;
    } finally {
      await tempFile?.delete();
    }
  }

  /// Partage marketing image + texte (menu partage / WhatsApp générique).
  Future<bool> _shareImageWithText({
    required Uint8List image,
    required String message,
    required int entityId,
  }) async {
    final trimmed = message.trim();

    try {
      final xfile = await _buildXFile(image, 'uzaapp_$entityId.jpg');
      await Share.shareXFiles(
        [xfile.$1],
        text: trimmed.isNotEmpty ? trimmed : null,
        subject: 'UzaApp',
      );
      await xfile.$2?.delete();
      return true;
    } catch (e) {
      debugPrint('shareXFiles failed: $e');
    }

    if (kIsWeb) {
      if (trimmed.isNotEmpty) {
        final shared = await shareImageAndTextOnWeb(
          imageBytes: image,
          text: trimmed,
          filename: 'uzaapp_$entityId.jpg',
        );
        if (shared) return true;
      }

      try {
        await downloadStatusImages(entityId, [image]);
      } catch (e) {
        debugPrint('Image download fallback failed: $e');
      }

      if (trimmed.isNotEmpty) {
        await _launchWhatsAppWeb(message: trimmed);
        return true;
      }
    }

    return false;
  }

  /// Web/PWA: image produit + message (comme avant : partage natif ou download + WhatsApp).
  Future<void> _sharePreparedOnWeb({
    required int downloadId,
    List<Uint8List>? images,
    String? text,
  }) async {
    final message = text?.trim() ?? '';
    if (images != null && images.isNotEmpty) {
      await _shareImageWithText(
        image: images.first,
        message: message,
        entityId: downloadId,
      );
      return;
    }

    if (message.isEmpty) return;

    try {
      await Share.share(message);
      return;
    } catch (e) {
      debugPrint('Web Share.share failed: $e');
    }

    await _launchWhatsAppWeb(message: message);
  }

  Future<ContactPreview> _resolveWhatsAppContactPayload({
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
    if (entityType == 'product') {
      final product = await (db.select(db.products)
            ..where((t) => t.id.equals(entityId)))
          .getSingleOrNull();
      if (product != null) {
        final shop = await (db.select(db.shops)
              ..where((t) => t.id.equals(product.shopId)))
            .getSingleOrNull();
        return ContactPreview(
          message: _buildProductContactMessage(
            product,
            shop,
            productUrlOverride: productUrl,
          ),
          imageUrl:
              imageUrl ??
              ImageUtils.getDecryptedList(product.imageUrls).firstOrNull,
          entityType: 'product',
          entityId: product.id,
        );
      }
    }

    if (entityType == 'shop') {
      final shop = await (db.select(db.shops)
            ..where((t) => t.id.equals(entityId)))
          .getSingleOrNull();
      if (shop != null) {
        return ContactPreview(
          message: _buildShopBuyerContactMessage(shop),
          imageUrl: imageUrl ?? shop.logoUrl,
          entityType: 'shop',
          entityId: shop.id,
        );
      }
    }

    if (entityType == 'arrivage') {
      final story = await (db.select(db.stories)
            ..where((t) => t.id.equals(entityId)))
          .getSingleOrNull();
      if (story != null) {
        final shop = await (db.select(db.shops)
              ..where((t) => t.id.equals(story.shopId)))
            .getSingleOrNull();
        if (shop != null) {
          final storyImage = imageUrl ?? ImageUtils.resolveImageUrl(story.mediaUrl);
          return ContactPreview(
            message: _buildArrivageBuyerContactMessage(shop),
            imageUrl: storyImage ?? shop.logoUrl,
            entityType: 'arrivage',
            entityId: entityId,
          );
        }
      }
    }

    return ContactPreview(
      message: _buildWhatsAppMessage(
        entityType: entityType,
        entityId: entityId,
        name: name,
        category: category,
        productUrl: productUrl,
        price: price,
        hidePrice: hidePrice,
        condition: condition,
      ),
      imageUrl: imageUrl,
      entityType: entityType,
      entityId: entityId,
    );
  }

  String _buildProductContactMessage(
    Product product,
    Shop? shop, {
    String? productUrlOverride,
  }) {
    final productRef =
        (product.remoteId != null && product.remoteId!.isNotEmpty)
        ? product.remoteId!
        : product.id.toString();
    final url = productUrlOverride ?? 'https://uzaapp.com/product/$productRef';

    final conditionLine = product.condition == 'new'
        ? ShareMessageLabels.conditionNew()
        : ShareMessageLabels.conditionUsed();
    final priceText = ProductPriceUtils.shareLine(product);
    final descLine =
        (product.description != null && product.description!.isNotEmpty)
        ? '${ShareMessageLabels.description(product.description!.length > 120 ? '${product.description!.substring(0, 120)}...' : product.description!)}\n'
        : '';
    final shopLine = shop != null
        ? '${ShareMessageLabels.shop(shop.name)}\n'
        : '';
    final promoLine =
        (product.promotionMessage != null &&
            product.promotionMessage!.trim().isNotEmpty)
        ? '${ShareMessageLabels.promo(product.promotionMessage!.trim())}\n'
        : '';
    final categoryLine =
        (product.category != null && product.category!.trim().isNotEmpty)
        ? '${ShareMessageLabels.category(product.category!.trim())}\n'
        : '';
    final productImages = ImageUtils.getDecryptedList(product.imageUrls);
    final directImageUrl = productImages.isNotEmpty &&
            productImages.first.startsWith('http')
        ? '\n${productImages.first}\n'
        : '';

    return 'Bonjour, je vous contacte depuis UzaApp.\n'
        'Je suis très intéressé(e) par votre article :\n\n'
        '${ShareMessageLabels.productTitle(product.name)}\n'
        '$descLine'
        '$categoryLine'
        '$promoLine'
        '$conditionLine\n'
        '$priceText\n'
        '$shopLine'
        '$directImageUrl'
        '\n'
        '${ShareMessageLabels.productLink(url)}\n\n'
        'Cet article est-il toujours disponible ?\n\n'
        '${ShareMessageLabels.footerCatalog}\n\n'
        '${ShareMessageLabels.hashtagsShopping}';
  }

  String _buildShopBuyerContactMessage(Shop shop) {
    final url = ShopQrUtils.shopUrl(shop);
    final locationParts = <String>[
      if (shop.commune?.trim().isNotEmpty == true) shop.commune!.trim(),
      if (shop.city?.trim().isNotEmpty == true) shop.city!.trim(),
    ];
    final locationLine = locationParts.isNotEmpty
        ? '${ShareMessageLabels.location(locationParts.join(', '))}\n'
        : (shop.address?.trim().isNotEmpty == true
              ? '${ShareMessageLabels.location(shop.address!.trim())}\n'
              : '');
    final verifiedLine =
        shop.isVerified ? '${ShareMessageLabels.verifiedShop()}\n' : '';
    final logoUrl = ImageUtils.resolveImageUrl(shop.logoUrl) ??
        ImageUtils.resolveImageUrl(shop.bannerUrl);
    final logoLine = logoUrl != null && logoUrl.startsWith('http')
        ? '\n$logoUrl\n'
        : '';

    return 'Bonjour, je vous contacte depuis UzaApp.\n'
        'Je suis intéressé(e) par votre boutique :\n\n'
        '${ShareMessageLabels.productTitle(shop.name)}\n'
        '$locationLine'
        '$verifiedLine'
        '$logoLine'
        '\n'
        '${ShareMessageLabels.shopLink(url)}\n\n'
        'Auriez-vous des articles disponibles pour moi ?\n\n'
        '${ShareMessageLabels.footerCatalog}\n\n'
        '${ShareMessageLabels.hashtagsShop}';
  }

  String _buildArrivageBuyerContactMessage(Shop shop) {
    final url = ShopQrUtils.shopUrl(shop);
    return 'Bonjour, je vous contacte depuis UzaApp.\n'
        'Je suis très intéressé(e) par votre *nouvel arrivage* :\n\n'
        '${ShareMessageLabels.arrivageTitle(shop.name)}\n'
        '\n'
        '${ShareMessageLabels.shopLink(url)}\n\n'
        'Est-ce que ces articles sont encore disponibles ?\n\n'
        '${ShareMessageLabels.footerCatalog}\n\n'
        '${ShareMessageLabels.hashtagsArrivage}';
  }

  String _buildWhatsAppMessage({
    required String entityType,
    required int entityId,
    String? name,
    String? category,
    String? productUrl,
    double? price,
    bool hidePrice = false,
    String? condition,
  }) {
    final StringBuffer buf = StringBuffer();

    if (entityType == 'product' && name != null) {
      buf.writeln('Bonjour, je vous contacte depuis UzaApp.');
      buf.writeln('Je suis très intéressé(e) par votre article :');
      buf.writeln(ShareMessageLabels.productTitle(name));
      if (category != null && category.trim().isNotEmpty) {
        buf.writeln(ShareMessageLabels.category(category.trim()));
      }
      if (condition != null && condition.trim().isNotEmpty) {
        final normalized = condition.trim().toLowerCase();
        buf.writeln(
          normalized == 'new'
              ? ShareMessageLabels.conditionNew()
              : ShareMessageLabels.conditionUsed(),
        );
      }
      buf.writeln(
        ProductPriceUtils.shareLineFromValues(
          price: price,
          hidePrice: hidePrice,
        ),
      );
      buf.writeln();
      final productLink = productUrl ?? 'https://uzaapp.com/product/$entityId';
      buf.writeln(ShareMessageLabels.productLink(productLink));
      buf.writeln();
      buf.writeln('Cet article est-il toujours disponible ?');
      buf.writeln();
      buf.writeln(ShareMessageLabels.footerBody);
      buf.writeln();
      buf.writeln(ShareMessageLabels.hashtagsShopping);
    } else if (entityType == 'shop' && name != null) {
      buf.writeln('*${name.trim()}*');
      if (productUrl != null && productUrl.isNotEmpty) {
        buf.writeln(ShareMessageLabels.shopLink(productUrl));
        buf.writeln();
      }
      buf.write('Envoyé depuis UzaApp');
    } else {
      buf.write('Bonjour, je suis intéressé par ce produit sur UzaApp');
    }

    return buf.toString();
  }

  Future<Uint8List?> _composeBrandedShareImage({
    required String entityType,
    String? imageUrl,
  }) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;

    final imageBytes = await ImageUtils.downloadImageBytes(imageUrl);
    if (imageBytes == null || imageBytes.isEmpty) return null;

    try {
      final uzaLogoBytes = await ImageUtils.loadUzaLogoBytes();
      return StatusImageComposer.composeProductShareImage(
        productImageBytes: imageBytes,
        uzaLogoBytes: uzaLogoBytes,
      );
    } catch (e) {
      debugPrint('composeBrandedShareImage failed: $e');
      return null;
    }
  }

  Future<void> makeCall({
    required String phone,
    required String entityType,
    required int entityId,
    String? buyerPhone,
  }) async {
    final tel = PhoneUtils.forTelUri(phone);
    if (tel.isEmpty) return;
    final url = Uri.parse('tel:$tel');
    debugPrint('Launching phone call: $url');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
        await _logInteraction(
          entityType,
          entityId,
          'call',
          buyerPhone: buyerPhone,
        );
      } else {
        throw Exception('Impossible d\'ouvrir l\'application téléphone');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      rethrow;
    }
  }

  Future<void> sendSMS({
    required String phone,
    String? message,
    required String entityType,
    required int entityId,
    String? buyerPhone,
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
        await _logInteraction(
          entityType,
          entityId,
          'sms',
          buyerPhone: buyerPhone,
        );
      } else {
        throw Exception('Impossible d\'ouvrir l\'application SMS');
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      rethrow;
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
    String type, {
    String? buyerPhone,
  }) async {
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
                userPhone: (buyerPhone != null && buyerPhone.trim().isNotEmpty)
                    ? buyerPhone.trim()
                    : 'Client',
                contactType: type,
                productId: drift.Value(productId),
              ),
            );

        syncService?.reportContactStat(
          localShopId: shopId,
          contactType: type,
          localProductId: productId,
          userPhone: buyerPhone,
        );
      }
    } else if (type == 'share' && entityType == 'product') {
      syncService?.reportProductStatByLocalId(entityId, 'share');
    } else if (entityType == 'shop' && ShopStatsTypes.isSynced(type)) {
      syncService?.reportShopInteractionByLocalId(entityId, type);
    }
  }

  Future<void> shareShopQrCode(
    Shop shop, {
    Rect? sharePositionOrigin,
  }) async {
    final String url = ShopQrUtils.shopUrl(shop);
    final bytes = await ShopQrUtils.generateQrPng(url);
    final String text = ShopShareMessages.qrShare(shop);

    if (kIsWeb) {
      await _sharePreparedOnWeb(
        downloadId: shop.id,
        images: [bytes],
        text: text,
      );
      await _logInteraction('shop', shop.id, 'qr_share');
      return;
    }

    final xfile = await _buildXFile(
      bytes,
      'shop_qr_${shop.id}.png',
      mimeType: 'image/png',
    );
    try {
      await Share.shareXFiles(
        [xfile.$1],
        text: text,
        subject: ShopShareMessages.qrShareSubject(shop),
        sharePositionOrigin: sharePositionOrigin,
      );
      await _logInteraction('shop', shop.id, 'qr_share');
    } catch (e) {
      debugPrint('shareShopQrCode failed: $e');
      rethrow;
    } finally {
      await xfile.$2?.delete();
    }
  }

  Future<void> shareAppInvite() async {
    final text = AppShareMessages.merchantInvite();
    if (kIsWeb) {
      await _launchWhatsAppWeb(message: text);
      return;
    }
    await Share.share(
      text,
      subject: AppShareMessages.merchantInviteSubject(),
    );
  }

  Future<void> shareShopCatalog(Shop shop) async {
    final catalog = await ProductRepository(db).getShareableCatalog(shop.id);

    final now = DateTime.now();
    final arrivageStories = await (db.select(db.stories)..where(
          (t) =>
              t.shopId.equals(shop.id) &
              t.isArrivage.equals(true) &
              t.expiresAt.isBiggerThanValue(now),
        ))
        .get();

    final text = ShopShareMessages.catalogShare(
      shop,
      arrivals: catalog.arrivals,
      products: catalog.products,
      activeArrivageStories: arrivageStories.length,
    );

    final logoBytes = await _downloadShopLogoBytes(shop);
    if (logoBytes != null) {
      if (kIsWeb) {
        await _sharePreparedOnWeb(
          downloadId: shop.id,
          images: [logoBytes],
          text: text,
        );
        await _logInteraction('shop', shop.id, 'catalog_share');
        return;
      }
      try {
        final xfile = await _buildXFile(
          logoBytes,
          'shop_logo_${shop.id}.jpg',
        );
        await Share.shareXFiles(
          [xfile.$1],
          text: text,
          subject: ShopShareMessages.catalogShareSubject(shop),
        );
        await xfile.$2?.delete();
        await _logInteraction('shop', shop.id, 'catalog_share');
        return;
      } catch (e) {
        debugPrint('Catalog logo share failed: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'catalog_share');
  }

  Future<Uint8List?> _downloadShopLogoBytes(Shop shop) async {
    final resolved = ImageUtils.resolveImageUrl(shop.logoUrl);
    if (resolved == null || resolved.isEmpty) return null;
    try {
      if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        final response = await http.get(Uri.parse(resolved));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      }
    } catch (e) {
      debugPrint('Shop logo download failed: $e');
    }
    return null;
  }

  Future<void> shareShop(Shop shop) async {
    final String text = ShopShareMessages.linkShare(shop);

    final logoBytes = await _downloadShopLogoBytes(shop);
    if (logoBytes != null) {
      if (kIsWeb) {
        await _sharePreparedOnWeb(
          downloadId: shop.id,
          images: [logoBytes],
          text: text,
        );
        await _logInteraction('shop', shop.id, 'share');
        return;
      }
      try {
        final xfile = await _buildXFile(
          logoBytes,
          'shop_logo_${shop.id}.jpg',
        );
        await Share.shareXFiles(
          [xfile.$1],
          text: text,
          subject: ShopShareMessages.linkShareSubject(shop),
        );
        await xfile.$2?.delete();
        await _logInteraction('shop', shop.id, 'share');
        return;
      } catch (e) {
        debugPrint('Shop image share failed: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'share');
  }

  Future<void> shareProduct(
    Product product,
    Shop? shop, {
    Uint8List? precomposedImage,
  }) async {
    Shop? actualShop = shop;
    actualShop ??= await (db.select(
      db.shops,
    )..where((t) => t.id.equals(product.shopId))).getSingleOrNull();

    final text = ProductShareMessages.share(product, actualShop);
    final String? productImageSource =
        ImageUtils.getDecryptedList(product.imageUrls).firstOrNull;
    final Uint8List? productImageBytes = await ImageUtils.downloadImageBytes(
      productImageSource,
    );

    if (productImageBytes != null && productImageBytes.isNotEmpty) {
      try {
        final shareImageBytes = precomposedImage ??
            await StatusImageComposer.composeProductShareImage(
              productImageBytes: productImageBytes,
              uzaLogoBytes: await ImageUtils.loadUzaLogoBytes(),
            );
        if (kIsWeb) {
          await _sharePreparedOnWeb(
            downloadId: product.id,
            images: [shareImageBytes],
            text: text,
          );
          await _logInteraction('product', product.id, 'share');
          return;
        }
        final xfile = await _buildXFile(
          shareImageBytes,
          'product_${product.id}.jpg',
        );
        await Share.shareXFiles(
          [xfile.$1],
          text: text,
          subject: ProductShareMessages.subject(product),
        );
        await xfile.$2?.delete();
        await _logInteraction('product', product.id, 'share');
        return;
      } catch (e) {
        debugPrint('Product image share failed: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('product', product.id, 'share');
  }

  Future<void> shareStory(
    Story story,
    Shop shop, {
    String? imageUrl,
  }) async {
    final text = StatusShareMessages.storyShare(
      shop,
      isArrivage: story.isArrivage,
    );
    final source =
        imageUrl ??
        ImageUtils.resolveImageUrl(
          story.mediaUrl.isNotEmpty ? story.mediaUrl : null,
        );
    final imageBytes = await ImageUtils.downloadImageBytes(source);

    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final uzaLogoBytes = await ImageUtils.loadUzaLogoBytes();
        final shareImageBytes = await StatusImageComposer.composeProductShareImage(
          productImageBytes: imageBytes,
          uzaLogoBytes: uzaLogoBytes,
        );
        if (kIsWeb) {
          await _sharePreparedOnWeb(
            downloadId: shop.id,
            images: [shareImageBytes],
            text: text,
          );
          await _logInteraction('shop', shop.id, 'story_share');
          return;
        }
        final xfile = await _buildXFile(
          shareImageBytes,
          'story_${story.id}.jpg',
        );
        await Share.shareXFiles(
          [xfile.$1],
          text: text,
          subject: StatusShareMessages.storyShareSubject(
            shop,
            isArrivage: story.isArrivage,
          ),
        );
        await xfile.$2?.delete();
        await _logInteraction('shop', shop.id, 'story_share');
        return;
      } catch (e) {
        debugPrint('Story image share failed: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'story_share');
  }

  /// Returns (XFile, File?) — File is non-null on mobile so caller can delete it.
  Future<(XFile, File?)> _buildXFile(
    List<int> bytes,
    String filename, {
    String mimeType = 'image/jpeg',
  }) async {
    if (kIsWeb) {
      // Web: in-memory XFile (no temp file needed)
      final xfile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: mimeType,
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
    if (kIsWeb) {
      try {
        await Share.share(text);
        return;
      } catch (e) {
        debugPrint('Web Share.share failed: $e');
      }
      await _launchWhatsAppWeb(message: text);
      return;
    }
    try {
      await Share.share(text);
    } catch (e) {
      debugPrint('Share plugin failed, trying fallback: $e');
      final String encodedText = Uri.encodeComponent(text);
      final url = Uri.parse("https://wa.me/?text=$encodedText");
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> _shareStatusFilesOnly({
    required List<XFile> files,
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
    Future<void> Function()? onShareUnavailable,
  }) async {
    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          files,
          text: text,
          subject: subject,
        );
        return;
      } catch (e) {
        debugPrint('Web shareXFiles status failed: $e');
      }
      if (onShareUnavailable != null) {
        await onShareUnavailable();
        return;
      }
      if (text != null && text.trim().isNotEmpty) {
        await _launchWhatsAppWeb(message: text.trim());
      }
      return;
    }
    try {
      await Share.shareXFiles(
        files,
        text: text,
        subject: subject,
        sharePositionOrigin: kIsWeb ? null : sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('shareStatusFilesOnly failed: $e');
      if (onShareUnavailable != null) {
        await onShareUnavailable();
        return;
      }
      rethrow;
    }
  }

  Future<void> shareStatusToFacebook({
    required Shop shop,
    required List<XFile> images,
    List<String>? tempPaths,
    Rect? sharePositionOrigin,
    List<Uint8List>? rawImagesForWebFallback,
  }) async {
    if (images.isEmpty) return;

    final text = StatusShareMessages.collectionShare(
      shop,
      imageCount: images.length,
    );

    try {
      await _shareStatusFilesOnly(
        files: images,
        text: text,
        subject: StatusShareMessages.collectionShareSubject(shop),
        sharePositionOrigin: sharePositionOrigin,
        onShareUnavailable: rawImagesForWebFallback != null &&
                rawImagesForWebFallback.isNotEmpty
            ? () => _sharePreparedOnWeb(
                downloadId: shop.id,
                images: rawImagesForWebFallback,
                text: text,
              )
            : null,
      );
      await _logInteraction('shop', shop.id, 'facebook_status');
    } finally {
      if (tempPaths != null && tempPaths.isNotEmpty) {
        await deleteStatusTempFiles(tempPaths);
      }
    }
  }

  Future<StatusSlideshowExport?> buildTikTokStatusExport({
    required Shop shop,
    required List<Uint8List> images,
  }) async {
    if (images.isEmpty) return null;
    return StatusSlideshowVideo.exportForTikTok(
      images: images,
      shopId: shop.id,
      shopName: shop.name,
    );
  }

  Future<void> shareTikTokStatusExport({
    required Shop shop,
    required StatusSlideshowExport? export,
    required List<Uint8List> fallbackImages,
    Rect? sharePositionOrigin,
  }) async {
    if (fallbackImages.isEmpty) return;

    final text = StatusShareMessages.collectionShare(
      shop,
      imageCount: fallbackImages.length,
    );
    final subject = StatusShareMessages.collectionShareSubject(shop);

    File? tempVideoFile;
    try {
      if (export == null) {
        final slides =
            fallbackImages.take(StatusSlideshowVideo.tikTokMaxSlides).toList();
        final (xfiles, tempPaths) = await writeStatusShareFiles(
          shop.id,
          slides,
        );
        try {
          await _shareStatusFilesOnly(
            files: xfiles,
            text: text,
            subject: subject,
            sharePositionOrigin: sharePositionOrigin,
            onShareUnavailable: kIsWeb
                ? () => _sharePreparedOnWeb(
                    downloadId: shop.id,
                    images: slides,
                    text: text,
                  )
                : null,
          );
        } finally {
          if (tempPaths.isNotEmpty) {
            await deleteStatusTempFiles(tempPaths);
          }
        }
      } else if (kIsWeb) {
        final slides =
            fallbackImages.take(StatusSlideshowVideo.tikTokMaxSlides).toList();
        await _sharePreparedOnWeb(
          downloadId: shop.id,
          images: slides,
          text: text,
        );
      } else {
        tempVideoFile = File(export.filePath);
        await _shareStatusFilesOnly(
          files: [
            XFile(
              export.filePath,
              mimeType: 'video/mp4',
              name: 'uza_tiktok_${shop.id}.mp4',
            ),
          ],
          text: text,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        );
      }
      await _logInteraction('shop', shop.id, 'tiktok_status');
    } finally {
      if (tempVideoFile != null && await tempVideoFile.exists()) {
        await tempVideoFile.delete();
      }
    }
  }

  Future<void> shareStatusToTikTok({
    required Shop shop,
    required List<Uint8List> images,
    Rect? sharePositionOrigin,
  }) async {
    if (images.isEmpty) return;
    final export = await buildTikTokStatusExport(shop: shop, images: images);
    await shareTikTokStatusExport(
      shop: shop,
      export: export,
      fallbackImages: images,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> shareStatusCollection({
    required Shop shop,
    required List<XFile> images,
    List<String>? tempPaths,
    Rect? sharePositionOrigin,
    List<Uint8List>? rawImagesForWebFallback,
  }) async {
    if (images.isEmpty) return;

    final text = StatusShareMessages.collectionShare(
      shop,
      imageCount: images.length,
    );

    try {
      await _shareStatusFilesOnly(
        files: images,
        text: text,
        subject: StatusShareMessages.collectionShareSubject(shop),
        sharePositionOrigin: sharePositionOrigin,
        onShareUnavailable: rawImagesForWebFallback != null &&
                rawImagesForWebFallback.isNotEmpty
            ? () => _sharePreparedOnWeb(
                downloadId: shop.id,
                images: rawImagesForWebFallback,
                text: text,
              )
            : null,
      );
      await _logInteraction('shop', shop.id, 'whatsapp_status');
    } catch (e) {
      debugPrint('shareStatusCollection failed: $e');
      if (rawImagesForWebFallback != null &&
          rawImagesForWebFallback.isNotEmpty) {
        await _sharePreparedOnWeb(
          downloadId: shop.id,
          images: rawImagesForWebFallback,
          text: text,
        );
        await _logInteraction('shop', shop.id, 'whatsapp_status');
        return;
      }
      rethrow;
    } finally {
      if (tempPaths != null && tempPaths.isNotEmpty) {
        await deleteStatusTempFiles(tempPaths);
      }
    }
  }
}
