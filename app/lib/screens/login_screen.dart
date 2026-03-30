
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../state/auth_provider.dart';

bool get _isApplePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
         defaultTargetPlatform == TargetPlatform.macOS;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _emailLinkSent = false;
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;

  // ── PHONE OTP FLOW (Android) ──────────────────────────────────

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    final fullPhone = '+91$phone';
    setState(() => _isLoading = true);

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _otpSent = true;
              _verificationId = verificationId;
              _resendToken = resendToken;
              _resendCountdown = 30;
            });
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP: $e')),
        );
      }
    }
  }

  // ── EMAIL LINK FLOW (iOS / macOS) ─────────────────────────────

  void _sendEmailLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actionCodeSettings = fb.ActionCodeSettings(
        url: 'https://rupayan-81953.firebaseapp.com/finishSignIn?email=$email',
        handleCodeInApp: true,
        iOSBundleId: 'com.sitesync.app',
        androidPackageName: 'com.sitesync.app',
        androidInstallApp: true,
        androidMinimumVersion: '23',
      );

      await fb.FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailLinkSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email link: $e')),
        );
      }
    }
  }



  // ── SHARED ────────────────────────────────────────────────────

  Future<void> _signInWithCredential(fb.PhoneAuthCredential credential) async {
    try {
      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null && mounted) {
        await ref.read(authProvider.notifier).loginWithFirebaseToken(idToken);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SiteSync',
                    textAlign: TextAlign.center,
                    style: AppTheme.heading.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Construction Management',
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_isApplePlatform)
                    ..._buildEmailLinkFlow()
                  else
                    ..._buildPhoneOTPFlow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── PHONE OTP UI (Android) ────────────────────────────────────

  List<Widget> _buildPhoneOTPFlow() {
    if (!_otpSent) {
      return [
        Text('MOBILE NUMBER', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: AppTheme.body,
          decoration: InputDecoration(
            prefixText: '+91  ',
            prefixStyle: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
            hintText: '98765 43210',
            counterText: '',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Send OTP',
          isLoading: _isLoading,
          onPressed: _sendOTP,
        ),
      ];
    } else {
      return [
        Text(
          'OTP sent to +91 ${_phoneController.text}',
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        Text('ENTER OTP', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTheme.heading.copyWith(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Verify & Sign In',
          isLoading: _isLoading,
          onPressed: _verifyOTP,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _otpController.clear();
                });
              },
              child: const Text('Change Number'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _sendOTP,
              child: Text(
                _resendCountdown > 0 
                  ? 'Resend in ${_resendCountdown}s' 
                  : 'Resend OTP',
              ),
            ),
          ],
        ),
      ];
    }
  }

  // ── EMAIL LINK UI (iOS / macOS) ───────────────────────────────

  List<Widget> _buildEmailLinkFlow() {
    if (!_emailLinkSent) {
      return [
        Text('EMAIL ADDRESS', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.body,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Send Sign-In Link',
          isLoading: _isLoading,
          onPressed: _sendEmailLink,
        ),
        const SizedBox(height: 12),
        Text(
          'A magic link will be sent to your email.\nTap it to sign in — no password needed.',
          textAlign: TextAlign.center,
          style: AppTheme.label.copyWith(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ];
    } else {
      return [
        const Icon(Icons.mark_email_read_outlined, size: 48, color: AppTheme.accent),
        const SizedBox(height: 16),
        Text(
          'Sign-in link sent!',
          textAlign: TextAlign.center,
          style: AppTheme.heading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your email at\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the link in the email to sign in.\nThe app will open automatically.',
          textAlign: TextAlign.center,
          style: AppTheme.label.copyWith(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() {
              _emailLinkSent = false;
              _emailController.clear();
            });
          },
          child: const Text('Use a different email'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendEmailLink,
          child: const Text('Resend link'),
        ),
      ];
    }
  }
}
