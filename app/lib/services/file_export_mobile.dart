import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile implementation: writes to documents directory and opens share sheet.
Future<void> exportFilePlatform({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(filePath)], text: shareText ?? fileName);
}
