import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web Share API with image file — opens the system share sheet (WhatsApp, etc.).
Future<bool> shareImageAndTextOnWeb({
  required Uint8List imageBytes,
  required String text,
  String filename = 'uzaapp_share.jpg',
  String mimeType = 'image/jpeg',
}) async {
  try {
    final blob = html.Blob([imageBytes], mimeType);
    final file = html.File([blob], filename, {'type': mimeType});
    final shareData = <String, Object>{
      'text': text.trim(),
      'files': <html.File>[file],
    };

    final nav = html.window.navigator;
    final dynamic navDyn = nav;
    final canShareFn = navDyn.canShare;
    if (canShareFn != null) {
      final can = navDyn.canShare(shareData) as bool?;
      if (can == false) {
        return false;
      }
    }

    await navDyn.share(shareData);
    return true;
  } catch (e) {
    // ignore: avoid_print
    print('shareImageAndTextOnWeb failed: $e');
    return false;
  }
}
