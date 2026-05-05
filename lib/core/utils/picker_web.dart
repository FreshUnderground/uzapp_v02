import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Note: Advanced cropping on Web via image_cropper requires cropperjs in index.html.
Future<Uint8List?> pickImage(BuildContext context) async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();

  final completer = Completer<Uint8List?>();

  uploadInput.onChange.listen((e) async {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as Uint8List);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}

Future<Uint8List?> pickVideo(BuildContext context) async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'video/*';
  uploadInput.click();

  final completer = Completer<Uint8List?>();

  uploadInput.onChange.listen((e) async {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as Uint8List);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
