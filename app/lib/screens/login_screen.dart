import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_card.dart';
import '../state/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      if (mounted) {
        setState(() => _isLoading = false);
        await ref.read(authProvider.notifier).login(
          _emailController.text, 
          _passwordController.text
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
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
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo Placeholder
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
                  
                  AppTextField(
                    label: 'EMAIL',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  
                  AppTextField(
                    label: 'PASSWORD',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.label.copyWith(
                          color: AppTheme.primary,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  AppButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
