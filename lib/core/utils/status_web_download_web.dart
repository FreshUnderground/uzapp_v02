import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadStatusImages(int shopId, List<Uint8List> images) async {
  if (images.isEmpty) return false;

  for (var i = 0; i < images.length; i++) {
    final blob = html.Blob([images[i]], 'image/jpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'uzaapp_status_${shopId}_$i.jpg')
      ..click();
    html.Url.revokeObjectUrl(url);
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  return true;
}
