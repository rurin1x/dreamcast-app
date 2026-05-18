import 'package:dream_cast/app/theme/theme_mode_label.dart';
import 'package:dream_cast/core/settings/app_settings.dart';
import 'package:dream_cast/core/settings/settings_providers.dart';
import 'package:dream_cast/features/profile/data/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _profileController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WelcomePage(onNext: _next),
      _ThemePage(onNext: _next),
      _AccentPage(onNext: _next),
      _ProfilePage(controller: _profileController, onNext: _saveProfileAndNext),
      _PermissionPage(onFinish: _finish),
    ];
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dream Cast',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Шаг ${_page + 1} из ${pages.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: LinearProgressIndicator(
                value: (_page + 1) / pages.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _saveProfileAndNext() async {
    final name = _profileController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя длиной не меньше двух символов.'),
        ),
      );
      return;
    }
    await ref.read(activeProfileProvider.notifier).save(name);
    _next();
  }

  Future<void> _finish() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/home');
  }
}

class _OnboardingPageShell extends StatelessWidget {
  const _OnboardingPageShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 34, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.38,
          ),
        ),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageShell(
      icon: Icons.play_circle_outline_rounded,
      title: 'Настроим приложение',
      message:
          'Приложение будет хранить профиль, прогресс просмотра и личные настройки прямо на устройстве. Сначала выберем внешний вид и подготовим локальный профиль.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SetupChip(icon: Icons.auto_awesome, label: 'Material 3'),
              _SetupChip(icon: Icons.bookmark_outline, label: 'Библиотека'),
              _SetupChip(icon: Icons.history, label: 'Продолжение просмотра'),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Начать настройку'),
          ),
        ],
      ),
    );
  }
}

class _ThemePage extends ConsumerWidget {
  const _ThemePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return _OnboardingPageShell(
      icon: Icons.dark_mode_outlined,
      title: 'Тема интерфейса',
      message:
          'Можно использовать системную тему Android или закрепить светлый либо тёмный режим только для приложения.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: SegmentedButton<ThemeMode>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(64, 52)),
                tapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
              ),
              segments: ThemeMode.values
                  .map(
                    (mode) => ButtonSegment<ThemeMode>(
                      value: mode,
                      label: Text(mode.russianLabel),
                    ),
                  )
                  .toList(),
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  controller.setThemeMode(value.first),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onNext, child: const Text('Продолжить')),
        ],
      ),
    );
  }
}

class _AccentPage extends ConsumerWidget {
  const _AccentPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return _OnboardingPageShell(
      icon: Icons.palette_outlined,
      title: 'Цветовой акцент',
      message:
          'На современных версиях Android приложение может взять цвета из системы. Если нужен постоянный оттенок, выберите его вручную.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Использовать цвета системы'),
            subtitle: const Text('Динамический цвет Android, если он доступен'),
            value: settings.useDynamicColor,
            onChanged: controller.setUseDynamicColor,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppAccent.values.map((accent) {
              final selected = settings.accent == accent;
              return ChoiceChip(
                selected: selected,
                label: Text(accent.label),
                avatar: CircleAvatar(backgroundColor: accent.seedColor),
                onSelected: (_) => controller.setAccent(accent),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onNext, child: const Text('Продолжить')),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _OnboardingPageShell(
      icon: Icons.person_outline,
      title: 'Профиль на устройстве',
      message:
          'Профиль нужен для истории, закладок и продолжения просмотра. Эти данные остаются локально и не требуют входа в аккаунт.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Имя профиля',
              hintText: 'Например rurin1x',
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onNext,
            child: const Text('Сохранить профиль'),
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageShell(
      icon: Icons.privacy_tip_outlined,
      title: 'Данные и доступ',
      message:
          'Для работы нужны только сеть и локальное хранилище. Кэш, история и прогресс просмотра управляются в настройках приложения.',
      child: Column(
        children: [
          const _PermissionItem(
            icon: Icons.wifi_rounded,
            title: 'Сеть',
            subtitle: 'Загрузка релизов, страниц, постеров и видеопотоков.',
          ),
          const SizedBox(height: 10),
          const _PermissionItem(
            icon: Icons.storage_rounded,
            title: 'Локальное хранилище',
            subtitle: 'Кэш, профиль, закладки и продолжение просмотра.',
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check),
              label: const Text('Готово'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupChip extends StatelessWidget {
  const _SetupChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
