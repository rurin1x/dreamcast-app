import 'package:flutter/material.dart';

enum AppAccent { system, blue, green, violet, rose }

extension AppAccentLabel on AppAccent {
  String get label => switch (this) {
    AppAccent.system => 'Системный',
    AppAccent.blue => 'Синий',
    AppAccent.green => 'Зелёный',
    AppAccent.violet => 'Фиолетовый',
    AppAccent.rose => 'Розовый',
  };

  Color get seedColor => switch (this) {
    AppAccent.system => const Color(0xFF4966A7),
    AppAccent.blue => const Color(0xFF3569C8),
    AppAccent.green => const Color(0xFF386A20),
    AppAccent.violet => const Color(0xFF6750A4),
    AppAccent.rose => const Color(0xFFB3265B),
  };
}

final class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.accent,
    required this.useDynamicColor,
    required this.onboardingCompleted,
  });

  final ThemeMode themeMode;
  final AppAccent accent;
  final bool useDynamicColor;
  final bool onboardingCompleted;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
    bool? useDynamicColor,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
