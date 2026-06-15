import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../utils/crypto_utils.dart';
import '../utils/image_utils.dart';
import '../utils/phone_utils.dart';
import '../utils/product_price_utils.dart';
import '../utils/shop_qr_utils.dart';
import '../utils/app_share_messages.dart';
import '../utils/shop_share_messages.dart';
import '../utils/status_image_composer.dart';
import '../utils/status_slideshow_video.dart' show StatusSlideshowExport, StatusSlideshowVideo;
import '../utils/status_temp_files.dart';
import '../utils/status_web_download.dart';

class ContactService {
  final UzaDatabase db;

  ContactService(this.db);

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
        await _logInteraction(
          entityType,
          entityId,
          'whatsapp',
          buyerPhone: buyerPhone,
        );
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
    String? buyerPhone,
  }) async {
    final tel = PhoneUtils.forTelUri(phone);
    if (tel.isEmpty) return;
    final url = Uri.parse('tel:$tel');
    debugPrint('Launching phone call: $url');

    try {
      if (await canLaunchUrl(url)) {
        // Use platformDefaultLaunchMode for tel: URLs to work on all platforms
        await launchUrl(url, mode: LaunchMode.platformDefault);
        await _logInteraction(
          entityType,
          entityId,
          'call',
          buyerPhone: buyerPhone,
        );
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
      }
    }
  }

  Future<void> shareShopQrCode(
    Shop shop, {
    Rect? sharePositionOrigin,
  }) async {
    final String url = ShopQrUtils.shopUrl(shop);
    final bytes = await ShopQrUtils.generateQrPng(url);
    final xfile = await _buildXFile(
      bytes,
      'shop_qr_${shop.id}.png',
      mimeType: 'image/png',
    );
    final String text = ShopShareMessages.qrShare(shop);

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
      if (kIsWeb) {
        await downloadStatusImages(shop.id, [bytes]);
        await _logInteraction('shop', shop.id, 'qr_share');
        return;
      }
      rethrow;
    } finally {
      await xfile.$2?.delete();
    }
  }

  Future<void> shareAppInvite() async {
    await Share.share(
      AppShareMessages.merchantInvite(),
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

    await _shareText(text);
    await _logInteraction('shop', shop.id, 'catalog_share');
  }

  Future<void> shareShop(Shop shop) async {
    final String text = ShopShareMessages.linkShare(shop);

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
              subject: ShopShareMessages.linkShareSubject(shop),
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

    final composedImage = await _composeProductShareImage(product);
    if (composedImage != null) {
      try {
        final xfile = await _buildXFile(
          composedImage,
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
      } catch (e) {
        debugPrint('Product image share failed, using text fallback: $e');
      }
    }

    await _shareText(text);
    await _logInteraction('product', product.id, 'share');
  }

  Future<Uint8List?> _composeProductShareImage(Product product) async {
    final images = ImageUtils.getDecryptedList(product.imageUrls);
    if (images.isEmpty) return null;

    Uint8List? productBytes;
    for (final url in images) {
      productBytes = await ImageUtils.downloadImageBytes(url);
      if (productBytes != null && productBytes.isNotEmpty) break;
    }
    if (productBytes == null) return null;

    final uzaLogoBytes = await ImageUtils.loadUzaLogoBytes();

    try {
      return await StatusImageComposer.composeProductShareImage(
        productImageBytes: productBytes,
        uzaLogoBytes: uzaLogoBytes,
      );
    } catch (e) {
      debugPrint('Product share image compose failed: $e');
      return null;
    }
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

  Future<void> _shareStatusFilesOnly({
    required List<XFile> files,
    Rect? sharePositionOrigin,
    Future<void> Function()? onShareUnavailable,
  }) async {
    try {
      await Share.shareXFiles(
        files,
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

    try {
      await _shareStatusFilesOnly(
        files: images,
        sharePositionOrigin: sharePositionOrigin,
        onShareUnavailable: rawImagesForWebFallback != null &&
                rawImagesForWebFallback.isNotEmpty
            ? () => downloadStatusImages(shop.id, rawImagesForWebFallback)
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
            sharePositionOrigin: sharePositionOrigin,
            onShareUnavailable: kIsWeb
                ? () => downloadStatusImages(shop.id, slides)
                : null,
          );
        } finally {
          if (tempPaths.isNotEmpty) {
            await deleteStatusTempFiles(tempPaths);
          }
        }
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

    try {
      await _shareStatusFilesOnly(
        files: images,
        sharePositionOrigin: sharePositionOrigin,
        onShareUnavailable: rawImagesForWebFallback != null &&
                rawImagesForWebFallback.isNotEmpty
            ? () => downloadStatusImages(shop.id, rawImagesForWebFallback)
            : null,
      );
      await _logInteraction('shop', shop.id, 'whatsapp_status');
    } catch (e) {
      debugPrint('shareStatusCollection failed: $e');
      if (rawImagesForWebFallback != null &&
          rawImagesForWebFallback.isNotEmpty) {
        await downloadStatusImages(shop.id, rawImagesForWebFallback);
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
