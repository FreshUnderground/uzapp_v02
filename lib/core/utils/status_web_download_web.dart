import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadStatusImages(int shopId, List<Uint8List> images) {
  return downloadStatusFiles(
    shopId: shopId,
    files: images,
    extension: 'jpg',
    mimeType: 'image/jpeg',
    namePrefix: 'uzaapp_status',
  );
}

Future<bool> downloadStatusGif(int shopId, Uint8List gifBytes) {
  return downloadStatusFiles(
    shopId: shopId,
    files: [gifBytes],
    extension: 'gif',
    mimeType: 'image/gif',
    namePrefix: 'uzaapp_tiktok',
  );
}

Future<bool> downloadStatusFiles({
  required int shopId,
  required List<Uint8List> files,
  required String extension,
  required String mimeType,
  required String namePrefix,
}) async {
  if (files.isEmpty) return false;

  for (var i = 0; i < files.length; i++) {
    final filename = files.length == 1
        ? '${namePrefix}_$shopId.$extension'
        : '${namePrefix}_${shopId}_$i.$extension';
    final blob = html.Blob([files[i]], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  return true;
}
