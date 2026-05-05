import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Caches ETags for API responses to avoid re-downloading unchanged data.
///
/// On low-end devices with expensive/slow connectivity (DRC market), this
/// reduces bandwidth by sending `If-None-Match` headers and skipping
/// response parsing when the server responds with 304 Not Modified.
class ETagCacheService {
  static const String _prefix = 'etag_';

  // Prevent instantiation — all methods are static for simplicity.
  ETagCacheService._();

  // ---------------------------------------------------------------------------
  // Read / Write ETags
  // ---------------------------------------------------------------------------

  /// Get the stored ETag for [url], or `null` if none is cached.
  static Future<String?> getETag(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_prefix$url');
    } catch (e) {
      debugPrint('ETagCacheService: failed to read ETag for $url – $e');
      return null;
    }
  }

  /// Store [etag] for [url], overwriting any previous value.
  static Future<void> setETag(String url, String etag) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$url', etag);
    } catch (e) {
      debugPrint('ETagCacheService: failed to write ETag for $url – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Conditional request helpers
  // ---------------------------------------------------------------------------

  /// Compare the server's ETag header against the cached one.
  ///
  /// Returns `true` if the data has been modified (or there is no cached
  /// ETag), meaning the response body should be parsed and stored.
  /// Returns `false` if the data is unchanged (304-style behaviour).
  static Future<bool> isModified(
    String url,
    Map<String, String> responseHeaders,
  ) async {
    final serverEtag = responseHeaders['etag'];
    if (serverEtag == null) return true;

    final cachedEtag = await getETag(url);
    if (cachedEtag == serverEtag) return false;

    // New version — update the cache
    await setETag(url, serverEtag);
    return true;
  }

  /// Build request headers that include `If-None-Match` when a cached
  /// ETag exists, allowing the server to respond with 304 Not Modified.
  static Future<Map<String, String>> getConditionalHeaders(String url) async {
    final etag = await getETag(url);
    if (etag != null) {
      return {'If-None-Match': etag};
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // Cache management
  // ---------------------------------------------------------------------------

  /// Remove the ETag for a single [url].
  static Future<void> removeETag(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$url');
    } catch (e) {
      debugPrint('ETagCacheService: failed to remove ETag for $url – $e');
    }
  }

  /// Clear all cached ETags.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('ETagCacheService: cleared ${keys.length} cached ETags');
    } catch (e) {
      debugPrint('ETagCacheService: failed to clear ETags – $e');
    }
  }

  /// Return the number of cached ETags (useful for diagnostics / UI).
  static Future<int> cachedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((k) => k.startsWith(_prefix)).length;
    } catch (e) {
      debugPrint('ETagCacheService: failed to count ETags – $e');
      return 0;
    }
  }
}
