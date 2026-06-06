import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'picker_types.dart';
import 'picker_web.dart' if (dart.library.io) 'picker_mobile.dart' as platform;

export 'picker_types.dart';

class PickerUtils {
  static Future<Uint8List?> pickImage(
    BuildContext context, {
    PickerImageSource source = PickerImageSource.gallery,
  }) {
    return platform.pickImage(context, source: source);
  }

  static Future<List<Uint8List>> pickMultipleImages(BuildContext context) {
    return platform.pickMultipleImages(context);
  }

  static Future<PickedVideo?> pickVideo(BuildContext context) {
    return platform.pickVideo(context);
  }
}
