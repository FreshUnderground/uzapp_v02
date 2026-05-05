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
      String url = '$baseUrl/shops.php';
      if (updatedSince != null) {
        url +=
            '?updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-API-Key': _apiKey},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
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
      String url = '$baseUrl/products.php';
      if (updatedSince != null) {
        url +=
            '?updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-API-Key': _apiKey},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
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
      String url = '$baseUrl/stories.php';
      if (updatedSince != null) {
        url +=
            '?updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-API-Key': _apiKey},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
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
      String url = '$baseUrl/categories.php';
      if (updatedSince != null) {
        url +=
            '?updated_since=${Uri.encodeComponent(_formatDateForApi(updatedSince))}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-API-Key': _apiKey},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
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
        '$baseUrl/stories.php?page=$page&per_page=$perPage',
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
      late http.Response response;

      // Route shops and products through sync.php for better server-side
      // validation and upsert logic.
      if (entityType == 'shops' || entityType == 'products') {
        response = await http.post(
          Uri.parse('$baseUrl/sync.php'),
          headers: {'Content-Type': 'application/json', 'X-API-Key': _apiKey},
          body: jsonEncode({
            'entityType': entityType,
            'action': action,
            'data': data,
          }),
        );
      } else {
        final String endpoint = '$entityType.php';
        response = await http.post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {'Content-Type': 'application/json', 'X-API-Key': _apiKey},
          body: jsonEncode(data),
        );
      }

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
                'API LOGICAL ERROR (pushChange $entityType): $errorMsg',
              );
              return false;
            }
          }
        } catch (_) {
          // Response body is not JSON; treat as success since HTTP status was OK
        }
        return true;
      } else {
        debugPrint(
          'API ERROR (pushChange $entityType): ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('API ERROR (pushChange $entityType): $e');
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
