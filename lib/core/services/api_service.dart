import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _apiKey =
      'uza_sk_305f0f1ab9c86b0259c876595f74fdf4'; // Must match server API_KEY

  /// Public getter for the API key, used by services that need to
  /// make direct HTTP calls (e.g. SyncService).
  static String get apiKey => _apiKey;

  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Common headers for all API requests to avoid 403 blocks
  Map<String, String> get _commonHeaders => {
    'X-API-Key': _apiKey,
    'User-Agent': 'UzaApp-Flutter/1.0',
    'Accept': 'application/json',
  };

  /// Format DateTime for MySQL (YYYY-MM-DD HH:MM:SS)
  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  // GET /shops
  Future<List<Map<String, dynamic>>> fetchShops({
    DateTime? updatedSince,
  }) async {
    try {
      String url = '$baseUrl/shops.php?api_key=$_apiKey';
      if (updatedSince != null) {
        url +=
            '&updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      final response = await http.get(Uri.parse(url), headers: _commonHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Handle both paginated {data: [...]} and direct array responses
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("API ERROR (fetchShops): $e");
    }
    return [];
  }

  // GET /products
  Future<List<Map<String, dynamic>>> fetchProducts({
    DateTime? updatedSince,
  }) async {
    try {
      String url = '$baseUrl/products.php?api_key=$_apiKey';
      if (updatedSince != null) {
        url +=
            '&updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      debugPrint('API: Fetching products from $url');
      final response = await http.get(Uri.parse(url), headers: _commonHeaders);
      debugPrint('API: Products response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Handle both paginated {data: [...]} and direct array responses
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        debugPrint('API: Fetched ${data.length} products');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('API: Products fetch failed - ${response.body}');
      }
    } catch (e) {
      debugPrint("API ERROR (fetchProducts): $e");
    }
    return [];
  }

  // GET /stories
  Future<List<Map<String, dynamic>>> fetchStories({
    DateTime? updatedSince,
  }) async {
    try {
      String url = '$baseUrl/stories.php?api_key=$_apiKey&include_media=1';
      if (updatedSince != null) {
        url +=
            '&updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      debugPrint('API: Fetching stories from $url');
      final response = await http.get(Uri.parse(url), headers: _commonHeaders);
      debugPrint('API: Stories response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Handle both paginated {data: [...]} and direct array responses
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        debugPrint('API: Fetched ${data.length} stories');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('API: Stories fetch failed - ${response.body}');
      }
    } catch (e) {
      debugPrint("API ERROR (fetchStories): $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchCategories({
    DateTime? updatedSince,
  }) async {
    try {
      String url = '$baseUrl/categories.php?api_key=$_apiKey';
      if (updatedSince != null) {
        url +=
            '&updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      debugPrint('API: Fetching categories from $url');
      final response = await http.get(Uri.parse(url), headers: _commonHeaders);
      debugPrint('API: Categories response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Handle both paginated {data: [...]} and direct array responses
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        final categories = data.cast<Map<String, dynamic>>();
        debugPrint('API: Fetched ${categories.length} categories');
        return categories;
      } else {
        debugPrint('API: Categories fetch failed - ${response.body}');
      }
    } catch (e) {
      debugPrint("API ERROR (fetchCategories): $e");
    }
    return [];
  }

  // Paginated fetch methods
  Future<Map<String, dynamic>> fetchProductsPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/products.php?page=$page&per_page=$perPage',
      );
      final response = await http.get(uri, headers: {'X-API-Key': _apiKey});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("API ERROR (fetchProductsPaginated): $e");
    }
    return {
      'data': <Map<String, dynamic>>[],
      'meta': {
        'page': page,
        'per_page': perPage,
        'total': 0,
        'has_more': false,
      },
    };
  }

  Future<Map<String, dynamic>> fetchShopsPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/shops.php?page=$page&per_page=$perPage');
      final response = await http.get(uri, headers: {'X-API-Key': _apiKey});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("API ERROR (fetchShopsPaginated): $e");
    }
    return {
      'data': <Map<String, dynamic>>[],
      'meta': {
        'page': page,
        'per_page': perPage,
        'total': 0,
        'has_more': false,
      },
    };
  }

  Future<Map<String, dynamic>> fetchStoriesPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/stories.php?page=$page&per_page=$perPage&include_media=1',
      );
      final response = await http.get(uri, headers: {'X-API-Key': _apiKey});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("API ERROR (fetchStoriesPaginated): $e");
    }
    return {
      'data': <Map<String, dynamic>>[],
      'meta': {
        'page': page,
        'per_page': perPage,
        'total': 0,
        'has_more': false,
      },
    };
  }

  Future<Map<String, dynamic>?> fetchUserByPhone(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users.php?phone=${Uri.encodeComponent(phone)}'),
        headers: {'X-API-Key': _apiKey},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['error'] == null) {
          return data as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint("API ERROR (fetchUserByPhone): $e");
    }
    return null;
  }

  // POST /sync or entity-specific endpoints
  /// Pushes a local change to the server.
  ///
  /// For [shops] and [products], routes through `/sync.php` which has proper
  /// validation (owner_id check, one-shop-per-owner, upsert logic). Other
  /// entity types fall back to their specific endpoints.
  ///
  /// Returns `true` only when the server confirms success.
  Future<bool> pushChange(
    String entityType,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('PUSH → $entityType/$action (keys: ${data.keys.toList()})');

      late http.Response response;

      // Route shops and products through sync.php for better server-side
      // validation and upsert logic.
      if (entityType == 'shops' || entityType == 'products') {
        final uri = Uri.parse('$baseUrl/sync.php?api_key=$_apiKey');
        final payload = jsonEncode({
          'entityType': entityType,
          'action': action,
          'data': data,
        });
        debugPrint('PUSH → sync.php  uri=$uri  body_length=${payload.length}');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else {
        final String endpoint = '$entityType.php';
        final uri = Uri.parse('$baseUrl/$endpoint?api_key=$_apiKey');
        final payload = jsonEncode(data);
        debugPrint('PUSH → $endpoint  uri=$uri  body_length=${payload.length}');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      }

      debugPrint(
        'PUSH ← $entityType/$action  status=${response.statusCode}  body=${response.body.length > 500 ? response.body.substring(0, 500) + '…' : response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response body to detect logical failures
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final success = body['success'];
            if (success == false) {
              final errorMsg =
                  body['error'] ?? body['message'] ?? 'Unknown server error';
              debugPrint(
                'PUSH ✗ $entityType/$action logical failure: $errorMsg',
              );
              return false;
            }
            debugPrint(
              'PUSH ✓ $entityType/$action server confirmed (id=${body['id']}, action=${body['action']})',
            );
          }
        } catch (_) {
          // Response body is not JSON; treat as success since HTTP status was OK
          debugPrint('PUSH ✓ $entityType/$action (non-JSON 2xx response)');
        }
        return true;
      } else {
        debugPrint(
          'PUSH ✗ $entityType/$action HTTP ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('PUSH ✗ $entityType/$action exception: $e');
      return false;
    }
  }

  // File upload (Image or Video)
  Future<String?> uploadFile(
    Uint8List bytes,
    String fileName, {
    String folder = 'boutiques/profil',
    Duration? timeout,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload.php'),
      );
      request.headers['X-API-Key'] = _apiKey;
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamedResponse = timeout != null
          ? await request.send().timeout(timeout)
          : await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } on TimeoutException {
      rethrow;
    } catch (e) {
      debugPrint("API ERROR (uploadFile): $e");
    }
    return null;
  }
}
