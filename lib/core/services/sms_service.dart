import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service pour l'envoi de SMS via Africa's Talking
class SmsService {
  // Clé API fournie
  static const String apiKey =
      'atsk_630e7712eae43b599076a099966ab0c552ac8c4f0be256ccd98552837d4abefb2edb51e0';

  // Nom de l'expéditeur (Sender ID)
  static const String senderId = 'UzaApp';

  // Remplacer par votre nom d'utilisateur Africa's Talking
  static const String username = 'UzaApp';

  // Endpoint de l'API (live/sandbox)
  static String get _apiUrl => username == 'sandbox'
      ? 'https://api.sandbox.africastalking.com/version1/messaging'
      : 'https://api.africastalking.com/version1/messaging';

  /// Envoie un SMS en masse ou à un seul numéro
  /// [destinataires] list of phone numbers (ex: +243...)
  static Future<bool> envoyerSmsBulk(
    List<String> destinataires,
    String message,
  ) async {
    if (destinataires.isEmpty) return false;

    // Normalisation des numéros
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

    // Normalisation et sécurisation du message
    String messageSecurise = _normalizeText(message);
    if (messageSecurise.length > 160) {
      messageSecurise = messageSecurise.substring(0, 157) + '...';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          'apiKey': apiKey,
        },
        body: {
          'username': username,
          'to': validPhones.join(','),
          'message': messageSecurise,
          'from': senderId,
          'enqueue': '1',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          final smsData = data['SMSMessageData'];
          if (smsData != null && smsData['Recipients'] != null) {
            final recipients = smsData['Recipients'] as List;
            if (recipients.isNotEmpty) {
              final status = recipients[0]['status'];
              final statusCode = recipients[0]['statusCode'];

              if (statusCode == 100 || statusCode == 101 || statusCode == 102) {
                debugPrint(
                  '✅ SMS accepté par Africa\'s Talking pour ${validPhones.join(',')} (Status: $status)',
                );
                return true;
              } else {
                debugPrint(
                  '❌ SMS refusé par Africa\'s Talking pour ${validPhones.join(',')}. Code: $statusCode, Status: $status',
                );
                debugPrint('Détails complets: ${response.body}');
                return false;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Impossible de parser la réponse: ${response.body}');
        }

        debugPrint(
          '✅ SMS envoyé avec succès à ${validPhones.join(',')} (Réponse brute: ${response.body})',
        );
        return true;
      } else {
        debugPrint(
          '❌ Échec de l\'envoi du SMS (HTTP ${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur HTTP lors de l\'envoi du SMS: $e');
      return false;
    }
  }

  /// Envoie un SMS à un seul numéro (convenience method)
  static Future<bool> envoyerSms(String destinataire, String message) async {
    return envoyerSmsBulk([destinataire], message);
  }

  /// Envoie un code OTP par SMS
  static Future<bool> envoyerCodeOtp(String phone, String code) async {
    final message =
        'Votre code de verification UzaApp est: $code. Ne le partagez avec personne.';
    return envoyerSms(phone, message);
  }

  /// Remplace les caractères spéciaux/accentués par leurs équivalents ASCII (GSM-7 compatible)
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
