import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_prepare_utils.dart';
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
    imageQuality: 85,
  );

  if (pickedFile == null) return null;

  final rawBytes = await pickedFile.readAsBytes();
  final prepared = await ImagePrepareUtils.prepareForUpload(
    rawBytes,
    sourceName: pickedFile.name,
    sourcePath: pickedFile.path,
  );
  return prepared.bytes;
}

Future<List<Uint8List>> pickMultipleImages(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
  if (pickedFiles.isEmpty) return const [];

  final results = <Uint8List>[];
  for (final file in pickedFiles) {
    final rawBytes = await file.readAsBytes();
    final prepared = await ImagePrepareUtils.prepareForUpload(
      rawBytes,
      sourceName: file.name,
      sourcePath: file.path,
    );
    results.add(prepared.bytes);
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
