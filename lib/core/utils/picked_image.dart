import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

@immutable
class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  /// Dibuat baru setiap kali, karena `MultipartFile` hanya bisa dibaca sekali
  /// (diperlukan saat request diulang setelah sesi diperbarui).
  MultipartFile toMultipart() {
    final dot = filename.lastIndexOf('.');
    final ext = dot < 0 ? 'jpeg' : filename.substring(dot + 1).toLowerCase();
    final subtype = switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      'gif' => 'gif',
      _ => 'jpeg',
    };
    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: DioMediaType('image', subtype),
    );
  }
}
