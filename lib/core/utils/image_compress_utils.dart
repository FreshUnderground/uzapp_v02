import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'image_prepare_utils.dart';

/// @deprecated Prefer [ImagePrepareUtils.prepareForUpload] for new code.
class ImageCompressUtils {
  static int get maxImageUploadBytes => ImagePrepareUtils.maxImageUploadBytes;

  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int quality = 70,
    String? sourceName,
    String? sourcePath,
  }) async {
    try {
      final prepared = await ImagePrepareUtils.prepareForUpload(
        imageBytes,
        sourceName: sourceName,
        sourcePath: sourcePath,
        maxWidth: maxWidth,
        quality: quality,
      );
      return prepared.bytes;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return imageBytes;
    }
  }

  static Future<Uint8List?> compressThumbnail(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int quality = 50,
    String? sourceName,
    String? sourcePath,
  }) async {
    return compressImage(
      imageBytes,
      maxWidth: maxWidth,
      quality: quality,
      sourceName: sourceName,
      sourcePath: sourcePath,
    );
  }

  static String getFileSizeString(int bytes) =>
      ImagePrepareUtils.getFileSizeString(bytes);
}
