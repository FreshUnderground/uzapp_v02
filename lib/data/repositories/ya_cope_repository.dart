import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/services/api_service.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../models/ya_cope_listing.dart';

class YaCopeRepository {
  final ApiService api;

  YaCopeRepository(this.api);

  static const _base = 'https://uzaapp.com/api/ya_cope.php';

  Future<List<YaCopeListing>> fetchListings({int limit = 50}) async {
    final uri = Uri.parse('$_base?limit=$limit');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final list = body['listings'] as List<dynamic>? ?? [];
    return list
        .map((e) => YaCopeListing.fromJson(e as Map<String, dynamic>))
        .where((l) => !l.isExpired)
        .toList();
  }

  Future<YaCopeListing?> fetchById(int id) async {
    final uri = Uri.parse('$_base?id=$id');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
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
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('Au moins une photo est requise');
    }
    if (imageBytes.length > 3) {
      throw Exception('Maximum 3 photos');
    }

    final urls = <String>[];
    for (var i = 0; i < imageBytes.length; i++) {
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
      urls.add(url);
    }

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
    return YaCopeListing.fromJson(body['listing'] as Map<String, dynamic>);
  }
}
