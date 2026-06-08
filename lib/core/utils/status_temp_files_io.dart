import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<(List<XFile>, List<String>)> writeStatusShareFiles(
  int shopId,
  List<Uint8List> images,
) async {
  final tempDir = await getTemporaryDirectory();
  final xfiles = <XFile>[];
  final paths = <String>[];

  for (var i = 0; i < images.length; i++) {
    final path = '${tempDir.path}/status_${shopId}_$i.jpg';
    final file = File(path);
    await file.writeAsBytes(images[i]);
    xfiles.add(XFile(path));
    paths.add(path);
  }

  return (xfiles, paths);
}

Future<void> deleteStatusTempFiles(List<String> paths) async {
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
