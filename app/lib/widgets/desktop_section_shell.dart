import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/platform_utils.dart';

class DesktopSectionMetric {
  const DesktopSectionMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
}

class DesktopSectionShell extends StatelessWidget {
  const DesktopSectionShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow,
    this.actions,
    this.metrics = const [],
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final List<DesktopSectionMetric> metrics;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!isWindowsDesktop) {
      return child;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            _DesktopSectionHeader(
              eyebrow: eyebrow,
              title: title,
              subtitle: subtitle,
              actions: actions,
              metrics: metrics,
            ),
            const SizedBox(height: 20),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class DesktopSurfaceCard extends StatelessWidget {
  const DesktopSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppTheme.desktopPaneDecoration(context, radius: radius),
      child: child,
    );
  }
}

class _DesktopSectionHeader extends StatelessWidget {
  const _DesktopSectionHeader({
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.metrics,
    this.actions,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final List<DesktopSectionMetric> metrics;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return DesktopSurfaceCard(
      padding: const EdgeInsets.all(28),
      radius: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1080;

          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: AppTheme.label.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          );

          final trailing = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (actions != null && actions!.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: actions!,
                ),
              if (metrics.isNotEmpty) ...[
                SizedBox(height: actions == null || actions!.isEmpty ? 0 : 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map((metric) => _MetricCard(metric: metric))
                      .toList(),
                ),
              ],
            ],
          );

          if (compact) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  const SizedBox(height: 20),
                  trailing,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 10, child: summary),
              const SizedBox(width: 24),
              Expanded(flex: 8, child: trailing),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DesktopSectionMetric metric;

  @override
  Widget build(BuildContext context) {
    final accent = metric.accent ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(metric.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: AppTheme.label.copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.heading.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}