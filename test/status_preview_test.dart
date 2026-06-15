import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uzaapp/core/utils/status_image_composer.dart';

/// Génère un aperçu local : preview_status_square.jpg (produit carré).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate status preview images', () async {
    final squareProduct = Uint8List.fromList(
      img.encodeJpg(_makeSampleProduct(width: 900, height: 900)),
    );
    final wideProduct = Uint8List.fromList(
      img.encodeJpg(_makeSampleProduct(width: 1200, height: 700)),
    );

    final squareBytes = await StatusImageComposer.composeStatusImage(
      productImageBytes: squareProduct,
      productName: 'Nike Air Max 270',
      shopName: 'Ma Boutique Kinshasa',
    );
    final wideBytes = await StatusImageComposer.composeStatusImage(
      productImageBytes: wideProduct,
      productName: 'Samsung Galaxy A54',
      shopName: 'Tech Store Goma',
    );

    final outDir = Directory('preview_output');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    await File('preview_output/status_square.jpg').writeAsBytes(squareBytes);
    await File('preview_output/status_wide.jpg').writeAsBytes(wideBytes);

    expect(squareBytes.isNotEmpty, isTrue);
    expect(wideBytes.isNotEmpty, isTrue);
  });
}

img.Image _makeSampleProduct({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgba8(235, 238, 245, 255));
  img.fillRect(
    image,
    x1: (width * 0.12).round(),
    y1: (height * 0.18).round(),
    x2: (width * 0.88).round(),
    y2: (height * 0.82).round(),
    color: img.ColorRgba8(255, 255, 255, 255),
  );
  img.fillRect(
    image,
    x1: (width * 0.28).round(),
    y1: (height * 0.35).round(),
    x2: (width * 0.72).round(),
    y2: (height * 0.68).round(),
    color: img.ColorRgba8(254, 62, 0, 255),
  );
  return image;
}
