import 'package:flutter/material.dart';

extension ThemeModeLabel on ThemeMode {
  String get russianLabel => switch (this) {
    ThemeMode.system => 'Системная',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
  };
}
