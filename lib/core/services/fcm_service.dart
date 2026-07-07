import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Registers device tokens with the server for push notifications.
/// Uses a persistent local token until Firebase Messaging is configured.
class FcmService {
  static const _tokenKey = 'fcm_device_token';

  final ApiService _api;

  FcmService(this._api);

  Future<String> getOrCreateDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      token = 'uza_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await prefs.setString(_tokenKey, token);
    }
    return token;
  }

  Future<bool> registerToken({String? userPhone, int? shopId}) async {
    if (kIsWeb) return false;
    try {
      final token = await getOrCreateDeviceToken();
      final uri = Uri.parse(
        '${_api.baseUrl}/fcm.php?api_key=${ApiService.apiKey}',
      );
      final response = await http
          .post(
            uri,
            headers: {
              'X-API-Key': ApiService.apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'token': token,
              'user_phone': userPhone,
              'shop_id': shopId,
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is Map && body['success'] == true;
      }
    } catch (e) {
      debugPrint('FcmService.registerToken error: $e');
    }
    return false;
  }
}
