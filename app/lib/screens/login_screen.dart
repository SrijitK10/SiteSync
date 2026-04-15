import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../state/auth_provider.dart';
import '../services/platform_utils.dart';
import '../services/phone_auth_service.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Shared
  bool _isLoading = false;

  // Phone OTP (Android)
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  bool _preferRecaptcha = false;

  // Email + Password (iOS)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ── PHONE OTP FLOW (Android) ──────────────────────────────────

  void _sendOTP() async {
    final l = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.validMobileError)),
      );
      return;
    }

    final fullPhone = '+91$phone';
    setState(() => _isLoading = true);

    try {
      await PhoneAuthService.verifyPhoneNumber(
        phoneNumber: fullPhone,
        preferRecaptcha: _preferRecaptcha,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed:
            (
              fb.FirebaseAuthException e, {
              required bool usedRecaptchaFallback,
            }) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      usedRecaptchaFallback
                          ? 'Verification failed even after retrying with browser verification: ${e.message}'
                          : 'Verification failed: ${e.message}',
                    ),
                  ),
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
        onRecaptchaFallbackEnabled: () {
          if (mounted) {
            setState(() => _preferRecaptcha = true);
          } else {
            _preferRecaptcha = true;
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final l = AppLocalizations.of(context)!;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.enterOTPError)),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
      }
    }
  }

  Future<void> _signInWithCredential(fb.PhoneAuthCredential credential) async {
    try {
      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null && mounted) {
        await ref.read(authProvider.notifier).loginWithFirebaseToken(idToken);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  // ── EMAIL + PASSWORD FLOW (iOS) ───────────────────────────────

  void _loginWithPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.validEmailError)),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.enterPasswordError)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).loginWithPassword(email, password);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
      }
    }
  }

  // ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/rppl.png', height: 100),
                  const SizedBox(height: 40),

                  if (isApplePlatform)
                    ..._buildEmailPasswordFlow()
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
    final l = AppLocalizations.of(context)!;
    if (!_otpSent) {
      return [
        Text(l.mobileNumber, style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: AppTheme.body,
          decoration: InputDecoration(
            prefixText: '+91  ',
            prefixStyle: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
            hintText: l.mobileNumberHint,
            counterText: '',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(text: l.sendOTP, isLoading: _isLoading, onPressed: _sendOTP),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.dontHaveAccount),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: Text(l.signUp),
            ),
          ],
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
        Text(l.enterOTP, style: AppTheme.label),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: l.verifySignIn,
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
              child: Text(l.changeNumber),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _sendOTP,
              child: Text(
                _resendCountdown > 0
                    ? l.resendIn(_resendCountdown)
                    : l.resendOTP,
              ),
            ),
          ],
        ),
      ];
    }
  }

  // ── EMAIL + PASSWORD UI (iOS) ─────────────────────────────────

  List<Widget> _buildEmailPasswordFlow() {
    final l = AppLocalizations.of(context)!;
    return [
      Text(l.emailAddress, style: AppTheme.label),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: AppTheme.body,
        decoration: InputDecoration(
          hintText: l.emailHint,
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(l.password, style: AppTheme.label),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: AppTheme.body,
        decoration: InputDecoration(
          hintText: l.passwordHint,
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.push('/forgot-password'),
          child: Text(l.forgotPassword),
        ),
      ),
      const SizedBox(height: 16),
      AppButton(
        text: l.signIn,
        isLoading: _isLoading,
        onPressed: _loginWithPassword,
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.dontHaveAccount),
          TextButton(
            onPressed: () => context.go('/signup'),
            child: Text(l.signUp),
          ),
        ],
      ),
    ];
  }
}
