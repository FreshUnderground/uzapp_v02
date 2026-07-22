import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../models/ya_cope_listing.dart';

class YaCopeRepository {
  final ApiService api;

  YaCopeRepository(this.api);

  static const _base = 'https://uzaapp.com/api/ya_cope.php';
  static const _cacheKey = 'ya_cope_listings_cache_v1';
  static const _cacheAtKey = 'ya_cope_listings_cached_at_v1';
  static const _cacheMaxAge = Duration(hours: 6);

  static Map<String, String> get _noCacheHeaders => const {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

  Future<List<YaCopeListing>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => YaCopeListing.fromJson(e as Map<String, dynamic>))
          .where((l) => !l.isExpired)
          .toList();
    } catch (e) {
      debugPrint('YaCope cache read error: $e');
      return [];
    }
  }

  Future<void> _writeCache(List<YaCopeListing> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
      await prefs.setInt(
        _cacheAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('YaCope cache write error: $e');
    }
  }

  Future<List<YaCopeListing>> _fetchFromNetwork({int limit = 50}) async {
    final uri = Uri.parse(
      '$_base?limit=$limit&_=${DateTime.now().millisecondsSinceEpoch}',
    );
    final response = await http
        .get(uri, headers: _noCacheHeaders)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final list = body['listings'] as List<dynamic>? ?? [];
    return list
        .map((e) => YaCopeListing.fromJson(e as Map<String, dynamic>))
        .where((l) => !l.isExpired)
        .toList();
  }

  /// Stale-while-revalidate: show cache immediately, refresh in background.
  Future<List<YaCopeListing>> fetchListings({int limit = 50}) async {
    final cached = await _readCache();
    final prefs = await SharedPreferences.getInstance();
    final cachedAtMs = prefs.getInt(_cacheAtKey);
    final cachedAt = cachedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(cachedAtMs)
        : null;
    final cacheFresh = cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheMaxAge;

    if (cached.isNotEmpty) {
      if (!cacheFresh) {
        unawaited(() async {
          try {
            final fresh = await _fetchFromNetwork(limit: limit);
            if (fresh.isNotEmpty) await _writeCache(fresh);
          } catch (e) {
            debugPrint('YaCope background refresh: $e');
          }
        }());
      }
      return cached;
    }

    try {
      final items = await _fetchFromNetwork(limit: limit);
      if (items.isNotEmpty) await _writeCache(items);
      return items;
    } catch (e) {
      debugPrint('YaCope fetchListings: $e');
      return cached;
    }
  }

  Future<YaCopeListing?> fetchById(int id) async {
    final uri = Uri.parse(
      '$_base?id=$id&_=${DateTime.now().millisecondsSinceEpoch}',
    );
    final response = await http
        .get(uri, headers: _noCacheHeaders)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) return null;
    final data = body['listing'] as Map<String, dynamic>?;
    if (data == null) return null;
    final listing = YaCopeListing.fromJson(data);
    if (listing.isExpired) return null;
    return listing;
  }

  Future<YaCopeListing> create({
    required String name,
    required String phone,
    String? address,
    required List<Uint8List> imageBytes,
    void Function(String message)? onProgress,
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('Au moins une photo est requise');
    }
    if (imageBytes.length > 3) {
      throw Exception('Maximum 3 photos');
    }

    onProgress?.call('Envoi des photos (0/${imageBytes.length})…');
    var done = 0;
    final urls = await Future.wait(
      List.generate(imageBytes.length, (i) async {
        final prepared = await ImagePrepareUtils.prepareForUpload(
          imageBytes[i],
          prefix: 'yacope_$i',
        );
        final sized = await ImagePrepareUtils.ensureUploadSize(prepared.bytes);
        final url = await api.uploadFileOrThrow(
          sized,
          prepared.fileName,
          folder: 'ya_cope',
        );
        done++;
        onProgress?.call('Envoi des photos ($done/${imageBytes.length})…');
        return url;
      }),
    );

    onProgress?.call('Publication…');
    final uri = Uri.parse(_base);
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.trim(),
            'phone': phone.trim(),
            if (address != null && address.trim().isNotEmpty)
              'address': address.trim(),
            'image_urls': urls,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint('YaCope create failed: ${response.body}');
      throw Exception('Impossible de publier l\'annonce');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error']?.toString() ?? 'Erreur serveur');
    }
    final listing =
        YaCopeListing.fromJson(body['listing'] as Map<String, dynamic>);
    final cached = await _readCache();
    await _writeCache([listing, ...cached.where((l) => l.id != listing.id)]);
    return listing;
  }
}
