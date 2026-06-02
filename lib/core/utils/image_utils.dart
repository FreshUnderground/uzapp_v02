import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'crypto_utils.dart';

class ImageUtils {
  // Proxy URL for external images (to avoid CORS on web)
  static const String _proxyBaseUrl = 'https://uzaapp.com/api/proxy.php?url=';

  /// Convert external URLs to proxy URLs (only on web platform)
  static String _getProxiedUrl(String url) {
    if (!kIsWeb) return url; // No proxy needed for mobile
    if (url.isEmpty) return url;

    // Don't proxy if already proxied
    if (url.contains('proxy.php')) return url;

    // Don't proxy if it's already our server URL
    if (url.contains('uzaapp.com')) return url;

    // Only proxy external storage URLs
    if (url.contains('firebasestorage.googleapis.com') ||
        url.contains('storage.googleapis.com')) {
      // Legacy: some image data still contains Firebase Storage URLs
      return '$_proxyBaseUrl${Uri.encodeComponent(url)}';
    }
    return url;
  }

  static ImageProvider? getImageProvider(String? encryptedSource) {
    if (encryptedSource == null || encryptedSource.isEmpty) return null;

    var source = CryptoUtils.decrypt(encryptedSource);
    if (source.isEmpty) return null;

    // Unescape slashes for legacy URLs
    if (source.contains(r'\/')) {
      source = source.replaceAll(r'\/', '/');
    }

    if (source.startsWith('data:image')) {
      try {
        final base64String = source.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }

    return NetworkImage(_getProxiedUrl(source));
  }

  static Widget getLogoWidget(
    String? encryptedSource, {
    double size = 50,
    IconData fallbackIcon = Icons.store,
  }) {
    final String decrypted = CryptoUtils.decrypt(encryptedSource ?? '');

    if (decrypted.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey[200],
        child: Icon(fallbackIcon, size: size * 0.6, color: Colors.grey),
      );
    }

    return buildCachedImage(
      decrypted,
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(size / 2),
      fit: BoxFit.cover,
      placeholder: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey[200],
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget buildCachedImage(
    String? source, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    String? thumbnailUrl,
    int? memCacheWidth,
  }) {
    if (source == null || source.isEmpty) {
      return buildErrorWidget(
        height: height,
        width: width,
        borderRadius: borderRadius,
      );
    }

    // Decrypt if the URL was stored encrypted (AES-encrypted strings from sync)
    source = CryptoUtils.decrypt(source);
    if (source.isEmpty) {
      return buildErrorWidget(
        height: height,
        width: width,
        borderRadius: borderRadius,
      );
    }

    // Unescape slashes for legacy URLs (e.g. from older data)
    if (source.contains(r'\/')) {
      source = source.replaceAll(r'\/', '/');
      debugPrint('Legacy URL detected and fixed: $source');
    }

    // Handle base64
    if (source.startsWith('data:image')) {
      try {
        final base64String = source.split(',').last;
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.memory(
            base64Decode(base64String),
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => buildErrorWidget(
              height: height,
              width: width,
              borderRadius: borderRadius,
              error: error,
            ),
          ),
        );
      } catch (e) {
        return buildErrorWidget(
          height: height,
          width: width,
          borderRadius: borderRadius,
          error: e,
        );
      }
    }

    // Apply proxy for external URLs on web
    final String imageUrl = _getProxiedUrl(source);

    return _RetryCachedImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      thumbnailUrl: thumbnailUrl,
      memCacheWidth: memCacheWidth,
    );
  }

  static Widget buildCachedImageProvider(
    ImageProvider imageProvider, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image(
        image: imageProvider,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => buildErrorWidget(
          height: height,
          width: width,
          borderRadius: borderRadius,
          error: error,
        ),
      ),
    );
  }

  static List<String> getDecryptedList(String? encryptedSource) {
    if (encryptedSource == null || encryptedSource.isEmpty) return [];

    var decrypted = CryptoUtils.decrypt(encryptedSource);
    if (decrypted.isEmpty) return [];

    // Unescape slashes for legacy JSON or lists
    if (decrypted.contains(r'\/')) {
      decrypted = decrypted.replaceAll(r'\/', '/');
    }

    if (decrypted.trim().startsWith('[') && decrypted.trim().endsWith(']')) {
      try {
        final List<dynamic> decoded = jsonDecode(decrypted);
        return decoded
            .map((e) => _getProxiedUrl(e.toString().trim()))
            .where((s) => s.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('Error decoding image JSON: $e');
      }
    }

    // Handle double-encoded JSON arrays, e.g. "\"[\\\"https://...\\\"]\""
    if (decrypted.trim().startsWith('"') && decrypted.trim().endsWith('"')) {
      try {
        final normalized = jsonDecode(decrypted).toString();
        if (normalized.trim().startsWith('[') &&
            normalized.trim().endsWith(']')) {
          final List<dynamic> decoded = jsonDecode(normalized);
          return decoded
              .map((e) => _getProxiedUrl(e.toString().trim()))
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (e) {
        debugPrint('Error decoding double-encoded image JSON: $e');
      }
    }

    // Fallback: extract URL-like values from corrupted CSV/JSON payloads.
    final extractedUrls = RegExp(
      r'(https?:\/\/[^,\s"\]]+|data:image\/[^,\s]+,[^,\s"\]]+)',
      caseSensitive: false,
    ).allMatches(decrypted).map((m) => m.group(0)?.trim() ?? '').where((s) {
      return s.isNotEmpty;
    }).toList();
    if (extractedUrls.isNotEmpty) {
      return extractedUrls.map(_getProxiedUrl).toList();
    }

    return decrypted
        .split(',')
        .map((s) => _getProxiedUrl(s.trim()))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static Widget buildPlaceholder({
    double? height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }

  static Widget buildErrorWidget({
    double? height,
    double? width,
    BorderRadius? borderRadius,
    Object? error,
  }) {
    final bool isQuotaError = error?.toString().contains('402') ?? false;
    final bool isNotFoundError = error?.toString().contains('404') ?? false;
    final bool isServerError = error?.toString().contains('5') ?? false;

    // Log detailed error for debugging
    if (error != null) {
      debugPrint(
        'ImageUtils.buildErrorWidget: error=$error, isQuota=$isQuotaError, isNotFound=$isNotFoundError',
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isQuotaError
                  ? Icons.cloud_off_outlined
                  : isNotFoundError
                  ? Icons.image_not_supported_outlined
                  : Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              isQuotaError
                  ? 'Quota dépassé'
                  : isNotFoundError
                  ? 'Image supprimée'
                  : isServerError
                  ? 'Erreur serveur'
                  : 'Image non disponible',
              style: TextStyle(color: Colors.grey[500], fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final String? thumbnailUrl;
  final int? memCacheWidth;

  const _RetryCachedImage({
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.thumbnailUrl,
    this.memCacheWidth,
  });

  @override
  State<_RetryCachedImage> createState() => _RetryCachedImageState();
}

class _RetryCachedImageState extends State<_RetryCachedImage> {
  int _retryCount = 0;

  void _scheduleRetry() {
    if (_retryCount < 2) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _retryCount++);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}_$_retryCount'),
      imageUrl: widget.imageUrl,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 200),
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          image: DecorationImage(image: imageProvider, fit: widget.fit),
        ),
      ),
      placeholder: (context, url) {
        if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: widget.width,
                height: widget.height,
              ),
            ),
          );
        }
        return widget.placeholder ??
            ImageUtils.buildPlaceholder(
              height: widget.height,
              width: widget.width,
              borderRadius: widget.borderRadius,
            );
      },
      errorWidget: (context, url, error) {
        // Log all image loading errors for debugging
        debugPrint(
          'Image load failed: url=$url, error=$error, retry=$_retryCount',
        );

        if (error.toString().contains('402')) {
          debugPrint('⚠️ FIREBASE STORAGE QUOTA EXCEEDED for $url');
          debugPrint(
            '💡 Run fix_firebase_urls.sql to migrate Firebase URLs to server',
          );
        } else if (error.toString().contains('404')) {
          debugPrint('⚠️ IMAGE NOT FOUND (404) for $url');
        }

        if (_retryCount < 2) {
          _scheduleRetry();
          return widget.placeholder ??
              ImageUtils.buildPlaceholder(
                height: widget.height,
                width: widget.width,
                borderRadius: widget.borderRadius,
              );
        }
        return ImageUtils.buildErrorWidget(
          height: widget.height,
          width: widget.width,
          borderRadius: widget.borderRadius,
          error: error,
        );
      },
    );
  }
}
