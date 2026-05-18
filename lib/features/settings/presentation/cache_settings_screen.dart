import 'package:dream_cast/core/cache/cache_providers.dart';
import 'package:dream_cast/core/cache/cache_retention.dart';
import 'package:dream_cast/features/settings/data/cache_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheSettingsScreen extends ConsumerWidget {
  const CacheSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cacheStatsProvider);
    final retention = ref.watch(cacheRetentionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Кэш')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Material(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: stats.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Text(
                    'Не удалось прочитать кэш: $error',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  data: (value) => Column(
                    children: [
                      _CacheMetric(
                        icon: Icons.storage_outlined,
                        title: 'Занято',
                        value: _formatBytes(value.approximateBytes),
                      ),
                      const Divider(height: 22),
                      _CacheMetric(
                        icon: Icons.inventory_2_outlined,
                        title: 'Записей',
                        value: '${value.entriesCount}',
                      ),
                      const Divider(height: 22),
                      _CacheMetric(
                        icon: Icons.schedule_outlined,
                        title: 'Срок хранения',
                        value: retention.label,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.event_repeat_outlined),
                title: const Text('Срок хранения'),
                subtitle: Text(retention.label),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _showRetentionSheet(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: stats.isLoading
                  ? null
                  : () => _clearCache(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Очистить кэш'),
            ),
            const SizedBox(height: 8),
            Text(
              'Кэш хранит списки релизов, страницы тайтлов, расписание и извлечённые потоки. История просмотра и закладки не удаляются.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final removed = await ref.read(cacheRepositoryProvider).clearAll();
    ref.invalidate(cacheStatsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Кэш очищен. Удалено записей: $removed')),
    );
  }

  void _showRetentionSheet(BuildContext context, WidgetRef ref) {
    final selected = ref.read(cacheRetentionProvider);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Срок хранения кэша',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final option in CacheRetentionOption.values)
              ListTile(
                title: Text(option.label),
                subtitle: Text(option.description),
                trailing: selected == option ? const Icon(Icons.check) : null,
                onTap: () async {
                  await ref
                      .read(cacheRetentionProvider.notifier)
                      .setRetention(option);
                  await ref
                      .read(cacheRepositoryProvider)
                      .applyCurrentRetentionToExistingEntries();
                  ref.invalidate(cacheStatsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final refreshed = ref.refresh(cacheStatsProvider.future);
    await refreshed;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} КБ';
    return '${(kb / 1024).toStringAsFixed(1)} МБ';
  }
}

class _CacheMetric extends StatelessWidget {
  const _CacheMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
