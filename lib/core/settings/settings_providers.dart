import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/core/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

final class AppSettingsController extends Notifier<AppSettings> {
  static const _themeModeKey = 'settings.theme_mode';
  static const _accentKey = 'settings.accent';
  static const _dynamicColorKey = 'settings.dynamic_color';
  static const _onboardingKey = 'settings.onboarding_completed';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    return AppSettings(
      themeMode: _themeModeFromString(prefs.getString(_themeModeKey)),
      accent: _accentFromString(prefs.getString(_accentKey)),
      useDynamicColor: prefs.getBool(_dynamicColorKey) ?? true,
      onboardingCompleted: prefs.getBool(_onboardingKey) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAccent(AppAccent accent) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_accentKey, accent.name);
    state = state.copyWith(accent: accent);
  }

  Future<void> setUseDynamicColor(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(_dynamicColorKey, value);
    state = state.copyWith(useDynamicColor: value);
  }

  Future<void> completeOnboarding() async {
    await ref.read(sharedPreferencesProvider).setBool(_onboardingKey, true);
    state = state.copyWith(onboardingCompleted: true);
  }

  static ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  static AppAccent _accentFromString(String? value) {
    return AppAccent.values.firstWhere(
      (accent) => accent.name == value,
      orElse: () => AppAccent.system,
    );
  }
}
