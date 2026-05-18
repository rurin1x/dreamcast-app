import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  int _rurin1xTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rurinPhrase =
        _rurin1xClickPhrases[(_rurin1xTapCount ~/ 10).clamp(
          0,
          _rurin1xClickPhrases.length - 1,
        )];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: const Text('Разработчики')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderPanel(theme: theme),
                  const SizedBox(height: 18),
                  _SectionTitle(theme: theme, title: 'Разработчик'),
                  const SizedBox(height: 10),
                  _DeveloperTile(
                    imageAsset: 'assets/developers/rurin1x.jpg',
                    name: 'rurin1x',
                    role: 'Разработка приложения',
                    description: rurinPhrase,
                    icon: Icons.phone_android,
                    onTap: () {
                      setState(() {
                        _rurin1xTapCount = (_rurin1xTapCount + 1).clamp(0, 100);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(theme: theme, title: 'Отдельная благодарность'),
                  const SizedBox(height: 10),
                  const _DeveloperTile(
                    imageAsset: 'assets/developers/vypivshiy.png',
                    name: 'vypivshiy',
                    role: 'Оригинальная реализация парсера',
                    description:
                        'Некоторые идеи парсинга основаны на anicli-api (MIT License).',
                    icon: Icons.code,
                  ),
                  const SizedBox(height: 20),
                  _DreamCastLinksPanel(theme: theme),
                  const SizedBox(height: 14),
                  _NotePanel(theme: theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Фразы для пасхалки rurin1x лежат здесь. Каждая следующая открывается через
// 10 нажатий по карточке: 0-9, 10-19, ... 90-100.
const _rurin1xClickPhrases = [
  'Жми Жми Жми НА МЕНЯ',
  'Ты реально кликаешь на карточку? Больной?',
  'Я кстати мангу еще перевожу',
  'Хватит уже дрочить на мою аватарку',
  'НУ ЖМИ ДАЛЬШЕ ДАВАЙ ДАВАЙ',
  'Да... ты нашел самую бональную пасхалку',
  'У меня день рождения 15 февраля',
  'Я начал сотрудничать с Dream Cast 13 октября 2025 года',
  'Sora Love, Sora Love, Sora Love, SORA LOVE, SORA LOVE ',
  '100! 100! ЭТО КОНЕЦ!!! ТЫ ДОШЕЛ ДО КОНЦА!!',
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.theme, required this.title});

  final ThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dream Cast',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Приложение для просмотра релизов Dream Cast.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.35,
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

class _DeveloperTile extends StatelessWidget {
  const _DeveloperTile({
    required this.imageAsset,
    required this.name,
    required this.role,
    required this.icon,
    this.description,
    this.onTap,
  });

  final String imageAsset;
  final String name;
  final String role;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 34, foregroundImage: AssetImage(imageAsset)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Text(
                          description!,
                          key: ValueKey(description),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DreamCastLinksPanel extends StatelessWidget {
  const _DreamCastLinksPanel({required this.theme});

  final ThemeData theme;

  static const _links = [
    _DreamCastLink(
      title: 'Telegram',
      url: 'https://t.me/dreamercast',
      icon: Icons.send_outlined,
    ),
    _DreamCastLink(
      title: 'Группа в VK',
      url: 'https://vk.com/dreamerscast',
      icon: Icons.groups_outlined,
    ),
    _DreamCastLink(
      title: 'Сайт',
      url: 'https://dreamerscast.com/',
      icon: Icons.language_outlined,
    ),
    _DreamCastLink(
      title: 'YouTube',
      url: 'https://www.youtube.com/@AdminDreamCast',
      icon: Icons.play_circle_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Dream Cast',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final link in _links) _LinkButton(link: link)],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.link});

  final _DreamCastLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                link.icon,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                link.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(link.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть ${link.title}.')),
      );
    }
  }
}

class _DreamCastLink {
  const _DreamCastLink({
    required this.title,
    required this.url,
    required this.icon,
  });

  final String title;
  final String url;
  final IconData icon;
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.favorite_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Спасибо open-source сообществу\nи людям, чьи проекты и идеи\nпомогли при разработке приложения.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
