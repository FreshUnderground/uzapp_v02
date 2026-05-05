import 'package:encrypt/encrypt.dart';

class CryptoUtils {
  // Fixed key for demo/offline storage (In production, this should be derived or stored securely)
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1');
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    // If it's already a plain URL, return as-is
    if (encryptedText.startsWith('http://') ||
        encryptedText.startsWith('https://') ||
        encryptedText.startsWith('data:image')) {
      return encryptedText;
    }

    // If it looks like a JSON array of URLs, return as-is
    if (encryptedText.trim().startsWith('[') &&
        encryptedText.contains('http')) {
      return encryptedText;
    }

    try {
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      return encryptedText; // Fallback if regular text
    }
  }
}
