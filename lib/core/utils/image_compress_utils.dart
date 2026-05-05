import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressUtils {
  /// Compress image bytes for upload
  /// Target: max 800px width, 70% quality JPEG
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int quality = 70,
  }) async {
    try {
      if (kIsWeb) {
        // flutter_image_compress doesn't support web well
        // Return original bytes on web
        return imageBytes;
      }

      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      debugPrint(
        'Image compressed: ${imageBytes.length} -> ${result.length} bytes '
        '(${((1 - result.length / imageBytes.length) * 100).toStringAsFixed(1)}% reduction)',
      );

      return result;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return imageBytes; // Return original on failure
    }
  }

  /// Compress image for thumbnail (smaller, lower quality)
  static Future<Uint8List?> compressThumbnail(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int quality = 50,
  }) async {
    return compressImage(imageBytes, maxWidth: maxWidth, quality: quality);
  }

  /// Get estimated file size string
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
