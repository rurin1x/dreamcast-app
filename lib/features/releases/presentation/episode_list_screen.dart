import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/features/downloads/data/download_providers.dart';
import 'package:dream_cast/features/downloads/data/download_service.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/player/presentation/preferred_stream_launcher.dart';
import 'package:dream_cast/features/player/presentation/stream_selection_sheet.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EpisodeListScreen extends ConsumerStatefulWidget {
  const EpisodeListScreen({required this.detail, super.key});

  final DreamReleaseDetail detail;

  @override
  ConsumerState<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends ConsumerState<EpisodeListScreen> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(releaseEpisodesProvider(widget.detail));
    final downloadsState = ref.watch(downloadedEpisodesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Серии')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(releaseEpisodesProvider(widget.detail)),
        ),
        data: (data) {
          final completedDownloads = downloadsState.value
              ?.where(
                (download) =>
                    download.releaseId == widget.detail.release.id &&
                    download.status == 'completed',
              )
              .map((download) => download.episodeId)
              .toSet();
          final offlineOnly = data.isStale && completedDownloads != null;
          final queue =
              (offlineOnly
                      ? data.value.where(
                          (episode) => completedDownloads.contains(episode.id),
                        )
                      : data.value)
                  .toList()
                ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
          final visible = _ascending ? queue : queue.reversed.toList();

          return Column(
            children: [
              if (data.isStale) const StaleCacheBanner(),
              _EpisodeToolbar(
                ascending: _ascending,
                episodes: queue,
                onSortChanged: (value) => setState(() => _ascending = value),
                onDownloadAll: queue.isEmpty
                    ? null
                    : () => _downloadAllEpisodes(context, queue),
              ),
              Expanded(
                child: visible.isEmpty && offlineOnly
                    ? const _OfflineEpisodesEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          return _EpisodeTile(
                            release: widget.detail.release,
                            episode: visible[index],
                            episodeQueue: queue,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadAllEpisodes(
    BuildContext context,
    List<DreamEpisode> episodes,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Добавляем ${episodes.length} серий в загрузки...'),
      ),
    );

    final requests = <DreamEpisodeDownloadRequest>[];
    for (final episode in episodes) {
      try {
        final streamsData = await ref.read(
          episodeStreamsProvider(episode).future,
        );
        final stream = pickDownloadStream(streamsData.value);
        if (stream == null) continue;
        requests.add(
          DreamEpisodeDownloadRequest(episode: episode, stream: stream),
        );
      } catch (_) {
        // Ошибка одной серии не должна останавливать очередь целиком.
      }
    }

    if (requests.isEmpty) return;
    await ref
        .read(downloadServiceProvider)
        .startBatchDownload(release: widget.detail.release, requests: requests);
  }
}

class _EpisodeToolbar extends StatelessWidget {
  const _EpisodeToolbar({
    required this.ascending,
    required this.episodes,
    required this.onSortChanged,
    required this.onDownloadAll,
  });

  final bool ascending;
  final List<DreamEpisode> episodes;
  final ValueChanged<bool> onSortChanged;
  final VoidCallback? onDownloadAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            '${episodes.length} сер.',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                tooltip: 'По возрастанию',
                icon: Icon(Icons.arrow_downward, size: 18),
              ),
              ButtonSegment(
                value: false,
                tooltip: 'По убыванию',
                icon: Icon(Icons.arrow_upward, size: 18),
              ),
            ],
            selected: {ascending},
            onSelectionChanged: (value) => onSortChanged(value.first),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Скачать все',
            onPressed: onDownloadAll,
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
      ),
    );
  }
}

