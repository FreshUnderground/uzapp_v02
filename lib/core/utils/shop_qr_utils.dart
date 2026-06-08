import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/local/uza_database.dart';

class ShopQrUtils {
  ShopQrUtils._();

  static const String _logoAsset = 'assets/logo.png';

  /// Public shop id for URLs (server/MySQL id when synced).
  static String shopPublicId(Shop shop) {
    if (shop.remoteId != null && shop.remoteId!.isNotEmpty) {
      return shop.remoteId!;
    }
    return shop.id.toString();
  }

  static String shopUrl(Shop shop) =>
      'https://uzaapp.com/shop/${shopPublicId(shop)}';

  static ImageProvider<Object> get uzaLogoProvider =>
      const AssetImage(_logoAsset);

  static QrEmbeddedImageStyle embeddedImageStyleFor(double qrSize) {
    final logoSize = (qrSize * 0.22).clamp(40.0, 120.0);
    return QrEmbeddedImageStyle(
      size: Size(logoSize, logoSize),
    );
  }

  static Future<ui.Image?> loadUzaLogoImage() async {
    try {
      final data = await rootBundle.load(_logoAsset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> generateQrPng(
    String data, {
    double size = 512,
  }) async {
    final logo = await loadUzaLogoImage();
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      embeddedImage: logo,
      embeddedImageStyle: embeddedImageStyleFor(size),
    );
    final imageData = await painter.toImageData(
      size,
      format: ui.ImageByteFormat.png,
    );
    logo?.dispose();
    if (imageData == null) {
      throw StateError('Impossible de générer le QR code');
    }
    return imageData.buffer.asUint8List();
  }
}
