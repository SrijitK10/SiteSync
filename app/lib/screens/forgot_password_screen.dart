import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  void _handleSendOtp() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  void _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_otpSent) ...[
                  Text(
                    'Enter your email address to receive a password reset OTP.',
                    style: AppTheme.body,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'EMAIL',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Send OTP',
                    isLoading: _isLoading,
                    onPressed: _handleSendOtp,
                  ),
                ] else ...[
                  Text(
                    'An OTP has been sent to your email. Please verify to reset your password.',
                    style: AppTheme.body,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'OTP',
                    hint: 'Enter 6-digit OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Verify OTP',
                    isLoading: _isLoading,
                    onPressed: _handleVerifyOtp,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
