import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../services/api_client.dart';
import '../services/phone_auth_service.dart';
import '../services/platform_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1: enter phone, 2: verify OTP, 3: new password
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  String? _firebaseIdToken;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _preferRecaptcha = false;

  // ── Step 1: Send SMS OTP ──────────────────────────────────────

  void _sendPhoneOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
        ),
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
          await _onCredentialObtained(credential);
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
              _step = 2;
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

  // ── Step 2: Verify OTP ────────────────────────────────────────

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
      await _onCredentialObtained(credential);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
      }
    }
  }

  Future<void> _onCredentialObtained(fb.PhoneAuthCredential credential) async {
    try {
      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null && mounted) {
        setState(() {
          _firebaseIdToken = idToken;
          _isLoading = false;
          _step = 3;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    }
  }

  // ── Step 3: Set new password ──────────────────────────────────

  void _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await apiClient.post(
        '/auth/reset-password',
        data: {'firebaseIdToken': _firebaseIdToken, 'newPassword': password},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please sign in.'),
          ),
        );
        context.go('/login');
      }
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
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Reset Password'),
      ),
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
                  Icon(Icons.lock_reset, size: 48, color: AppTheme.accent),
                  const SizedBox(height: 16),
                  Text(
                    _step == 1
                        ? 'Enter your phone number'
                        : _step == 2
                        ? 'Verify your identity'
                        : 'Set new password',
                    textAlign: TextAlign.center,
                    style: AppTheme.heading.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'We\'ll send an SMS to verify your identity.'
                        : _step == 2
                        ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                        : 'Choose a strong password for your account.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_step == 1) ..._buildPhoneStep(),
                  if (_step == 2) ..._buildOtpStep(),
                  if (_step == 3) ..._buildPasswordStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPhoneStep() {
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: 24),
      AppButton(
        text: 'Send Verification Code',
        isLoading: _isLoading,
        onPressed: _sendPhoneOTP,
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: 24),
      AppButton(text: 'Verify', isLoading: _isLoading, onPressed: _verifyOTP),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _step = 1;
                _otpController.clear();
              });
            },
            child: const Text('Change Number'),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _resendCountdown > 0 ? null : _sendPhoneOTP,
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

  List<Widget> _buildPasswordStep() {
    return [
      Text('NEW PASSWORD', style: AppTheme.label),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: AppTheme.body,
        decoration: InputDecoration(
          hintText: 'Min. 6 characters',
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
      const SizedBox(height: 20),
      Text('CONFIRM PASSWORD', style: AppTheme.label),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        style: AppTheme.body,
        decoration: InputDecoration(
          hintText: 'Re-enter your password',
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
              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
      const SizedBox(height: 24),
      AppButton(
        text: 'Reset Password',
        isLoading: _isLoading,
        onPressed: _resetPassword,
      ),
    ];
  }
}
