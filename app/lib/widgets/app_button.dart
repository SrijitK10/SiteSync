import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/platform_utils.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isWindows = isWindowsDesktop;
    final background = color ?? Theme.of(context).colorScheme.primary;
    final foreground = textColor ?? Theme.of(context).colorScheme.onPrimary;
    final borderRadius = BorderRadius.circular(isWindows ? 18 : 8);

    return SizedBox(
      width: double.infinity,
      height: isWindows ? 54 : 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isWindows ? null : background,
          gradient: isWindows
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(background, Colors.white, 0.08)!,
                    Color.lerp(background, AppTheme.accent, 0.1)!,
                  ],
                )
              : null,
          borderRadius: borderRadius,
          boxShadow: isWindows
              ? [
                  BoxShadow(
                    color: background.withValues(alpha: 0.24),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: foreground,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: foreground.withValues(alpha: 0.8),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: EdgeInsets.symmetric(horizontal: isWindows ? 22 : 16),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: foreground,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: AppTheme.body.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
