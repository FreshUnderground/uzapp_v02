import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Normalized image ready for upload (JPEG when conversion succeeds).
class PreparedImage {
  final Uint8List bytes;
  final String fileName;

  const PreparedImage({required this.bytes, required this.fileName});
}

/// Converts picked images (incl. iPhone HEIC/HEIF) to upload-safe JPEG bytes.
class ImagePrepareUtils {
  static const int maxImageUploadBytes = 5 * 1024 * 1024;

  static const Set<String> _heicExtensions = {'heic', 'heif', 'hif'};

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
    'hif',
  };

  static bool isHeicOrHeif(Uint8List bytes, {String? sourceName}) {
    if (sourceName != null && sourceName.contains('.')) {
      final ext = sourceName.split('.').last.toLowerCase();
      if (_heicExtensions.contains(ext)) return true;
    }
    if (bytes.length < 12) return false;
    final boxType = String.fromCharCodes(bytes.sublist(4, 8));
    if (boxType != 'ftyp') return false;
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    return brand.startsWith('hei') || brand == 'mif1' || brand == 'msf1';
  }

  static String extensionFromName(String? name) {
    if (name == null || !name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  static String buildUploadFileName({String prefix = 'image', String ext = 'jpg'}) {
    final safeExt = _imageExtensions.contains(ext) ? ext : 'jpg';
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
  }

  /// Prepare bytes (and optional native path) for API upload.
  static Future<PreparedImage> prepareForUpload(
    Uint8List bytes, {
    String? sourceName,
    String? sourcePath,
    int maxWidth = 1080,
    int quality = 70,
    String prefix = 'image',
  }) async {
    Uint8List? output;

    if (!kIsWeb && sourcePath != null && sourcePath.isNotEmpty) {
      try {
        final fromFile = await FlutterImageCompress.compressWithFile(
          sourcePath,
          minWidth: maxWidth,
          minHeight: maxWidth,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (fromFile != null && fromFile.isNotEmpty) {
          output = fromFile;
        }
      } catch (e) {
        debugPrint('ImagePrepareUtils: compressWithFile failed: $e');
      }
    }

    output ??= await _compressToJpeg(
      bytes,
      maxWidth: maxWidth,
      quality: quality,
    );

    final finalBytes = output ?? bytes;
    final isHeic = isHeicOrHeif(finalBytes, sourceName: sourceName);
    final ext = output != null
        ? 'jpg'
        : (isHeic
              ? extensionFromName(sourceName).isNotEmpty
                    ? extensionFromName(sourceName)
                    : 'heic'
              : 'jpg');

    return PreparedImage(
      bytes: finalBytes,
      fileName: buildUploadFileName(prefix: prefix, ext: ext),
    );
  }

  static Future<Uint8List?> _compressToJpeg(
    Uint8List imageBytes, {
    required int maxWidth,
    required int quality,
  }) async {
    try {
      if (!kIsWeb) {
        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: maxWidth,
          minHeight: maxWidth,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (result.isNotEmpty) {
          debugPrint(
            'ImagePrepareUtils: ${imageBytes.length} -> ${result.length} bytes',
          );
          return result;
        }
        return null;
      }

      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        if (isHeicOrHeif(imageBytes)) {
          debugPrint(
            'ImagePrepareUtils: HEIC on web — upload brut, conversion serveur',
          );
        }
        return null;
      }

      final resized = decoded.width > maxWidth
          ? img.copyResize(decoded, width: maxWidth)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      debugPrint('ImagePrepareUtils: compression failed: $e');
      return null;
    }
  }

  static Future<Uint8List> ensureUploadSize(
    Uint8List bytes, {
    int maxWidth = 1080,
    int quality = 60,
  }) async {
    if (bytes.length <= maxImageUploadBytes) return bytes;
    final smaller = await _compressToJpeg(
      bytes,
      maxWidth: maxWidth,
      quality: quality,
    );
    return smaller ?? bytes;
  }

  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
