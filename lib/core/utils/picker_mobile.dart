import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_compress_utils.dart';

Future<Uint8List?> pickImage(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );

  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    final compressed = await ImageCompressUtils.compressImage(bytes);
    return compressed ?? bytes;
  }
  return null;
}

Future<Uint8List?> pickVideo(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

  if (pickedFile != null) {
    return await pickedFile.readAsBytes();
  }
  return null;
}
