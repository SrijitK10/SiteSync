import 'dart:typed_data';

/// Stub implementation — should never actually be called at runtime.
/// The conditional imports in file_export.dart ensure either web or mobile
/// is loaded instead.
Future<void> exportFilePlatform({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
}) async {
  throw UnsupportedError('Cannot export files on this platform');
}
