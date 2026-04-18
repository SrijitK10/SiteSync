// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> openBrowserFilePlatform({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
  bool preferInline = false,
}) async {
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    final anchor = html.AnchorElement(href: url);
    if (preferInline) {
      anchor.target = '_blank';
      anchor.rel = 'noopener noreferrer';
    } else {
      anchor.setAttribute('download', fileName);
    }
    anchor.click();
    return true;
  } finally {
    unawaited(
      Future<void>.delayed(const Duration(minutes: 1), () {
        html.Url.revokeObjectUrl(url);
      }),
    );
  }
}
