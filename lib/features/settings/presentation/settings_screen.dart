import 'package:dream_cast/app/theme/theme_mode_label.dart';
import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:dream_cast/app/widgets/settings_tile.dart';
import 'package:dream_cast/core/settings/app_settings.dart';
import 'package:dream_cast/core/settings/settings_providers.dart';
import 'package:dream_cast/features/profile/data/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final profile = ref.watch(activeProfileProvider);

    return AppScreen(
      title: 'Настройки',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsTile(
            icon: Icons.person_outline,
            title: 'Профиль',
            subtitle: profile.maybeWhen(
              data: (value) => value?.name ?? 'Профиль не создан',
              orElse: () => 'Загрузка…',
            ),
            onTap: () => context.push('/settings/profile'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Тема',
            subtitle: settings.themeMode.russianLabel,
            onTap: () => _showThemeSheet(context, ref),
          ),
          SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Акцент',
            subtitle: settings.accent.label,
            onTap: () => _showAccentSheet(context, ref),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wallpaper_outlined),
            title: const Text('Цвета системы'),
            subtitle: const Text('Использовать Monet / Material You'),
            value: settings.useDynamicColor,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setUseDynamicColor,
          ),
          const Divider(height: 1),
          const SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Кэш',
            subtitle: 'Сроки хранения релизов, страниц и потоков',
          ),
          const SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Проигрыватель',
            subtitle: 'Основа для Media3, субтитров и прогресса',
          ),
          const SettingsTile(
            icon: Icons.info_outline,
            title: 'О приложении',
            subtitle: 'Dream Cast для Android',
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final selected = ref.read(appSettingsProvider).themeMode;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return ListTile(
                title: Text(mode.russianLabel),
                trailing: selected == mode ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAccentSheet(BuildContext context, WidgetRef ref) {
    final selected = ref.read(appSettingsProvider).accent;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppAccent.values.map((accent) {
              return ListTile(
                title: Text(accent.label),
                leading: CircleAvatar(backgroundColor: accent.seedColor),
                trailing: selected == accent ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setAccent(accent);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
