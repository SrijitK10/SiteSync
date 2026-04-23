import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/platform_utils.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isWindows = isWindowsDesktop;
    final borderRadius = BorderRadius.circular(isWindows ? 18 : 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.label.copyWith(
            fontSize: isWindows ? 11 : 12,
            letterSpacing: isWindows ? 1.2 : 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTheme.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: isWindows ? 0.92 : 1),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isWindows ? 18 : 16,
              vertical: isWindows ? 18 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: isWindows ? 1.6 : 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
