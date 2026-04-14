import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextScalePreset {
  standard('Default', 1.0, 'Balanced sizing across the current layout'),
  large('Large', 1.1, 'Slightly larger text for day-to-day readability'),
  larger('Larger', 1.2, 'Noticeably larger text with stable spacing'),
  extraLarge('Extra Large', 1.3, 'High readability for dense screens'),
  maximum('Maximum', 1.4, 'Largest supported scale while preserving layout');

  const AppTextScalePreset(this.label, this.scale, this.description);

  final String label;
  final double scale;
  final String description;
}

@immutable
class AppSettingsState {
  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.textScalePreset = AppTextScalePreset.standard,
    this.locale = const Locale('en'),
  });

  final ThemeMode themeMode;
  final AppTextScalePreset textScalePreset;
  final Locale locale;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AppTextScalePreset? textScalePreset,
    Locale? locale,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      textScalePreset: textScalePreset ?? this.textScalePreset,
      locale: locale ?? this.locale,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  static const _themeModeKey = 'app_theme_mode';
  static const _textScaleKey = 'app_text_scale';
  static const _localeKey = 'app_locale';

  bool _didScheduleLoad = false;

  @override
  AppSettingsState build() {
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      Future.microtask(_load);
    }
    return const AppSettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeModeKey);
    final savedScale = prefs.getString(_textScaleKey);
    final savedLocale = prefs.getString(_localeKey);

    state = AppSettingsState(
      themeMode: _themeModeFromString(savedTheme),
      textScalePreset: _textScaleFromString(savedScale),
      locale: savedLocale != null ? Locale(savedLocale) : const Locale('en'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setTextScalePreset(AppTextScalePreset preset) async {
    state = state.copyWith(textScalePreset: preset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textScaleKey, preset.name);
  }

  Future<void> setLocale(Locale loc) async {
    state = state.copyWith(locale: loc);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, loc.languageCode);
  }

  ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  AppTextScalePreset _textScaleFromString(String? value) {
    return AppTextScalePreset.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => AppTextScalePreset.standard,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );
