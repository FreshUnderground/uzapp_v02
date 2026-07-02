import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'picker_types.dart';

Future<Uint8List?> pickImage(
  BuildContext context, {
  PickerImageSource source = PickerImageSource.gallery,
}) async {
  final picker = ImagePicker();
  final imageSource = source == PickerImageSource.camera
      ? ImageSource.camera
      : ImageSource.gallery;

  final pickedFile = await picker.pickImage(
    source: imageSource,
    imageQuality: 82,
    maxWidth: 1440,
    maxHeight: 1440,
  );

  if (pickedFile == null) return null;

  return pickedFile.readAsBytes();
}

Future<List<Uint8List>> pickMultipleImages(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFiles = await picker.pickMultiImage(
    imageQuality: 82,
    maxWidth: 1440,
    maxHeight: 1440,
  );
  if (pickedFiles.isEmpty) return const [];

  final results = <Uint8List>[];
  for (final file in pickedFiles) {
    final rawBytes = await file.readAsBytes();
    results.add(rawBytes);
  }
  return results;
}

Future<PickedVideo?> pickVideo(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

  if (pickedFile == null) return null;

  final bytes = await pickedFile.readAsBytes();
  final name = pickedFile.name.trim().isNotEmpty
      ? pickedFile.name
      : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
  return PickedVideo(bytes: bytes, fileName: name);
}
