import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_prepare_utils.dart';
import 'picker_types.dart';

const _imageAccept =
    'image/jpeg,image/png,image/gif,image/webp,image/heic,image/heif,.heic,.heif';

/// Web FileReader may return [ByteBuffer], [Uint8List], or [NativeUint8List].
Uint8List? _bytesFromFileReaderResult(Object? result) {
  if (result == null) return null;

  // NativeUint8List implements List<int> but is not always `is Uint8List` in DDC.
  if (result is List<int>) {
    return Uint8List.fromList(result);
  }
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }

  try {
    final dynamic typed = result;
    final buffer = typed.buffer;
    if (buffer is ByteBuffer) {
      final offset = (typed.byteOffset as int?) ?? 0;
      final length = (typed.byteLength as int?) ?? buffer.lengthInBytes;
      return Uint8List.view(buffer, offset, length);
    }
  } catch (e) {
    debugPrint('picker_web: typed array fallback failed: $e');
  }

  return null;
}

Uint8List? _bytesFromDataUrl(String? dataUrl) {
  if (dataUrl == null || !dataUrl.contains(',')) return null;
  try {
    return base64Decode(dataUrl.split(',').last);
  } catch (e) {
    debugPrint('picker_web: data URL decode failed: $e');
    return null;
  }
}

Future<Uint8List?> _readFileWithReader(
  html.File file, {
  required void Function(html.FileReader reader) startRead,
  required Uint8List? Function(Object? result) parseResult,
}) async {
  final reader = html.FileReader();
  final completer = Completer<Uint8List?>();
  reader.onError.listen((_) {
    if (!completer.isCompleted) completer.complete(null);
  });
  reader.onLoadEnd.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(parseResult(reader.result));
    }
  });
  startRead(reader);
  return completer.future;
}

Future<Uint8List?> _readFileAsImageBytes(html.File file) async {
  var bytes = await _readFileWithReader(
    file,
    startRead: (reader) => reader.readAsArrayBuffer(file),
    parseResult: _bytesFromFileReaderResult,
  );

  if (bytes == null || bytes.isEmpty) {
    bytes = await _readFileWithReader(
      file,
      startRead: (reader) => reader.readAsDataUrl(file),
      parseResult: (result) => _bytesFromDataUrl(result as String?),
    );
  }

  return bytes;
}

/// Videos can be large — array buffer only (no base64 data URL fallback).
Future<Uint8List?> _readFileAsVideoBytes(html.File file) async {
  return _readFileWithReader(
    file,
    startRead: (reader) => reader.readAsArrayBuffer(file),
    parseResult: _bytesFromFileReaderResult,
  );
}

String _videoFileNameFromFile(html.File file) {
  final name = file.name.trim();
  if (name.isNotEmpty && name.contains('.')) return name;
  final mime = file.type.toLowerCase();
  if (mime.contains('quicktime')) {
    return 'video_${DateTime.now().millisecondsSinceEpoch}.mov';
  }
  if (mime.contains('webm')) {
    return 'video_${DateTime.now().millisecondsSinceEpoch}.webm';
  }
  return 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
}

Future<T?> _pickWithInput<T>({
  required String accept,
  required bool multiple,
  required Future<T?> Function(List<html.File> files) onFiles,
}) async {
  final uploadInput = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = multiple;

  final completer = Completer<T?>();
  var selected = false;

  void completeOnce(T? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  late StreamSubscription<html.Event> focusSub;
  focusSub = html.window.onFocus.listen((_) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!selected) completeOnce(null);
      focusSub.cancel();
    });
  });

  uploadInput.onChange.listen((_) async {
    selected = true;
    focusSub.cancel();
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completeOnce(null);
      return;
    }
    try {
      completeOnce(await onFiles(files));
    } catch (_) {
      completeOnce(null);
    }
  });

  uploadInput.click();
  final result = await completer.future;
  await focusSub.cancel();
  return result;
}

Future<Uint8List?> pickImage(
  BuildContext context, {
  PickerImageSource source = PickerImageSource.gallery,
}) async {
  final bytes = await _pickWithInput<Uint8List?>(
    accept: _imageAccept,
    multiple: false,
    onFiles: (files) async {
      final file = files.first;
      final raw = await _readFileAsImageBytes(file);
      if (raw == null) return null;
      final prepared = await ImagePrepareUtils.prepareForUpload(
        raw,
        sourceName: file.name,
      );
      return prepared.bytes;
    },
  );
  return bytes;
}

Future<List<Uint8List>> pickMultipleImages(BuildContext context) async {
  final images = await _pickWithInput<List<Uint8List>>(
    accept: _imageAccept,
    multiple: true,
    onFiles: (files) async {
      final results = <Uint8List>[];
      for (final file in files) {
        final raw = await _readFileAsImageBytes(file);
        if (raw == null) continue;
        final prepared = await ImagePrepareUtils.prepareForUpload(
          raw,
          sourceName: file.name,
        );
        results.add(prepared.bytes);
      }
      return results;
    },
  );
  return images ?? const [];
}

Future<PickedVideo?> pickVideo(BuildContext context) async {
  return _pickWithInput<PickedVideo?>(
    accept:
        'video/mp4,video/quicktime,video/webm,video/x-msvideo,video/*,.mp4,.mov,.webm,.avi',
    multiple: false,
    onFiles: (files) async {
      final file = files.first;
      final raw = await _readFileAsVideoBytes(file);
      if (raw == null || raw.isEmpty) return null;
      return PickedVideo(bytes: raw, fileName: _videoFileNameFromFile(file));
    },
  );
}