class _OfflineEpisodesEmptyState extends StatelessWidget {
  const _OfflineEpisodesEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Нет скачанных серий',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Возможно у вас нет доступа к интернету. В офлайн-режиме здесь отображаются только скачанные серии.',
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

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
    required this.release,
    required this.episode,
    required this.episodeQueue,
  });

  final DreamRelease release;
  final DreamEpisode episode;
  final List<DreamEpisode> episodeQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      episodeWatchEntryProvider((release: release, episode: episode)),
    );
    final downloadState = ref.watch(
      downloadedEpisodeStreamProvider((
        releaseId: release.id,
        episodeId: episode.id,
      )),
    );
    final download = downloadState.value;

    return ListTile(
      minVerticalPadding: 10,
      leading: _EpisodeNumberBadge(episode.ordinal),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: progress.when(
          loading: () => const Text('Проверяем прогресс...'),
          error: (error, stackTrace) => const Text('Прогресс не загружен'),
          data: (entry) => _EpisodeSubtitle(progress: _progressLabel(entry)),
        ),
      ),
      trailing: _EpisodeActions(
        download: download,
        onDownload: () => startEpisodeDownload(
          context: context,
          ref: ref,
          release: release,
          episode: episode,
        ),
        onCancelDownload: () => ref
            .read(downloadServiceProvider)
            .cancelDownload(release.id, episode.id),
        onDeleteDownload: () => confirmDeleteDownload(
          context: context,
          ref: ref,
          release: release,
          episode: episode,
        ),
        onPlay: () => playEpisode(
          context: context,
          ref: ref,
          release: release,
          episode: episode,
          episodeQueue: episodeQueue,
        ),
      ),
      onTap: () => playEpisode(
        context: context,
        ref: ref,
        release: release,
        episode: episode,
        episodeQueue: episodeQueue,
      ),
    );
  }

  String _progressLabel(ContinueWatchingItem? entry) {
    if (entry == null) return 'Не просмотрено';
    if (entry.isWatched) return 'Просмотрено';
    return 'Остановились на ${formatEpisodeDuration(entry.position)}';
  }
}

class _EpisodeNumberBadge extends StatelessWidget {
  const _EpisodeNumberBadge(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.secondaryContainer,
      foregroundColor: theme.colorScheme.onSecondaryContainer,
      child: Text(
        '$number',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EpisodeSubtitle extends StatelessWidget {
  const _EpisodeSubtitle({required this.progress});

  final String progress;

  @override
  Widget build(BuildContext context) {
    return Text(progress, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _EpisodeActions extends StatelessWidget {
  const _EpisodeActions({
    required this.download,
    required this.onDownload,
    required this.onCancelDownload,
    required this.onDeleteDownload,
    required this.onPlay,
  });

  final DownloadedEpisode? download;
  final VoidCallback onDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onDeleteDownload;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DownloadActionButton(
          download: download,
          onDownload: onDownload,
          onCancelDownload: onCancelDownload,
          onDeleteDownload: onDeleteDownload,
        ),
        const SizedBox(width: 4),
        IconButton.filled(
          tooltip: 'Смотреть',
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow_rounded),
        ),
      ],
    );
  }
}

class _DownloadActionButton extends StatelessWidget {
  const _DownloadActionButton({
    required this.download,
    required this.onDownload,
    required this.onCancelDownload,
    required this.onDeleteDownload,
  });

  final DownloadedEpisode? download;
  final VoidCallback onDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onDeleteDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = download?.status;

    if (status == 'pending') {
      return const SizedBox.square(
        dimension: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (status == 'downloading') {
      final total = download!.fileSize;
      final value = total > 0 ? download!.downloadedBytes / total : null;
      return IconButton(
        tooltip: 'Отменить загрузку',
        onPressed: onCancelDownload,
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

    if (status == 'completed') {
      return IconButton(
        tooltip: 'Удалить офлайн-копию',
        color: theme.colorScheme.primary,
        onPressed: onDeleteDownload,
        icon: const Icon(Icons.offline_pin_rounded),
      );
    }

    if (status == 'failed') {
      return IconButton(
        tooltip: 'Повторить загрузку',
        color: theme.colorScheme.error,
        onPressed: onDownload,
        icon: const Icon(Icons.error_outline_rounded),
      );
    }

    return IconButton(
      tooltip: 'Скачать',
      onPressed: onDownload,
      icon: const Icon(Icons.download_outlined),
    );
  }
}

Future<void> playEpisode({
  required BuildContext context,
  required WidgetRef ref,
  required DreamRelease release,
  required DreamEpisode episode,
  required List<DreamEpisode> episodeQueue,
}) async {
  final downloaded = await ref
      .read(appDatabaseProvider)
      .downloadedEpisode(release.id, episode.id);

  if (downloaded != null && downloaded.status == 'completed') {
    final localStream = DreamStream(
      id: 'local_${episode.id}',
      releaseId: release.id,
      episodeId: episode.id,
      url: Uri.file(downloaded.localFilePath),
      type: DreamStreamType.hls,
      quality: downloaded.streamQuality,
    );

    if (!context.mounted) return;
    await context.push(
      '/watch',
      extra: PlaybackRequest(
        release: release,
        episode: episode,
        streams: [localStream],
        initialStream: localStream,
        episodeQueue: episodeQueue,
      ),
    );
    invalidatePlaybackProgressForEpisodes(
      ref,
      release: release,
      episodes: {episode, ...episodeQueue},
    );
    return;
  }

  if (!context.mounted) return;
  final openedPreferred = await openPreferredStreamIfConfigured(
    context: context,
    ref: ref,
    release: release,
    episode: episode,
    episodeQueue: episodeQueue,
    loadStreams: () => ref.read(episodeStreamsProvider(episode).future),
  );
  if (openedPreferred || !context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Consumer(
        builder: (context, sheetRef, child) {
          final streams = sheetRef.watch(episodeStreamsProvider(episode));

          return streams.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AppErrorView(
                error: error,
                onRetry: () {
                  Navigator.pop(sheetContext);
                  sheetRef.invalidate(episodeStreamsProvider(episode));
                },
              ),
            ),
            data: (data) {
              if (data.value.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Text('Для этой серии не найдено доступных потоков.'),
                );
              }

              return StreamSelectionSheet(
                release: release,
                episode: episode,
                streams: data.value,
                episodeQueue: episodeQueue,
                isStale: data.isStale,
              );
            },
          );
        },
      ),
    ),
  );
}

Future<void> startEpisodeDownload({
  required BuildContext context,
  required WidgetRef ref,
  required DreamRelease release,
  required DreamEpisode episode,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final streamsData = await ref.read(episodeStreamsProvider(episode).future);
    final hlsStreams = streamsData.value
        .where((stream) => stream.type == DreamStreamType.hls)
        .toList();

    if (hlsStreams.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Для этой серии нет HLS-потока для загрузки.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final qualities = hlsStreams.map((stream) => stream.quality).toSet();
    final selectedQuality = qualities.length <= 1
        ? qualities.first
        : await showDownloadQualitySheet(
            context: context,
            title: 'Скачать серию',
            message: episode.title,
            qualities: qualities.toList(),
          );
    if (selectedQuality == null) return;

    final stream = pickDownloadStream(hlsStreams, selectedQuality);
    if (stream == null) return;

    await ref
        .read(downloadServiceProvider)
        .startDownload(release: release, episode: episode, stream: stream);
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Серия «${episode.title}» добавлена в загрузки.')),
    );
  } catch (error) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Не удалось подготовить загрузку: $error')),
    );
  }
}

