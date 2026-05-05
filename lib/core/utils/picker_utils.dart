import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'picker_web.dart' if (dart.library.io) 'picker_mobile.dart' as platform;

class PickerUtils {
  static Future<Uint8List?> pickImage(BuildContext context) {
    return platform.pickImage(context);
  }

  static Future<Uint8List?> pickVideo(BuildContext context) {
    return platform.pickVideo(context);
  }
}
