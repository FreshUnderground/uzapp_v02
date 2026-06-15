import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';

bool get slideshowMp4Supported =>
    !kIsWeb &&
    (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

/// Encodes raw RGBA frames to H.264 MP4 using the device hardware encoder.
Future<String?> encodeRgbaFramesToMp4({
  required List<Uint8List> rgbaFrames,
  required String outputPath,
  required int width,
  required int height,
  required int fps,
}) async {
  if (!slideshowMp4Supported || rgbaFrames.isEmpty) return null;

  final expectedBytes = width * height * 4;

  await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
  await FlutterQuickVideoEncoder.setup(
    width: width,
    height: height,
    fps: fps,
    videoBitrate: 2_500_000,
    profileLevel: ProfileLevel.highAutoLevel,
    audioChannels: 0,
    audioBitrate: 0,
    sampleRate: 44_100,
    filepath: outputPath,
  );

  try {
    for (var i = 0; i < rgbaFrames.length; i++) {
      final rgba = rgbaFrames[i];
      if (rgba.length != expectedBytes) {
        debugPrint(
          'StatusSlideshowMp4: skip frame $i (${rgba.length} vs $expectedBytes)',
        );
        continue;
      }

      await FlutterQuickVideoEncoder.appendVideoFrame(rgba);

      if (i % 6 == 5) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await FlutterQuickVideoEncoder.finish();
    return outputPath;
  } catch (e, st) {
    debugPrint('StatusSlideshowMp4: encode failed: $e\n$st');
    try {
      await FlutterQuickVideoEncoder.finish();
    } catch (_) {}
    return null;
  }
}