Future<void> confirmDeleteDownload({
  required BuildContext context,
  required WidgetRef ref,
  required DreamRelease release,
  required DreamEpisode episode,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Удалить офлайн-копию?'),
      content: Text(
        'Серия «${episode.title}» останется в списке, но файл будет удалён с устройства.',
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
        .deleteDownload(release.id, episode.id);
  }
}

Future<int?> showDownloadQualitySheet({
  required BuildContext context,
  required String title,
  required String message,
  required List<int> qualities,
}) {
  final theme = Theme.of(context);
  final sortedQualities = [...qualities]..sort((a, b) => b.compareTo(a));

  return showModalBottomSheet<int?>(
    context: context,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surfaceContainerHigh,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              message,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final quality in sortedQualities)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text('${quality}p'),
              subtitle: Text(_qualityDescription(quality)),
              onTap: () => Navigator.pop(sheetContext, quality),
            ),
        ],
      ),
    ),
  );
}

DreamStream? pickDownloadStream(List<DreamStream> streams, [int? quality]) {
  final hlsStreams = streams
      .where((stream) => stream.type == DreamStreamType.hls)
      .toList();
  if (hlsStreams.isEmpty) return null;
  if (quality == null) {
    hlsStreams.sort((a, b) => b.quality.compareTo(a.quality));
    return hlsStreams.first;
  }
  hlsStreams.sort((a, b) {
    final distance = (a.quality - quality).abs().compareTo(
      (b.quality - quality).abs(),
    );
    return distance == 0 ? b.quality.compareTo(a.quality) : distance;
  });
  return hlsStreams.first;
}

String _qualityDescription(int quality) {
  if (quality >= 1080) return 'Лучшее качество, больше места';
  if (quality >= 720) return 'Оптимально для телефона';
  return 'Меньше размер файла';
}

String formatEpisodeDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
