import 'package:flutter/material.dart';

extension ThemeModeLabel on ThemeMode {
  String get russianLabel => switch (this) {
    ThemeMode.system => 'Как в системе',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
  };
}
