import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appearance, style: AppTheme.heading),
                const SizedBox(height: 8),
                Text(
                  l.appearanceDescription,
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(l.systemTheme),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(l.lightTheme),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(l.darkTheme),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    notifier.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.languageLabel, style: AppTheme.heading),
                const SizedBox(height: 8),
                Text(
                  l.languageDescription,
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<String>(value: 'en', label: Text('English')),
                    ButtonSegment<String>(value: 'hi', label: Text('हिंदी')),
                    ButtonSegment<String>(value: 'bn', label: Text('বাংলা')),
                  ],
                  selected: {settings.locale.languageCode},
                  onSelectionChanged: (selection) {
                    notifier.setLocale(Locale(selection.first));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.textSize, style: AppTheme.heading),
                const SizedBox(height: 8),
                Text(
                  l.textSizeDescription,
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ...AppTextScalePreset.values.map((preset) {
                  final isSelected = settings.textScalePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => notifier.setTextScalePreset(preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : AppTheme.textSecondary.withValues(
                                    alpha: 0.15,
                                  ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${preset.label} (${(preset.scale * 100).round()}%)',
                                    style: AppTheme.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preset.description,
                                    style: AppTheme.label.copyWith(
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.preview,
                        style: AppTheme.label.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(l.previewHeading, style: AppTheme.heading),
                      const SizedBox(height: 4),
                      Text(
                        l.previewBody,
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
