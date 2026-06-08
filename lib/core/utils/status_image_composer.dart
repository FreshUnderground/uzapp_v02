import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import '../res/uza_colors.dart';

/// Builds branded 9:16 WhatsApp Status images from product photos.
class StatusImageComposer {
  static const int canvasWidth = 1080;
  static const int canvasHeight = 1920;

  static Future<Uint8List> composeStatusImage({
    required Uint8List productImageBytes,
    required String productName,
    required String shopName,
    Uint8List? shopLogoBytes,
    Uint8List? uzaLogoBytes,
  }) async {
    final productCodec = await ui.instantiateImageCodec(productImageBytes);
    final productFrame = await productCodec.getNextFrame();
    final productImage = productFrame.image;

    final shopLogo = await _bytesToImage(shopLogoBytes);
    final uzaLogo = await _bytesToImage(uzaLogoBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(canvasWidth.toDouble(), canvasHeight.toDouble());

    _drawCoverImage(canvas, productImage, size);
    _drawVignette(canvas, size);
    _drawTopBrandBar(canvas, size, shopLogo: shopLogo, uzaLogo: uzaLogo);
    _drawBottomPanel(
      canvas,
      size,
      productName: productName,
      shopName: shopName,
      shopLogo: shopLogo,
      uzaLogo: uzaLogo,
    );

    productImage.dispose();
    shopLogo?.dispose();
    uzaLogo?.dispose();

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(canvasWidth, canvasHeight);
    picture.dispose();

    final pngBytes = await _imageToPng(rendered);
    rendered.dispose();

    return _encodeJpeg(pngBytes);
  }

  static Future<ui.Image?> _bytesToImage(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('StatusImageComposer: logo decode failed: $e');
      return null;
    }
  }

  static void _drawCoverImage(Canvas canvas, ui.Image source, Size size) {
    final srcW = source.width.toDouble();
    final srcH = source.height.toDouble();
    final scale = math.max(size.width / srcW, size.height / srcH);
    final drawW = srcW * scale;
    final drawH = srcH * scale;
    final dx = (size.width - drawW) / 2;
    final dy = (size.height - drawH) / 2;

    canvas.drawImageRect(
      source,
      Rect.fromLTWH(0, 0, srcW, srcH),
      Rect.fromLTWH(dx, dy, drawW, drawH),
      Paint(),
    );
  }

