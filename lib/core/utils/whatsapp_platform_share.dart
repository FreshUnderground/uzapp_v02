import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android-only direct share to a WhatsApp chat (image + text).
class WhatsappPlatformShare {
  WhatsappPlatformShare._();

  static const _channel = MethodChannel('com.investeegroup.uzaapp/whatsapp');

  static Future<bool> shareToChat({
    required String phone,
    required String text,
    String? imagePath,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (imagePath == null || imagePath.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('shareToChat', {
        'phone': phone,
        'text': text,
        'filePath': imagePath,
      });
      return ok == true;
    } catch (e) {
      debugPrint('WhatsappPlatformShare failed: $e');
      return false;
    }
  }
}
