import 'package:dream_cast/app/theme/theme_mode_label.dart';
import 'package:dream_cast/core/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme and accent labels are Russian', () {
    expect(ThemeMode.system.russianLabel, 'Как в системе');
    expect(ThemeMode.light.russianLabel, 'Светлая');
    expect(ThemeMode.dark.russianLabel, 'Тёмная');
    expect(AppAccent.system.label, 'Системный');
  });
}
