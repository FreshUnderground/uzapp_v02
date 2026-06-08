import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<(List<XFile>, List<String>)> writeStatusShareFiles(
  int shopId,
  List<Uint8List> images,
) async {
  final xfiles = images.asMap().entries.map((entry) {
    return XFile.fromData(
      entry.value,
      mimeType: 'image/jpeg',
      name: 'status_${shopId}_${entry.key}.jpg',
    );
  }).toList();
  return (xfiles, <String>[]);
}

Future<void> deleteStatusTempFiles(List<String> paths) async {}
