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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Dream Cast',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1}/${pages.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: LinearProgressIndicator(
                value: (_page + 1) / pages.length,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
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
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(icon, size: 30),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
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
      icon: Icons.play_circle_outline,
      title: 'Добро пожаловать',
      message:
          'Клиент для релизов Dream Cast с аккуратным интерфейсом, быстрым доступом к сериям и подготовкой к удобному просмотру.',
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Начать настройку'),
        ),
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
      title: 'Выберите тему',
      message:
          'Приложение может следовать системной теме Android или использовать выбранный режим постоянно.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ThemeMode>(
            segments: ThemeMode.values
                .map(
                  (mode) => ButtonSegment<ThemeMode>(
                    value: mode,
                    label: Text(mode.russianLabel),
                  ),
                )
                .toList(),
            selected: {settings.themeMode},
            onSelectionChanged: (value) => controller.setThemeMode(value.first),
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
      title: 'Акцент приложения',
      message:
          'На современных Android можно взять цвет из обоев. Если хочется постоянный оттенок, выберите его здесь.',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Использовать цвета системы'),
            subtitle: const Text('Monet / Material You, если доступно'),
            value: settings.useDynamicColor,
            onChanged: controller.setUseDynamicColor,
          ),
          const SizedBox(height: 8),
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
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Продолжить'),
            ),
          ),
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
    return _OnboardingPageShell(
      icon: Icons.person_outline,
      title: 'Локальный профиль',
      message:
          'Профиль хранится только на устройстве. Он нужен для истории, продолжения просмотра и личных настроек.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Имя профиля',
              hintText: 'Например, Иван',
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
      title: 'Разрешения и данные',
      message:
          'На старте приложению нужен только доступ к сети. Кэш, история и прогресс просмотра сохраняются локально и управляются в настройках.',
      child: Column(
        children: [
          const _PermissionItem(
            icon: Icons.wifi,
            title: 'Сеть',
            subtitle: 'Для загрузки релизов, страниц и потоков.',
          ),
          const _PermissionItem(
            icon: Icons.storage,
            title: 'Локальное хранилище',
            subtitle: 'Для кэша, профиля и продолжения просмотра.',
          ),
          const _PermissionItem(
            icon: Icons.subtitles_outlined,
            title: 'Субтитры',
            subtitle: 'Архитектура уже готова к подключению дорожек позже.',
          ),
          const SizedBox(height: 20),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
