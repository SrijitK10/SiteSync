import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

bool get isApplePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
         defaultTargetPlatform == TargetPlatform.macOS;
}

String extractErrorMessage(dynamic error) {
  if (error is Exception) {
    final str = error.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
  }
  return error.toString();
}
