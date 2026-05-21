import 'package:dream_cast/core/cache/cache_providers.dart';
import 'package:dream_cast/core/cache/cache_retention.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/downloads/data/download_providers.dart';
import 'package:dream_cast/features/settings/data/cache_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheSettingsScreen extends ConsumerWidget {
  const CacheSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Кэш и загрузки'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Сетевой кэш'),
              Tab(text: 'Офлайн-серии'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_NetworkCacheTab(), _DownloadedEpisodesTab()],
        ),
      ),
    );
  }
}

class _NetworkCacheTab extends ConsumerWidget {
  const _NetworkCacheTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cacheStatsProvider);
    final retention = ref.watch(cacheRetentionProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cacheStatsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            onPressed: stats.isLoading ? null : () => _clearCache(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Очистить сетевой кэш'),
          ),
          const SizedBox(height: 8),
          Text(
            'Сетевой кэш хранит списки релизов, страницы тайтлов, расписание и извлечённые потоки. История просмотра, закладки и скачанные серии не удаляются.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
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
}

class _DownloadedEpisodesTab extends ConsumerWidget {
  const _DownloadedEpisodesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsState = ref.watch(downloadedEpisodesStreamProvider);

    return downloadsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _DownloadsError(error: error),
      data: (downloads) {
        if (downloads.isEmpty) return const _EmptyDownloads();

        final totalSize = downloads
            .where((episode) => episode.status == 'completed')
            .fold<int>(0, (sum, episode) => sum + episode.fileSize);
        final completedCount = downloads
            .where((episode) => episode.status == 'completed')
            .length;
        final groups = _groupDownloads(downloads);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _DownloadsSummary(
              totalCount: downloads.length,
              completedCount: completedCount,
              totalSize: totalSize,
            ),
            const SizedBox(height: 16),
            for (final group in groups) ...[
              _DownloadGroupCard(group: group),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => _confirmDeleteAll(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Очистить офлайн-серии'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все офлайн-серии?'),
        content: const Text(
          'Файлы будут удалены с устройства. Закладки и история просмотра останутся на месте.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(downloadServiceProvider).deleteAllDownloads();
    }
  }
}

class _DownloadsSummary extends StatelessWidget {
  const _DownloadsSummary({
    required this.totalCount,
    required this.completedCount,
    required this.totalSize,
  });

  final int totalCount;
  final int completedCount;
  final int totalSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.offline_pin_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Офлайн-серии',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedCount из $totalCount готово',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.74,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatBytes(totalSize),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadGroupCard extends ConsumerWidget {
  const _DownloadGroupCard({required this.group});

  final _ReleaseGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupSize = group.episodes
        .where((episode) => episode.status == 'completed')
        .fold<int>(0, (sum, episode) => sum + episode.fileSize);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: _DownloadPoster(url: group.posterUrl),
        title: Text(
          group.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${group.episodes.length} сер. • ${_formatBytes(groupSize)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Удалить серии тайтла',
          onPressed: () => _confirmDeleteGroup(context, ref, group),
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        children: [
          for (final episode in group.episodes)
            _DownloadedEpisodeTile(episode: episode),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    WidgetRef ref,
    _ReleaseGroup group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить серии тайтла?'),
        content: Text(
          'Будет удалено серий: ${group.episodes.length}. Файлы исчезнут только с устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(downloadServiceProvider);
      for (final episode in group.episodes) {
        await service.deleteDownload(episode.releaseId, episode.episodeId);
      }
    }
  }
}

class _DownloadedEpisodeTile extends ConsumerWidget {
  const _DownloadedEpisodeTile({required this.episode});

  final DownloadedEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = _downloadStatusLabel(episode.status);

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        child: Text(
          '${episode.episodeOrdinal}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        episode.episodeTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          status,
          '${episode.streamQuality}p',
          if (episode.status == 'completed') _formatBytes(episode.fileSize),
          if (episode.status == 'downloading')
            'Загружено: ${episode.downloadedBytes}/${episode.fileSize}',
        ].join(' • '),
      ),
      trailing: _DownloadedEpisodeAction(episode: episode),
    );
  }
}

class _DownloadedEpisodeAction extends ConsumerWidget {
  const _DownloadedEpisodeAction({required this.episode});

  final DownloadedEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (episode.status == 'pending' || episode.status == 'downloading') {
      final value = episode.fileSize > 0
          ? episode.downloadedBytes / episode.fileSize
          : null;
      return IconButton(
        tooltip: 'Отменить загрузку',
        onPressed: () => ref
            .read(downloadServiceProvider)
            .cancelDownload(episode.releaseId, episode.episodeId),
        icon: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(value: value, strokeWidth: 2.4),
            ),
            const Icon(Icons.close_rounded, size: 16),
          ],
        ),
      );
    }

    return IconButton(
      tooltip: 'Удалить файл',
      onPressed: () => _confirmDeleteEpisode(context, ref, episode),
      icon: const Icon(Icons.delete_outline),
    );
  }

  Future<void> _confirmDeleteEpisode(
    BuildContext context,
    WidgetRef ref,
    DownloadedEpisode episode,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить офлайн-серию?'),
        content: Text(
          'Файл серии «${episode.episodeTitle}» будет удалён с устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(downloadServiceProvider)
          .deleteDownload(episode.releaseId, episode.episodeId);
    }
  }
}

class _DownloadPoster extends StatelessWidget {
  const _DownloadPoster({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (url == null || url!.isEmpty) {
      return _PosterFallback(color: theme.colorScheme.surfaceContainerHighest);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 42,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _PosterFallback(color: theme.colorScheme.surfaceContainerHighest),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 58,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.movie_outlined, size: 20),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.46),
            ),
            const SizedBox(height: 16),
            Text(
              'Пока ничего не скачано',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Скачанные серии появятся здесь. Их можно будет удалить по одной, по тайтлу или очистить всё сразу.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadsError extends StatelessWidget {
  const _DownloadsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Не удалось открыть список загрузок: $error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
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

class _ReleaseGroup {
  _ReleaseGroup({
    required this.releaseId,
    required this.title,
    required this.posterUrl,
    required this.episodes,
  });

  final int releaseId;
  final String title;
  final String? posterUrl;
  final List<DownloadedEpisode> episodes;
}

List<_ReleaseGroup> _groupDownloads(List<DownloadedEpisode> downloads) {
  final groups = <int, _ReleaseGroup>{};
  for (final episode in downloads) {
    final group = groups.putIfAbsent(
      episode.releaseId,
      () => _ReleaseGroup(
        releaseId: episode.releaseId,
        title: episode.releaseTitle,
        posterUrl: episode.posterUrl,
        episodes: [],
      ),
    );
    group.episodes.add(episode);
  }

  for (final group in groups.values) {
    group.episodes.sort((a, b) => a.episodeOrdinal.compareTo(b.episodeOrdinal));
  }

  return groups.values.toList()..sort((a, b) => a.title.compareTo(b.title));
}

String _downloadStatusLabel(String status) {
  return switch (status) {
    'pending' => 'В очереди',
    'downloading' => 'Загрузка',
    'completed' => 'Готово',
    'failed' => 'Ошибка',
    _ => 'Неизвестно',
  };
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} КБ';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} МБ';
  return '${(mb / 1024).toStringAsFixed(1)} ГБ';
}
