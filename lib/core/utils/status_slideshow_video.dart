import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'status_slideshow_mp4.dart';

/// Slideshow export for TikTok — lightweight H.264 MP4 (mobile/desktop native).
class StatusSlideshowVideo {
  static const int tikTokMaxSlides = 5;
  static const int totalDurationSeconds = 10;
  static const int framesPerSecond = 20;
  static const int canvasWidth = 720;
  static const int canvasHeight = 1280;
  static const int crossfadeFrames = 14;

  /// Builds MP4 on Android/iOS/macOS. Web returns null (share images instead).
  static Future<StatusSlideshowExport?> exportForTikTok({
    required List<Uint8List> images,
    required int shopId,
    String? shopName,
  }) async {
    if (images.isEmpty || !slideshowMp4Supported) return null;

    final slides = images.take(tikTokMaxSlides).toList();
    final rendered = await compute(
      _renderSlideshowFramesIsolate,
      _SlideshowInput(slides, shopName),
    );
    if (rendered == null || rendered.rgbaFrames.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final mp4Path =
        '${dir.path}/uza_tiktok_${shopId}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final encoded = await encodeRgbaFramesToMp4(
      rgbaFrames: rendered.rgbaFrames,
      outputPath: mp4Path,
      width: canvasWidth,
      height: canvasHeight,
      fps: framesPerSecond,
    );

    if (encoded == null) {
      debugPrint('StatusSlideshowVideo: MP4 encode failed, no GIF fallback');
      return null;
    }

    return StatusSlideshowExport(
      filePath: encoded,
      frameCount: rendered.rgbaFrames.length,
    );
  }
}

class StatusSlideshowExport {
  final String filePath;
  final int frameCount;

  const StatusSlideshowExport({
    required this.filePath,
    required this.frameCount,
  });
}

class _SlideshowInput {
  final List<Uint8List> images;
  final String? shopName;

  const _SlideshowInput(this.images, this.shopName);
}

class _SlideshowFrameResult {
  final List<Uint8List> rgbaFrames;

  const _SlideshowFrameResult(this.rgbaFrames);
}

_SlideshowFrameResult? _renderSlideshowFramesIsolate(_SlideshowInput input) {
  if (input.images.isEmpty) return null;

  final w = StatusSlideshowVideo.canvasWidth;
  final h = StatusSlideshowVideo.canvasHeight;
  const kenBurnsScale = 1.14;

  final slides = <img.Image>[];
  for (final bytes in input.images) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) continue;
    slides.add(
      img.copyResize(
        decoded,
        width: (w * kenBurnsScale).round(),
        height: (h * kenBurnsScale).round(),
        interpolation: img.Interpolation.cubic,
      ),
    );
  }
  if (slides.isEmpty) return null;

  final totalFrames =
      StatusSlideshowVideo.totalDurationSeconds *
      StatusSlideshowVideo.framesPerSecond;
  final framesPerSlide = (totalFrames / slides.length).ceil();
  final rgbaFrames = <Uint8List>[];

  for (var frame = 0; frame < totalFrames; frame++) {
    final slideIndex = math.min(frame ~/ framesPerSlide, slides.length - 1);
    final localFrame = frame - slideIndex * framesPerSlide;
    final slideProgress = localFrame / framesPerSlide;

    final current = _kenBurnsFrame(slides[slideIndex], slideProgress, w, h);

    img.Image composed;
    final crossfadeStart =
        framesPerSlide - StatusSlideshowVideo.crossfadeFrames;
    final hasNext = slideIndex < slides.length - 1;

    if (hasNext && localFrame >= crossfadeStart) {
      final linear =
          (localFrame - crossfadeStart) /
          StatusSlideshowVideo.crossfadeFrames;
      final blend = _smoothStep(linear.clamp(0.0, 1.0));
      final nextProgress = blend * 0.4;
      final next = _kenBurnsFrame(
        slides[slideIndex + 1],
        nextProgress,
        w,
        h,
      );
      composed = _crossfade(current, next, blend);
    } else {
      composed = current;
    }

    _applyVignette(composed);
    _drawProgressBar(composed, (frame + 1) / totalFrames);

    if (input.shopName != null && input.shopName!.trim().isNotEmpty) {
      _drawShopLabel(composed, input.shopName!.trim());
    }

    rgbaFrames.add(
      Uint8List.fromList(composed.getBytes(order: img.ChannelOrder.rgba)),
    );
  }

  return _SlideshowFrameResult(rgbaFrames);
}

img.Image _kenBurnsFrame(
  img.Image prepared,
  double progress,
  int width,
  int height,
) {
  final eased = _easeInOutCubic(progress);
  final panX = ((prepared.width - width) * eased * 0.52).round();
  final panY = ((prepared.height - height) * eased * 0.3).round();

  return img.copyCrop(
    prepared,
    x: panX.clamp(0, math.max(0, prepared.width - width)),
    y: panY.clamp(0, math.max(0, prepared.height - height)),
    width: width,
    height: height,
  );
}

double _easeInOutCubic(double t) {
  if (t < 0.5) return 4 * t * t * t;
  return 1 - math.pow(-2 * t + 2, 3) / 2;
}

double _smoothStep(double t) => t * t * (3 - 2 * t);

img.Image _crossfade(img.Image a, img.Image b, double blend) {
  final out = img.Image.from(a);
  final inv = 1.0 - blend;

  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      out.setPixelRgba(
        x,
        y,
        (pa.r * inv + pb.r * blend).round(),
        (pa.g * inv + pb.g * blend).round(),
        (pa.b * inv + pb.b * blend).round(),
        255,
      );
    }
  }

  return out;
}

void _applyVignette(img.Image image) {
  final w = image.width;
  final h = image.height;
  final band = (h * 0.1).round();

  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: w,
    y2: band,
    color: img.ColorRgba8(0, 0, 0, 45),
  );
  img.fillRect(
    image,
    x1: 0,
    y1: h - band,
    x2: w,
    y2: h,
    color: img.ColorRgba8(0, 0, 0, 60),
  );
}

void _drawProgressBar(img.Image image, double progress) {
  const barHeight = 4;
  const margin = 28;
  final w = image.width;
  final h = image.height;
  final y = h - margin;
  final totalW = w - margin * 2;
  final fillW = (totalW * progress.clamp(0.0, 1.0)).round();

  img.fillRect(
    image,
    x1: margin,
    y1: y,
    x2: margin + totalW,
    y2: y + barHeight,
    color: img.ColorRgba8(255, 255, 255, 50),
  );

  if (fillW > 0) {
    img.fillRect(
      image,
      x1: margin,
      y1: y,
      x2: margin + fillW,
      y2: y + barHeight,
      color: img.ColorRgba8(254, 62, 0, 235),
    );
  }
}

void _drawShopLabel(img.Image image, String shopName) {
  final label = shopName.length > 28
      ? '${shopName.substring(0, 27).trim()}…'
      : shopName;
  const barH = 42;
  const margin = 24;
  final y = image.height - margin - barH - 12;

  img.fillRect(
    image,
    x1: margin,
    y1: y,
    x2: image.width - margin,
    y2: y + barH,
    color: img.ColorRgba8(0, 0, 0, 115),
    radius: 10,
  );

  img.drawString(
    image,
    label,
    font: img.arial14,
    x: margin + 14,
    y: y + 13,
    color: img.ColorRgba8(255, 255, 255, 240),
  );
}
