import 'dart:typed_data';

import 'browser_file_opener_stub.dart'
    if (dart.library.html) 'browser_file_opener_web.dart';

Future<bool> openBrowserFile({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
  bool preferInline = false,
}) {
  return openBrowserFilePlatform(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    preferInline: preferInline,
  );
}
