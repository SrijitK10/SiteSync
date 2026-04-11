import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

typedef PhoneVerificationCompleted =
    Future<void> Function(fb.PhoneAuthCredential credential);
typedef PhoneVerificationFailed =
    void Function(
      fb.FirebaseAuthException exception, {
      required bool usedRecaptchaFallback,
    });

class PhoneAuthService {
  static bool get _isAndroidPhoneAuthTarget {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    required void Function() onRecaptchaFallbackEnabled,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
    bool preferRecaptcha = false,
  }) async {
    final auth = fb.FirebaseAuth.instance;
    final canRetryWithRecaptcha = _isAndroidPhoneAuthTarget && !preferRecaptcha;

    Future<void> runAttempt(bool useRecaptcha) async {
      if (_isAndroidPhoneAuthTarget) {
        await auth.setSettings(forceRecaptchaFlow: useRecaptcha);
      }

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        forceResendingToken: forceResendingToken,
        verificationCompleted: verificationCompleted,
        verificationFailed: (fb.FirebaseAuthException exception) async {
          if (!useRecaptcha && _shouldRetryWithRecaptcha(exception)) {
            onRecaptchaFallbackEnabled();
            try {
              await runAttempt(true);
            } on fb.FirebaseAuthException catch (retryException) {
              verificationFailed(retryException, usedRecaptchaFallback: true);
            }
            return;
          }

          verificationFailed(exception, usedRecaptchaFallback: useRecaptcha);
        },
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    }

    try {
      await runAttempt(preferRecaptcha);
    } on fb.FirebaseAuthException catch (exception) {
      if (canRetryWithRecaptcha && _shouldRetryWithRecaptcha(exception)) {
        onRecaptchaFallbackEnabled();
        await runAttempt(true);
        return;
      }
      rethrow;
    }
  }

  static bool _shouldRetryWithRecaptcha(fb.FirebaseAuthException exception) {
    final code = exception.code.toLowerCase();
    final message = (exception.message ?? '').toLowerCase();
    final combined = '$code $message';

    return combined.contains('play_integrity') ||
        combined.contains('play integrity') ||
        combined.contains('play_integrity_token') ||
        combined.contains('invalid app info') ||
        combined.contains('invalid-app-credential') ||
        combined.contains('app not authorized') ||
        combined.contains('app-not-authorized');
  }
}
