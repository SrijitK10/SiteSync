import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_picker/file_picker.dart';

/// Mobile/Desktop implementation: writes to documents directory and opens share sheet on mobile,
/// or prompts for a save location natively on desktop platforms.
Future<void> exportFilePlatform({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
}) async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: fileName,
    );
    
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
    }
  } else {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(filePath)], text: shareText ?? fileName);
  }
}
