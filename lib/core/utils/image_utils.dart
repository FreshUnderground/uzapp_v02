import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'crypto_utils.dart';

class UzaImageCache {
  static final CacheManager instance = CacheManager(
    Config(
      'uza_image_cache_v1',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 2500,
    ),
  );
}

class ImageUtils {
  // Proxy URL for external images (to avoid CORS on web)
  static const String _proxyBaseUrl = 'https://uzaapp.com/api/proxy.php?url=';

  /// URLs that failed to load after retries — used to deprioritize products.
  static final Set<String> _failedImageUrls = <String>{};

  static void markImageLoadFailed(String? url) {
    if (url == null || url.isEmpty) return;
    _failedImageUrls.add(url);
  }

  static void markImageLoadSuccess(String? url) {
    if (url == null || url.isEmpty) return;
    _failedImageUrls.remove(url);
  }

  /// True when the product has at least one resolvable, non-failed image URL.
  static bool hasDisplayableImage(String? imageUrls) {
    if (isEmptyMediaValue(imageUrls)) return false;
    final urls = getDecryptedList(imageUrls);
    if (urls.isEmpty) return false;
    return urls.any((url) => !_failedImageUrls.contains(url));
  }

  /// Prefer banner/cover, then logo for shop cards and headers.
  static String? getShopCoverSource(String? bannerUrl, String? logoUrl) {
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      if (resolveImageUrl(bannerUrl) != null) return bannerUrl;
    }
    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (resolveImageUrl(logoUrl) != null) return logoUrl;
    }
    return null;
  }

  /// First product image widget from encrypted/plain image_urls field.
  static Widget buildCachedFirstProductImage(
    String? imageUrls, {
    BoxFit fit = BoxFit.cover,
    double? height,
    double? width,
    BorderRadius? borderRadius,
    String? thumbnailUrl,
    int? memCacheWidth,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final resolved = getDecryptedList(imageUrls);
    if (resolved.isEmpty) {
      return placeholder ?? buildPlaceholder(height: height, width: width);
    }
    return buildCachedImage(
      resolved.first,
      fit: fit,
      height: height,
      width: width,
      borderRadius: borderRadius,
      thumbnailUrl: thumbnailUrl,
      memCacheWidth: memCacheWidth,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fromResolvedUrl: true,
    );
  }

  /// Warm disk cache after sync so images survive app restarts.
  /// Remove cached files for encrypted/plain media URLs (after delete).
  static Future<void> evictCachedSources(Iterable<String?> sources) async {
    final seen = <String>{};
    for (final source in sources) {
      final resolved = resolveImageUrl(source);
      if (resolved == null || resolved.isEmpty || !seen.add(resolved)) {
        continue;
      }
      try {
        await UzaImageCache.instance.removeFile(resolved);
      } catch (e) {
        debugPrint('Image cache evict failed for $resolved: $e');
      }
    }
  }

  /// Returns true when the image is already on disk (mobile/desktop) or in cache.
  static Future<bool> isUrlCached(String url) async {
    if (url.startsWith('data:image')) return true;
    try {
      final file = await UzaImageCache.instance.getFileFromCache(url);
      return file != null;
    } catch (_) {
      return false;
    }
  }

  /// Prefetch images in parallel, skipping already-cached files.
  static Future<void> prefetchUrls(
    Iterable<String?> sources, {
    int? maxUrls,
    int concurrency = 6,
    bool skipCached = true,
  }) async {
    final urls = <String>[];
    final seen = <String>{};
    for (final source in sources) {
      final resolved = resolveImageUrl(source);
      if (resolved == null || resolved.isEmpty) continue;
      if (resolved.startsWith('data:image')) continue;
      if (!seen.add(resolved)) continue;
      urls.add(resolved);
      if (maxUrls != null && urls.length >= maxUrls) break;
    }

    if (urls.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (true) {
        final current = index++;
        if (current >= urls.length) break;
        final url = urls[current];
        try {
          if (skipCached && await isUrlCached(url)) continue;
          await UzaImageCache.instance.downloadFile(url);
        } catch (e) {
          debugPrint('Image prefetch failed for $url: $e');
        }
      }
    }

    final workerCount = concurrency.clamp(1, 8);
    await Future.wait(List.generate(workerCount, (_) => worker()));
  }

  static String _stripWrappingQuotes(String value) {
    var v = value.trim();
    while ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  static bool isEmptyMediaValue(String? value) {
    if (value == null) return true;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == '[]' || trimmed == 'null';
  }

  static String? _normalizeDecryptedUrl(String decrypted) {
    var value = _stripWrappingQuotes(decrypted);
    if (value.isEmpty) return null;

    if (value.contains(r'\/')) {
      value = value.replaceAll(r'\/', '/');
    }

    if (value.startsWith('data:image')) {
      return value;
    }

    if (value.startsWith('/uploads/')) {
      value = 'https://uzaapp.com$value';
    } else if (value.startsWith('uploads/')) {
      value = 'https://uzaapp.com/$value';
    } else if (!value.startsWith('http://') && !value.startsWith('https://')) {
      if (RegExp(r'uzaapp\.com/', caseSensitive: false).hasMatch(value)) {
        value = 'https://$value';
      } else {
        return null;
      }
    }

    if (value.startsWith('http://') && value.contains('uzaapp.com')) {
      value = value.replaceFirst('http://', 'https://');
    }

    return _getProxiedUrl(value);
  }

  /// Normalize encrypted/plain/legacy image sources into a loadable URL.
  static String? resolveImageUrl(String? source) {
    if (source == null || source.isEmpty) return null;

    final trimmed = source.trim();
    if (trimmed.contains('proxy.php')) {
      return trimmed;
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image')) {
      return _normalizeDecryptedUrl(trimmed);
    }

    var decrypted = CryptoUtils.decrypt(trimmed).trim();
    if (decrypted.isEmpty) return null;

    // Some records store a JSON array instead of a single URL.
    if (decrypted.startsWith('[') && decrypted.contains('http')) {
      final urls = getDecryptedList(source);
      if (urls.isEmpty) return null;
      return urls.first;
    }

    if (decrypted.contains(',') && decrypted.contains('http')) {
      final urls = decrypted
          .split(',')
          .map((s) => _normalizeDecryptedUrl(s.trim()))
          .whereType<String>()
          .toList();
      return urls.isEmpty ? null : urls.first;
    }

    return _normalizeDecryptedUrl(decrypted);
  }

  /// Route external/legacy storage URLs through the server proxy when needed.
  static String _getProxiedUrl(String url) {
    if (url.isEmpty) return url;

    if (url.contains('proxy.php')) return url;

    if (url.contains('uzaapp.com') &&
        !url.contains('firebasestorage.googleapis.com')) {
      return url;
    }

    if (url.contains('firebasestorage.googleapis.com') ||
        url.contains('storage.googleapis.com')) {
      return '$_proxyBaseUrl${Uri.encodeComponent(url)}';
    }
    return url;
  }

  static ImageProvider? getImageProvider(String? encryptedSource) {
    final source = resolveImageUrl(encryptedSource);
    if (source == null || source.isEmpty) return null;

    if (source.startsWith('data:image')) {
      try {
        final base64String = source.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }

    return NetworkImage(source);
  }

  /// Download raw image bytes for offline composition (status images, etc.).
  static Future<Uint8List?> downloadImageBytes(String? source) async {
    final resolved = resolveImageUrl(source);
    if (resolved == null || resolved.isEmpty) return null;

    if (resolved.startsWith('data:image')) {
      try {
        return base64Decode(resolved.split(',').last);
      } catch (e) {
        debugPrint('ImageUtils: base64 decode failed: $e');
        return null;
      }
    }

    try {
      final file = await UzaImageCache.instance.getSingleFile(resolved);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('ImageUtils: cache miss for $resolved: $e');
    }

    try {
      final response = await http.get(Uri.parse(resolved));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('ImageUtils: HTTP download failed: $e');
    }

    return null;
  }

  static Widget getLogoWidget(
    String? encryptedSource, {
    double size = 50,
    IconData fallbackIcon = Icons.store,
  }) {
    final resolved = resolveImageUrl(encryptedSource);

    if (resolved == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey[200],
        child: Icon(fallbackIcon, size: size * 0.6, color: Colors.grey),
      );
    }

    return buildCachedImage(
      encryptedSource,
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
    Widget? errorWidget,
    String? thumbnailUrl,
    int? memCacheWidth,
    bool fromResolvedUrl = false,
    VoidCallback? onImageLoaded,
  }) {
    final resolved = fromResolvedUrl ? source : resolveImageUrl(source);
    if (resolved == null) {
      return errorWidget ??
          buildErrorWidget(
            height: height,
            width: width,
            borderRadius: borderRadius,
          );
    }

    // Handle base64
    if (resolved.startsWith('data:image')) {
      try {
        final base64String = resolved.split(',').last;
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.memory(
            base64Decode(base64String),
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ??
                buildErrorWidget(
                  height: height,
                  width: width,
                  borderRadius: borderRadius,
                  error: error,
                ),
          ),
        );
      } catch (e) {
        return errorWidget ??
            buildErrorWidget(
              height: height,
              width: width,
              borderRadius: borderRadius,
              error: e,
            );
      }
    }

    return _RetryCachedImage(
      imageUrl: resolved,
      height: height,
      width: width,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      thumbnailUrl: thumbnailUrl,
      memCacheWidth: memCacheWidth,
      onImageLoaded: onImageLoaded,
    );
  }

  /// Full-screen media: blurred backdrop + [BoxFit.contain] so tall/wide
  /// images stay fully visible (Découvrir, stories, arrivages).
  static Widget buildFullscreenContainedImage(
    String? source, {
    Key? key,
    VoidCallback? onImageLoaded,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final resolved = resolveImageUrl(source);
    if (resolved == null) {
      return errorWidget ??
          Container(
            key: key,
            color: Colors.black,
            child: buildErrorWidget(),
          );
    }

    final loading = placeholder ??
        const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
    final error = errorWidget ??
        Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        );

    return Container(
      key: key,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          buildCachedImage(
            source,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          buildCachedImage(
            source,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            onImageLoaded: onImageLoaded,
            placeholder: loading,
            errorWidget: error,
          ),
        ],
      ),
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
    if (isEmptyMediaValue(encryptedSource)) return [];

    final trimmed = encryptedSource!.trim();

    // Single plain/encrypted URL (not a JSON array).
    if (!trimmed.startsWith('[')) {
      final decryptedPreview = CryptoUtils.decrypt(trimmed).trim();
      final looksLikeCsv =
          decryptedPreview.contains(',') && decryptedPreview.contains('http');
      if (!looksLikeCsv) {
        final single = resolveImageUrl(trimmed);
        if (single != null) return [single];
      }
    }

    var decrypted = CryptoUtils.decrypt(trimmed);
    if (decrypted.isEmpty) return [];

    // Unescape slashes for legacy JSON or lists
    if (decrypted.contains(r'\/')) {
      decrypted = decrypted.replaceAll(r'\/', '/');
    }

    if (decrypted.trim().startsWith('[') && decrypted.trim().endsWith(']')) {
      try {
        final List<dynamic> decoded = jsonDecode(decrypted);
        return decoded
            .map((e) => _normalizeDecryptedUrl(e.toString().trim()))
            .whereType<String>()
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
              .map((e) => _normalizeDecryptedUrl(e.toString().trim()))
              .whereType<String>()
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
      return extractedUrls
          .map((url) => _normalizeDecryptedUrl(url))
          .whereType<String>()
          .toList();
    }

    return decrypted
        .split(',')
        .map((s) => _normalizeDecryptedUrl(s.trim()))
        .whereType<String>()
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
  final Widget? errorWidget;
  final String? thumbnailUrl;
  final int? memCacheWidth;
  final VoidCallback? onImageLoaded;

  const _RetryCachedImage({
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.thumbnailUrl,
    this.memCacheWidth,
    this.onImageLoaded,
  });

  @override
  State<_RetryCachedImage> createState() => _RetryCachedImageState();
}

class _RetryCachedImageState extends State<_RetryCachedImage> {
  int _retryCount = 0;

  void _scheduleRetry() {
    if (_retryCount < 1) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _retryCount++);
        }
      });
    }
  }

  void _notifyLoaded() {
    ImageUtils.markImageLoadSuccess(widget.imageUrl);
    if (widget.onImageLoaded == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onImageLoaded?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final diskCacheWidth = widget.memCacheWidth;
    final image = CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}_$_retryCount'),
      imageUrl: widget.imageUrl,
      cacheManager: UzaImageCache.instance,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      maxWidthDiskCache: diskCacheWidth,
      maxHeightDiskCache: diskCacheWidth != null ? diskCacheWidth * 2 : 480,
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      httpHeaders: const {'Accept': 'image/*'},
      imageBuilder: widget.onImageLoaded == null
          ? null
          : (context, imageProvider) {
              _notifyLoaded();
              return Image(
                image: imageProvider,
                height: widget.height,
                width: widget.width,
                fit: widget.fit,
              );
            },
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
                cacheManager: UzaImageCache.instance,
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

        if (_retryCount < 1) {
          _scheduleRetry();
          return widget.placeholder ??
              ImageUtils.buildPlaceholder(
                height: widget.height,
                width: widget.width,
                borderRadius: widget.borderRadius,
              );
        }
        ImageUtils.markImageLoadFailed(url);
        return widget.errorWidget ??
            ImageUtils.buildErrorWidget(
              height: widget.height,
              width: widget.width,
              borderRadius: widget.borderRadius,
              error: error,
            );
      },
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}
