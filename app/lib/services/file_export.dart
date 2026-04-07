import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditionally import dart:html for web, dart:io for mobile
import 'file_export_stub.dart'
    if (dart.library.html) 'file_export_web.dart'
    if (dart.library.io) 'file_export_mobile.dart';

/// Platform-aware file export.
/// On web: triggers a browser download.
/// On mobile: saves to documents dir and opens share sheet.
Future<void> exportFile({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
}) async {
  await exportFilePlatform(
    bytes: bytes,
    fileName: fileName,
    shareText: shareText,
  );
}
