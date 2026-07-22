import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service pour l'envoi de SMS via le proxy serveur (jamais la clé AT côté client).
class SmsService {
  static String get _serverApiKey => ApiService.apiKey;

  static const String _proxyUrl = 'https://uzaapp.com/api/send_sms.php';

  /// Envoie un SMS en masse ou à un seul numéro
  /// [destinataires] list of phone numbers (ex: +243...)
  static Future<bool> envoyerSmsBulk(
    List<String> destinataires,
    String message,
  ) async {
    if (destinataires.isEmpty) return false;

    List<String> validPhones = [];
    for (String dest in destinataires) {
      String phone = dest.trim();
      if (phone.isEmpty) continue;

      if (!phone.startsWith('+')) {
        if (phone.startsWith('0')) {
          phone = '+243${phone.substring(1)}';
        } else {
          phone = '+243$phone';
        }
      }
      validPhones.add(phone);
    }

    if (validPhones.isEmpty) return false;

    String messageSecurise = _normalizeText(message);
    if (messageSecurise.length > 160) {
      messageSecurise = '${messageSecurise.substring(0, 157)}...';
    }

    return _sendViaProxy(validPhones, messageSecurise);
  }

  static Future<bool> _sendViaProxy(List<String> phones, String message) async {
    try {
      final response = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': _serverApiKey,
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'to': phones.join(','),
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      if (kDebugMode) {
        debugPrint('SMS proxy error: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SMS proxy exception: $e');
      }
      return false;
    }
  }

  static Future<bool> envoyerSms(String destinataire, String message) async {
    return envoyerSmsBulk([destinataire], message);
  }

  static Future<bool> envoyerCodeOtp(String phone, String code) async {
    final message =
        'Votre code de verification UzaApp est: $code. Ne le partagez avec personne.';
    return envoyerSms(phone, message);
  }

  static String _normalizeText(String text) {
    const map = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'û': 'u',
      'ù': 'u',
      'ü': 'u',
      'ç': 'c',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'À': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Î': 'I',
      'Ï': 'I',
      'Ô': 'O',
      'Ö': 'O',
      'Û': 'U',
      'Ù': 'U',
      'Ü': 'U',
      'Ç': 'C',
    };

    String normalized = text;
    map.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized;
  }
}
