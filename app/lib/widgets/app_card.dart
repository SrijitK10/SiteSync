import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/platform_utils.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWindows = isWindowsDesktop;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: isWindows
            ? AppTheme.desktopPaneDecoration(context, radius: 28)
            : BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: child,
      ),
    );
  }
}
