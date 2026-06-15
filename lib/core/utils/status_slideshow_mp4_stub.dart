import 'dart:typed_data';

/// Web / unsupported platforms — MP4 hardware encoding unavailable.
Future<String?> encodeRgbaFramesToMp4({
  required List<Uint8List> rgbaFrames,
  required String outputPath,
  required int width,
  required int height,
  required int fps,
}) async =>
    null;

bool get slideshowMp4Supported => false;