  static void _drawVignette(Canvas canvas, Size size) {
    final topFade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.45),
        Colors.transparent,
      ],
      stops: const [0.0, 0.22],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.28),
      Paint()
        ..shader = topFade.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height * 0.28),
        ),
    );

    final bottomFade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.35),
        Colors.black.withValues(alpha: 0.82),
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    final panelTop = size.height * 0.48;
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, size.width, size.height - panelTop),
      Paint()
        ..shader = bottomFade.createShader(
          Rect.fromLTWH(0, panelTop, size.width, size.height - panelTop),
        ),
    );
  }

  static void _drawTopBrandBar(
    Canvas canvas,
    Size size, {
    ui.Image? shopLogo,
    ui.Image? uzaLogo,
  }) {
    const margin = 48.0;
    const barHeight = 104.0;
    const logoRadius = 40.0;
    final barCenterY = 64.0 + barHeight / 2;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, 64, size.width - margin * 2, barHeight),
      Radius.circular(barHeight / 2),
    );

    canvas.drawRRect(
      barRect,
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    canvas.drawRRect(
      barRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final shopCenter = Offset(margin + logoRadius + 16, barCenterY);
    _drawLogoCircle(
      canvas,
      shopLogo,
      shopCenter,
      logoRadius,
      fallbackIcon: Icons.storefront_rounded,
      ringColor: UzaColors.primary,
    );

    final uzaLogoCenter = Offset(size.width - margin - logoRadius - 16, barCenterY);
    _drawLogoCircle(
      canvas,
      uzaLogo,
      uzaLogoCenter,
      logoRadius,
      fallbackLabel: 'U',
      ringColor: UzaColors.primary,
    );

    _paintText(
      canvas,
      text: 'UzaApp',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      maxWidth: 200,
      offset: Offset(uzaLogoCenter.dx - 156, barCenterY - 18),
    );
  }

  static void _drawBottomPanel(
    Canvas canvas,
    Size size, {
    required String productName,
    required String shopName,
    ui.Image? shopLogo,
    ui.Image? uzaLogo,
  }) {
    const horizontal = 56.0;
    final maxWidth = size.width - horizontal * 2;
    const shopLogoRadius = 34.0;
    const uzaFooterRadius = 28.0;
    const footerStyle = TextStyle(
      color: Colors.white,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
    const shopNameStyle = TextStyle(
      color: Colors.white,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    var contentHeight = 40.0;
    contentHeight += _measureText(
      _truncate(productName, 52),
      const TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      maxWidth,
      maxLines: 2,
    );
    contentHeight += 20 + 5 + 20;
    contentHeight += shopLogoRadius * 2;
    contentHeight += 14;
    contentHeight += uzaFooterRadius * 2;
    contentHeight += 40;

    final panelTop = size.height - contentHeight - 40;
    final panelHeight = size.height - panelTop - 32;

    final panelRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(32, panelTop, size.width - 64, panelHeight),
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
    );
    canvas.drawRRect(
      panelRect,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    var y = panelTop + 36;

    y += _paintText(
      canvas,
      text: _truncate(productName, 52),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 50,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.5,
      ),
      maxWidth: maxWidth,
      offset: Offset(horizontal, y),
      maxLines: 2,
      shadow: true,
    );
    y += 20;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(horizontal, y, 72, 5),
        const Radius.circular(3),
      ),
      Paint()..color = UzaColors.primary,
    );
    y += 20;

    final shopRowCenterY = y + shopLogoRadius;
    _drawLogoCircle(
      canvas,
      shopLogo,
      Offset(horizontal + shopLogoRadius, shopRowCenterY),
      shopLogoRadius,
      fallbackIcon: Icons.store_rounded,
      ringColor: UzaColors.primary,
    );

    final shopNameHeight = _measureText(
      _truncate(shopName, 36),
      shopNameStyle,
      maxWidth - shopLogoRadius * 2 - 24,
      maxLines: 1,
    );
    _paintText(
      canvas,
      text: _truncate(shopName, 36),
      style: shopNameStyle,
      maxWidth: maxWidth - shopLogoRadius * 2 - 24,
      offset: Offset(
        horizontal + shopLogoRadius * 2 + 20,
        shopRowCenterY - shopNameHeight / 2,
      ),
      maxLines: 1,
    );
    y += shopLogoRadius * 2 + 14;

    final footerCenterY = y + uzaFooterRadius;
    _drawLogoCircle(
      canvas,
      uzaLogo,
      Offset(horizontal + uzaFooterRadius, footerCenterY),
      uzaFooterRadius,
      fallbackLabel: 'U',
      ringColor: UzaColors.primary,
    );

    final footerText = 'Disponible sur UzaApp';
    final footerTextHeight = _measureText(
      footerText,
      footerStyle,
      maxWidth - uzaFooterRadius * 2 - 20,
      maxLines: 1,
    );
    _paintText(
      canvas,
      text: footerText,
      style: footerStyle.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
      maxWidth: maxWidth - uzaFooterRadius * 2 - 20,
      offset: Offset(
        horizontal + uzaFooterRadius * 2 + 16,
        footerCenterY - footerTextHeight / 2,
      ),
      maxLines: 1,
    );
  }

  static void _drawLogoCircle(
    Canvas canvas,
    ui.Image? logo,
    Offset center,
    double radius, {
    IconData? fallbackIcon,
    String? fallbackLabel,
    Color ringColor = Colors.white,
  }) {
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()..color = ringColor,
    );
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    if (logo != null) {
      final srcW = logo.width.toDouble();
      final srcH = logo.height.toDouble();
      final scale = math.max((radius * 2) / srcW, (radius * 2) / srcH);
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromCenter(
          center: center,
          width: srcW * scale,
          height: srcH * scale,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else if (fallbackLabel != null) {
      _paintText(
        canvas,
        text: fallbackLabel,
        style: TextStyle(
          color: UzaColors.primary,
          fontSize: radius * 1.1,
          fontWeight: FontWeight.w800,
        ),
        maxWidth: radius * 2,
        offset: Offset(center.dx - radius * 0.35, center.dy - radius * 0.58),
        maxLines: 1,
      );
    } else if (fallbackIcon != null) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(fallbackIcon.codePoint),
          style: TextStyle(
            fontFamily: fallbackIcon.fontFamily,
            package: fallbackIcon.fontPackage,
            fontSize: radius * 1.1,
            color: UzaColors.primary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - iconPainter.width / 2,
          center.dy - iconPainter.height / 2,
        ),
      );
    }
    canvas.restore();
  }

  static double _measureText(
    String text,
    TextStyle style,
    double maxWidth, {
    int maxLines = 2,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  static double _paintText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required double maxWidth,
    required Offset offset,
    int maxLines = 2,
    bool shadow = false,
  }) {
    if (shadow) {
      final shadowPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            color: Colors.black.withValues(alpha: 0.35),
            shadows: const [],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      shadowPainter.paint(canvas, offset.translate(0, 2));
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, offset);
    return painter.height;
  }

  static String _truncate(String value, int maxChars) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars - 1).trim()}…';
  }

  static Future<Uint8List> _imageToPng(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('StatusImageComposer: PNG encode failed');
    }
    return byteData.buffer.asUint8List();
  }

  static Future<Uint8List> _encodeJpeg(Uint8List pngBytes) async {
    if (!kIsWeb) {
      try {
        final jpeg = await FlutterImageCompress.compressWithList(
          pngBytes,
          quality: 88,
          format: CompressFormat.jpeg,
        );
        if (jpeg.isNotEmpty) return jpeg;
      } catch (e) {
        debugPrint('StatusImageComposer: JPEG compress failed: $e');
      }
    }

    try {
      final decoded = img.decodePng(pngBytes);
      if (decoded != null) {
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
      }
    } catch (e) {
      debugPrint('StatusImageComposer: PNG→JPEG failed: $e');
    }

    return pngBytes;
  }
}
