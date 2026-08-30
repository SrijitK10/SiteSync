import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

bool get isApplePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool get isWindowsDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows;
}

bool get usesPasswordAuth => isApplePlatform || isWindowsDesktop;

/// Turns any error thrown by the app (Dio, Firebase Auth, or a generic
/// exception) into a short, user-facing message — never a raw stack trace
/// or "DioException [bad response]: ..." string.
String extractErrorMessage(dynamic error) {
  if (error is DioException) return _dioMessage(error);
  if (error is fb.FirebaseAuthException) return _firebaseAuthMessage(error);

  final str = error.toString();

  // Some call sites re-throw as `Exception('prefix: $original')`, which
  // buries the backend's JSON body inside the string — pull it back out.
  final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
  if (match != null) return match.group(1)!;

  return str.replaceFirst(RegExp(r'^Exception:\s*'), '');
}

String _dioMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    final message = data['message'];
    if (message is List && message.isNotEmpty) {
      return message.join('\n');
    }
    if (message is String && message.isNotEmpty) return message;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The server took too long to respond. Please try again.';
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Unable to reach the server. Check your internet connection and try again.';
    case DioExceptionType.badCertificate:
      return 'Could not establish a secure connection to the server.';
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code != null && code >= 500) {
        return 'Something went wrong on our end. Please try again in a moment.';
      }
      return 'The request could not be completed. Please try again.';
  }
}

String _firebaseAuthMessage(fb.FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-phone-number':
      return "That phone number doesn't look valid. Please check and try again.";
    case 'too-many-requests':
      return 'Too many attempts. Please wait a while before trying again.';
    case 'invalid-verification-code':
      return 'That OTP is incorrect. Please check and try again.';
    case 'session-expired':
    case 'code-expired':
      return 'The OTP has expired. Please request a new one.';
    case 'network-request-failed':
      return 'Unable to reach the server. Check your internet connection and try again.';
    case 'quota-exceeded':
      return 'SMS quota exceeded. Please try again later.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support for help.';
    default:
      return error.message ?? 'Verification failed. Please try again.';
  }
}
