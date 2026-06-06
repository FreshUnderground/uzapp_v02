import 'dart:typed_data';

enum PickerImageSource { gallery, camera }

/// Bytes + original filename (important for video MIME on upload).
class PickedVideo {
  final Uint8List bytes;
  final String fileName;

  const PickedVideo({required this.bytes, required this.fileName});
}
