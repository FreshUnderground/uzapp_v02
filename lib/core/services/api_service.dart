import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  List<String> _phoneVariations(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    final variations = <String>{cleaned, digits};

    if (digits.startsWith('243') && digits.length >= 12) {
      final local = digits.substring(3);
      variations.add(local);
      variations.add('0$local');
      variations.add(digits);
      variations.add('+$digits');
    } else if (digits.startsWith('0') && digits.length >= 10) {
      final local = digits.substring(1);
      variations.add(local);
      variations.add('0$local');
      variations.add('243$local');
      variations.add('+243$local');
    } else if (digits.length == 9) {
      variations.add(digits);
      variations.add('0$digits');
      variations.add('243$digits');
      variations.add('+243$digits');
    }

    variations.removeWhere((value) => value.isEmpty);
    return variations.toList();
  }

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

  /// Lightweight lookup: returns the shop owned by [phone], if any.
  Future<Map<String, dynamic>?> fetchShopByOwner(String phone) async {
    for (final phoneVariant in _phoneVariations(phone)) {
      try {
        final uri = Uri.parse(
          '$baseUrl/shops.php?owner_id=${Uri.encodeComponent(phoneVariant)}',
        );
        final response = await http
            .get(uri, headers: _commonHeaders)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['id'] != null) {
          return decoded;
        }
      } catch (e) {
        debugPrint('API ERROR (fetchShopByOwner: $phoneVariant): $e');
      }
    }
    return null;
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

  Future<List<Map<String, dynamic>>> fetchProductUpdates({
    DateTime? updatedSince,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
      };
      if (updatedSince != null) {
        params['updated_since'] = _formatDateForApi(updatedSince);
      }
      final uri = Uri.parse('$baseUrl/product_updates.php')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: _commonHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('API ERROR (fetchProductUpdates): $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> postProductUpdate(
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/product_updates.php');
      final response = await http.post(
        uri,
        headers: {..._commonHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          return decoded as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('API ERROR (postProductUpdate): $e');
    }
    return null;
  }

  // GET /orders
  Future<List<Map<String, dynamic>>> fetchOrders({
    String? buyerPhone,
    int? shopId,
    DateTime? updatedSince,
  }) async {
    try {
      final params = <String, String>{};
      if (buyerPhone != null && buyerPhone.isNotEmpty) {
        params['buyer_phone'] = buyerPhone;
      }
      if (shopId != null) {
        params['shop_id'] = shopId.toString();
      }
      if (updatedSince != null) {
        params['updated_since'] = _formatDateForApi(updatedSince);
      }
      final uri = Uri.parse('$baseUrl/orders.php').replace(queryParameters: params);
      final response = await http.get(uri, headers: _commonHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('API ERROR (fetchOrders): $e');
    }
    return [];
  }

  // GET /deliveries
  Future<List<Map<String, dynamic>>> fetchDeliveries({
    String? buyerPhone,
    int? shopId,
    DateTime? updatedSince,
  }) async {
    try {
      final params = <String, String>{};
      if (buyerPhone != null && buyerPhone.isNotEmpty) {
        params['buyer_phone'] = buyerPhone;
      }
      if (shopId != null) {
        params['shop_id'] = shopId.toString();
      }
      if (updatedSince != null) {
        params['updated_since'] = _formatDateForApi(updatedSince);
      }
      final uri =
          Uri.parse('$baseUrl/deliveries.php').replace(queryParameters: params);
      final response = await http.get(uri, headers: _commonHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map
            ? (decoded['data'] ?? [])
            : decoded;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('API ERROR (fetchDeliveries): $e');
    }
    return [];
  }

  // GET /stories — returns null on HTTP/network failure (distinct from empty list).
  Future<List<Map<String, dynamic>>?> fetchStories({
    DateTime? updatedSince,
  }) async {
    try {
      String url = '$baseUrl/stories.php?include_media=1';
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
    return null;
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
      debugPrint('API: Fetching categories from $url');
      final response = await http.get(Uri.parse(url), headers: _commonHeaders);
      debugPrint('API: Categories response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('API: Categories decoded type: ${decoded.runtimeType}');

        // Handle both paginated {data: [...]} and direct array responses
        List<dynamic> data;
        if (decoded is List) {
          // Direct array (when updated_since is provided)
          data = decoded;
          debugPrint('API: Categories response is direct array');
        } else if (decoded is Map) {
          // Paginated format
          data = decoded['data'] ?? [];
          debugPrint(
            'API: Categories response is map with data key, length: ${data.length}',
          );
          if (data.isEmpty) {
            debugPrint(
              'API: WARNING - decoded map keys: ${decoded.keys.toList()}',
            );
            debugPrint(
              'API: WARNING - response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
            );
          }
        } else {
          debugPrint(
            'API: ERROR - Unexpected response type: ${decoded.runtimeType}',
          );
          data = [];
        }

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

  /// Find an existing user-contributed category or create one under [parentServerId].
  Future<Map<String, dynamic>?> findOrCreateCategory({
    required String name,
    required int parentServerId,
    String? remoteId,
    int level = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/categories.php');
      final payload = jsonEncode({
        'action': 'find_or_create',
        'name': name.trim(),
        'parent_id': parentServerId,
        'level': level,
        if (remoteId != null) 'remote_id': remoteId,
      });
      debugPrint('API: findOrCreateCategory parent=$parentServerId name=$name');
      final response = await http.post(
        uri,
        headers: {..._commonHeaders, 'Content-Type': 'application/json'},
        body: payload,
      );
      debugPrint(
        'API: findOrCreateCategory status=${response.statusCode} body=${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['success'] == true) {
          final category = body['category'];
          if (category is Map<String, dynamic>) {
            return {
              ...category,
              'action': body['action'],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('API ERROR (findOrCreateCategory): $e');
    }
    return null;
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
      final response = await http.get(uri, headers: _commonHeaders);
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
      final uri = Uri.parse(
        '$baseUrl/shops.php?page=$page&per_page=$perPage',
      );
      final response = await http.get(uri, headers: _commonHeaders);
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
    for (final phoneVariant in _phoneVariations(phone)) {
      try {
        final response = await http.get(
          Uri.parse(
            '$baseUrl/users.php?phone=${Uri.encodeComponent(phoneVariant)}',
          ),
          headers: {'X-API-Key': _apiKey},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data['error'] == null) {
            return data as Map<String, dynamic>;
          }
        }
      } catch (e) {
        debugPrint("API ERROR (fetchUserByPhone: $phoneVariant): $e");
      }
    }
    return null;
  }

  /// Vérifie que le compte [users] et la boutique [shops] existent sur le serveur.
  Future<({bool userExists, bool shopExists})> verifyUserAndShopOnServer(
    String phone,
  ) async {
    final user = await fetchUserByPhone(phone);
    final userExists = user != null && user['error'] == null;

    final shop = await fetchShopByOwner(phone);
    final shopExists = shop != null && shop['id'] != null;

    debugPrint(
      'VERIFY server registration phone=$phone user=$userExists shop=$shopExists',
    );
    return (userExists: userExists, shopExists: shopExists);
  }

  /// Login with phone number and password hash
  Future<Map<String, dynamic>?> loginWithPassword({
    required String phone,
    required String passwordHash,
  }) async {
    Map<String, dynamic>? lastNotFound;

    for (final phoneVariant in _phoneVariations(phone)) {
      try {
        final uri = Uri.parse('$baseUrl/login.php');
        final response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phoneVariant,
            'password_hash': passwordHash,
          }),
        );

        if (kDebugMode) {
          debugPrint('Login response status: ${response.statusCode}');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data['success'] == true) {
            return data;
          }
        } else if (response.statusCode == 401) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 404) {
          lastNotFound = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint("API ERROR (loginWithPassword: $phoneVariant): $e");
      }
    }

    return lastNotFound;
  }

  // POST /sync or entity-specific endpoints
  /// Pushes a local change to the server.
  ///
  /// For [shops] and [products], routes through `/sync.php` which has proper
  /// validation (owner_id check, one-shop-per-owner, upsert logic). Other
  /// entity types fall back to their specific endpoints.
  ///
  /// Returns `true` only when the server confirms success.
  /// Push changes to server and return response data for ID mapping
  Future<Map<String, dynamic>?> pushChange(
    String entityType,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('PUSH → $entityType/$action (keys: ${data.keys.toList()})');
      }

      late http.Response response;

      // Route shops and products through sync.php for better server-side
      // validation and upsert logic.
      // Route product_likes and shop_follows through stats.php.
      if (entityType == 'shops' || entityType == 'products') {
        final uri = Uri.parse('$baseUrl/sync.php');
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
      } else if (entityType == 'product_likes') {
        // Route product likes to stats.php
        final uri = Uri.parse('$baseUrl/stats.php');
        final actionMap = action == 'CREATE' ? 'like' : 'unlike';
        final payload = jsonEncode({'action': actionMap, ...data});
        debugPrint('PUSH → stats.php (like)  uri=$uri');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else if (entityType == 'shop_follows') {
        // Route shop follows to stats.php
        final uri = Uri.parse('$baseUrl/stats.php');
        final actionMap = action == 'CREATE' ? 'follow' : 'unfollow';
        final payload = jsonEncode({'action': actionMap, ...data});
        debugPrint('PUSH → stats.php (follow)  uri=$uri');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else if (entityType == 'stories' && action == 'DELETE') {
        final uri = Uri.parse('$baseUrl/stories.php');
        final payload = jsonEncode(data);
        debugPrint('PUSH → stories.php DELETE  uri=$uri');
        response = await http.delete(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else if (entityType == 'orders') {
        final uri = Uri.parse('$baseUrl/orders.php');
        final payload = jsonEncode({'action': action, 'data': data});
        debugPrint('PUSH → orders.php  uri=$uri');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else if (entityType == 'deliveries') {
        final uri = Uri.parse('$baseUrl/deliveries.php');
        final payload = jsonEncode({'action': action, 'data': data});
        debugPrint('PUSH → deliveries.php  uri=$uri');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      } else {
        final String endpoint = '$entityType.php';
        final uri = Uri.parse('$baseUrl/$endpoint');
        final payload = jsonEncode(data);
        debugPrint('PUSH → $endpoint  uri=$uri  body_length=${payload.length}');
        response = await http.post(
          uri,
          headers: {..._commonHeaders, 'Content-Type': 'application/json'},
          body: payload,
        );
      }

      debugPrint(
        'PUSH ← $entityType/$action  status=${response.statusCode}  body=${response.body.length > 500 ? '${response.body.substring(0, 500)}…' : response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response body to detect logical failures and extract server ID
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
              debugPrint('PUSH ✗ FULL RESPONSE: ${response.body}');
              return null;
            }
            debugPrint(
              'PUSH ✓ $entityType/$action server confirmed (id=${body['id']}, action=${body['action']})',
            );
            // Return full response data for ID mapping
            return body;
          }
        } catch (e) {
          // Response body is not JSON; treat as success since HTTP status was OK
          debugPrint('PUSH ✓ $entityType/$action (non-JSON 2xx response)');
          debugPrint('PUSH WARNING: Could not parse JSON: $e');
          debugPrint('PUSH RAW BODY: ${response.body}');
          return {'success': true};
        }
      } else {
        debugPrint(
          'PUSH ✗ $entityType/$action HTTP ${response.statusCode}: ${response.body}',
        );
        debugPrint(
          'PUSH ✗ REQUEST DATA: entityType=$entityType action=$action data=${jsonEncode(data)}',
        );
      }
    } catch (e) {
      debugPrint('PUSH ✗ $entityType/$action exception: $e');
    }
    return null;
  }

  /// Report a product for moderation.
  Future<bool> reportProduct({
    required int productId,
    required String reason,
    String? details,
    required String reporterPhone,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/reports.php');
      final response = await http.post(
        uri,
        headers: {..._commonHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'reason': reason,
          'details': details,
          'reporter_phone': reporterPhone,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body is Map && (body['success'] == true || body['id'] != null);
      }
      debugPrint('reportProduct HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('reportProduct error: $e');
    }
    return false;
  }

  static MediaType? _mediaTypeForFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
      case 'hif':
        return MediaType('image', 'heif');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'webm':
        return MediaType('video', 'webm');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      default:
        return null;
    }
  }

  String? _parseUploadError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        return data['error']?.toString();
      }
    } catch (_) {}
    return null;
  }

  // File upload (Image or Video)
  Future<String?> uploadFile(
    Uint8List bytes,
    String fileName, {
    String folder = 'boutiques/profil',
    Duration? timeout,
  }) async {
    final effectiveTimeout =
        timeout ?? const Duration(seconds: 90);
    try {
      final uri = Uri.parse('$baseUrl/upload.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-Key'] = _apiKey;
      request.fields['folder'] = folder;
      request.fields['skip_thumbnail'] = '1';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _mediaTypeForFileName(fileName),
        ),
      );

      final streamedResponse =
          await request.send().timeout(effectiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }

      final serverError = _parseUploadError(response.body);
      debugPrint(
        'API ERROR (uploadFile): HTTP ${response.statusCode} '
        '${serverError ?? response.body}',
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      debugPrint("API ERROR (uploadFile): $e");
    }
    return null;
  }

  /// Upload with a human-readable error when the server rejects the file.
  Future<String> uploadFileOrThrow(
    Uint8List bytes,
    String fileName, {
    String folder = 'boutiques/profil',
    Duration? timeout,
  }) async {
    final effectiveTimeout =
        timeout ?? const Duration(seconds: 90);
    try {
      final uri = Uri.parse('$baseUrl/upload.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-Key'] = _apiKey;
      request.fields['folder'] = folder;
      request.fields['skip_thumbnail'] = '1';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _mediaTypeForFileName(fileName),
        ),
      );

      final streamedResponse =
          await request.send().timeout(effectiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
        throw Exception('Réponse serveur invalide');
      }

      final serverError = _parseUploadError(response.body);
      if (response.statusCode == 401) {
        throw Exception('Non autorisé. Vérifiez votre connexion.');
      }
      throw Exception(
        serverError ??
            'Échec de l\'upload (HTTP ${response.statusCode})',
      );
    } on TimeoutException {
      rethrow;
    }
  }

  /// Record a platform open / visit for admin analytics.
  Future<bool> trackPlatformVisit({
    required String eventType,
    required String platform,
    String? visitorId,
    String? userPhone,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/platform_visits.php');
      final payload = jsonEncode({
        'event_type': eventType,
        'platform': platform,
        if (visitorId != null) 'visitor_id': visitorId,
        if (userPhone != null && userPhone.isNotEmpty) 'user_phone': userPhone,
      });
      final response = await http.post(
        uri,
        headers: {..._commonHeaders, 'Content-Type': 'application/json'},
        body: payload,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map && data['success'] == true;
      }
    } catch (e) {
      debugPrint('API ERROR (trackPlatformVisit): $e');
    }
    return false;
  }

  Map<String, String> _adminHeaders(String adminPhone) => {
        ..._commonHeaders,
        'X-Admin-Phone': adminPhone,
      };

  /// Platform statistics for admin dashboard (requires admin role on server).
  Future<Map<String, dynamic>?> fetchAdminStats({
    required String adminPhone,
    String preset = '30d',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/admin_stats.php').replace(
        queryParameters: {
          'admin_phone': adminPhone,
          'preset': preset,
        },
      );
      final response = await http.get(uri, headers: _adminHeaders(adminPhone));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          return Map<String, dynamic>.from(decoded['data'] as Map);
        }
        debugPrint(
          'API ERROR (fetchAdminStats): success=false ${response.body}',
        );
      } else {
        debugPrint(
          'API ERROR (fetchAdminStats): HTTP ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('API ERROR (fetchAdminStats): $e');
    }
    return null;
  }

  /// Recent product reports for admin moderation.
  Future<List<Map<String, dynamic>>> fetchAdminReports({
    required String adminPhone,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/reports.php').replace(
        queryParameters: {
          'admin_phone': adminPhone,
          'list': '1',
          'limit': '$limit',
        },
      );
      final response = await http.get(uri, headers: _adminHeaders(adminPhone));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          final reports = decoded['reports'];
          if (reports is List) {
            return reports
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }
      } else {
        debugPrint(
          'API ERROR (fetchAdminReports): HTTP ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('API ERROR (fetchAdminReports): $e');
    }
    return [];
  }

  /// Aggregated shop stats from server (cross-device).
  Future<Map<String, int>?> fetchShopStats(int remoteShopId) async {
    try {
      final uri = Uri.parse('$baseUrl/stats.php').replace(
        queryParameters: {
          'shop_id': remoteShopId.toString(),
        },
      );
      final response = await http
          .get(uri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) return null;
      final stats = decoded['stats'];
      if (stats is! Map) return null;

      int asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse('$v') ?? 0;
      }

      return {
        'followers': asInt(stats['followers']),
        'likes': asInt(stats['likes']),
        'whatsapp_contacts': asInt(stats['whatsapp_contacts']),
        'call_contacts': asInt(stats['call_contacts']),
        'sms_contacts': asInt(stats['sms_contacts']),
        'total_contacts': asInt(stats['total_contacts']),
        'unique_clients': asInt(stats['unique_clients']),
        'product_views': asInt(stats['product_views']),
        'product_shares': asInt(stats['product_shares']),
        'shop_views': asInt(stats['shop_views']),
        'shop_shares': asInt(stats['shop_shares']),
      };
    } catch (e) {
      debugPrint('API ERROR (fetchShopStats): $e');
    }
    return null;
  }

  /// Record a buyer contact on the server for cross-device seller stats.
  Future<bool> trackContact({
    required int shopId,
    required String userPhone,
    required String contactType,
    int? productId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/stats.php');
      final payload = jsonEncode({
        'action': 'track_contact',
        'shop_id': shopId,
        'user_phone': userPhone,
        'contact_type': contactType,
        if (productId != null) 'product_id': productId,
      });
      final response = await http
          .post(
            uri,
            headers: {..._commonHeaders, 'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map && data['success'] == true;
      }
    } catch (e) {
      debugPrint('API ERROR (trackContact): $e');
    }
    return false;
  }

  /// Record a shop-level view or share (catalog, story, QR, status WA…).
  Future<bool> trackShopInteraction({
    required int shopId,
    required String interactionType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/stats.php');
      final payload = jsonEncode({
        'action': 'track_shop_interaction',
        'shop_id': shopId,
        'interaction_type': interactionType,
      });
      final response = await http
          .post(
            uri,
            headers: {..._commonHeaders, 'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map && data['success'] == true;
      }
    } catch (e) {
      debugPrint('API ERROR (trackShopInteraction): $e');
    }
    return false;
  }
}
