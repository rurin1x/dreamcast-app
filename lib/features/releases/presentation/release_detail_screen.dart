import 'package:cached_network_image/cached_network_image.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/downloads/data/download_providers.dart';
import 'package:dream_cast/features/library/data/release_bookmark_providers.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_providers.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/episode_list_screen.dart';
import 'package:dream_cast/features/releases/presentation/release_title_formatter.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/metadata_chip.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_poster.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReleaseDetailScreen extends ConsumerStatefulWidget {
  const ReleaseDetailScreen({required this.release, super.key});

  final DreamRelease release;

  @override
  ConsumerState<ReleaseDetailScreen> createState() =>
      _ReleaseDetailScreenState();
}

class _ReleaseDetailScreenState extends ConsumerState<ReleaseDetailScreen> {
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(releaseDetailProvider(widget.release));

    return Scaffold(
      floatingActionButton: detailState.maybeWhen(
        data: (data) => FloatingActionButton.extended(
          onPressed: () => _showEpisodeList(context, data.value),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Смотреть'),
        ),
        orElse: () => null,
      ),
      body: detailState.when(
        loading: () => _DetailSkeleton(release: widget.release),
        error: (error, stackTrace) => CustomScrollView(
          slivers: [
            _HeaderSliver(release: widget.release),
            SliverFillRemaining(
              child: AppErrorView(
                error: error,
                onRetry: () =>
                    ref.invalidate(releaseDetailProvider(widget.release)),
              ),
            ),
          ],
        ),
        data: (data) {
          final detail = data.value;
          return CustomScrollView(
            slivers: [
              _HeaderSliver(release: widget.release, detail: detail),
              if (data.isStale)
                const SliverToBoxAdapter(child: StaleCacheBanner()),
              SliverToBoxAdapter(
                child: _DetailBody(
                  release: widget.release,
                  detail: detail,
                  expanded: _descriptionExpanded,
                  onToggleDescription: () {
                    setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 104)),
            ],
          );
        },
      ),
    );
  }

  void _showEpisodeList(BuildContext context, DreamReleaseDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EpisodeListSheet(detail: detail),
    );
  }
}

class _HeaderSliver extends StatelessWidget {
  const _HeaderSliver({required this.release, this.detail});

  final DreamRelease release;
  final DreamReleaseDetail? detail;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        detail?.thumbnailUrl ?? release.wallUrl ?? release.posterUrl;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      title: Text(
        detail == null
            ? displayReleaseTitle(release)
            : displayDetailTitle(detail!),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.26),
                colorBlendMode: BlendMode.darken,
              )
            else
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.release,
    required this.detail,
    required this.expanded,
    required this.onToggleDescription,
  });

  final DreamRelease release;
  final DreamReleaseDetail detail;
  final bool expanded;
  final VoidCallback onToggleDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = detail.description ?? release.description;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                child: ReleasePoster(
                  imageUrl: detail.thumbnailUrl ?? release.posterUrl,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDetailTitle(detail),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (release.originalTitle.isNotEmpty &&
                        release.originalTitle !=
                            displayDetailTitle(detail)) ...[
                      const SizedBox(height: 4),
                      Text(
                        release.originalTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (release.currentEpisodes != null)
                          MetadataChip(
                            icon: Icons.video_library_outlined,
                            label: '${release.currentEpisodes} серий',
                          ),
                        if (release.rating != null)
                          MetadataChip(
                            icon: Icons.star_outline,
                            label: release.rating!,
                          ),
                        if (release.year != null)
                          MetadataChip(
                            icon: Icons.calendar_today_outlined,
                            label: '${release.year}',
                          ),
                        if (release.type != null)
                          MetadataChip(
                            icon: Icons.movie_outlined,
                            label: release.type!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _BookmarkStatusButton(release: release)),
              const SizedBox(width: 10),
              _EpisodeNotificationButton(release: release),
            ],
          ),
          if (description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text(
              'Описание',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description!,
              maxLines: expanded ? null : 8,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.36),
            ),
            TextButton(
              onPressed: onToggleDescription,
              child: Text(expanded ? 'Свернуть' : 'Показать полностью'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookmarkStatusButton extends ConsumerWidget {
  const _BookmarkStatusButton({required this.release});

  final DreamRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final releaseId = release.id;
    final status = ref.watch(releaseBookmarkProvider(releaseId));
    final controller = ref.read(releaseBookmarkProvider(releaseId).notifier);
    final label = status?.label ?? 'Добавить в закладки';

    return PopupMenuButton<Object>(
      tooltip: 'Закладки',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        if (value == _BookmarkAction.remove) {
          controller.remove();
        } else if (value is ReleaseBookmarkStatus) {
          controller.setStatus(value, release: release);
        }
      },
      itemBuilder: (context) => [
        for (final value in ReleaseBookmarkStatus.values)
          PopupMenuItem<Object>(
            value: value,
            child: Row(
              children: [
                Icon(
                  status == value ? Icons.check : Icons.bookmark_border,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(value.label),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<Object>(
          value: _BookmarkAction.remove,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 12),
              Text('Удалить'),
            ],
          ),
        ),
      ],
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  status == null ? Icons.bookmark_add_outlined : Icons.bookmark,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BookmarkAction { remove }

class _EpisodeNotificationButton extends ConsumerWidget {
  const _EpisodeNotificationButton({required this.release});

  final DreamRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = ref.watch(
      episodeNotificationSubscriptionProvider(release.id),
    );

    return Tooltip(
      message: enabled ? 'Уведомления включены' : 'Уведомлять о новых сериях',
      child: Material(
        color: enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggle(context, ref, enabled),
          child: SizedBox(
            width: 56,
            height: 50,
            child: Icon(
              enabled
                  ? Icons.notifications_active
                  : Icons.notifications_none_outlined,
              color: enabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(
      episodeNotificationSubscriptionProvider(release.id).notifier,
    );
    if (enabled) {
      await controller.disable();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уведомления о новых сериях выключены.')),
      );
      return;
    }

    final granted = await controller.enable(release);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Уведомления о новых сериях включены.'
              : 'Разрешите уведомления в настройках Android.',
        ),
      ),
    );
  }
}

class _EpisodeListSheet extends ConsumerStatefulWidget {
  const _EpisodeListSheet({required this.detail});

  final DreamReleaseDetail detail;

  @override
  ConsumerState<_EpisodeListSheet> createState() => _EpisodeListSheetState();
}

class _EpisodeListSheetState extends ConsumerState<_EpisodeListSheet> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(releaseEpisodesProvider(widget.detail));
    final downloadsState = ref.watch(downloadedEpisodesStreamProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Серии',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                    selected: {_ascending},
                    onSelectionChanged: (value) {
                      setState(() => _ascending = value.first);
                    },
                  ),
                  const SizedBox(width: 8),
                  state.maybeWhen(
                    data: (data) => IconButton.filledTonal(
                      tooltip: 'Скачать все',
                      onPressed: data.value.isEmpty
                          ? null
                          : () => _downloadAllEpisodes(context, data.value),
                      icon: const Icon(Icons.download_for_offline_outlined),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => AppErrorView(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(releaseEpisodesProvider(widget.detail)),
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
                  final offlineOnly =
                      data.isStale && completedDownloads != null;
                  final queue =
                      (offlineOnly
                              ? data.value.where(
                                  (episode) =>
                                      completedDownloads.contains(episode.id),
                                )
                              : data.value)
                          .toList()
                        ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
                  final visible = _ascending ? queue : queue.reversed.toList();

                  return Column(
                    children: [
                      if (data.isStale) const StaleCacheBanner(),
                      Expanded(
                        child: visible.isEmpty && offlineOnly
                            ? const _OfflineEpisodesEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: visible.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, indent: 72),
                                itemBuilder: (context, index) => _EpisodeRow(
                                  release: widget.detail.release,
                                  episode: visible[index],
                                  episodeQueue: queue,
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

    final downloadService = ref.read(downloadServiceProvider);
    for (final episode in episodes) {
      try {
        final streamsData = await ref.read(
          episodeStreamsProvider(episode).future,
        );
        final stream = pickDownloadStream(streamsData.value);
        if (stream == null) continue;
        await downloadService.startDownload(
          release: widget.detail.release,
          episode: episode,
          stream: stream,
        );
      } catch (_) {
        // Ошибка одной серии не должна останавливать всю очередь.
      }
    }
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

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({
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
          data: (entry) => _EpisodeRowSubtitle(
            progress: _progressLabel(entry),
            download: download,
          ),
        ),
      ),
      trailing: _EpisodeRowActions(
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

class _EpisodeRowSubtitle extends StatelessWidget {
  const _EpisodeRowSubtitle({required this.progress, required this.download});

  final String progress;
  final DownloadedEpisode? download;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = downloadStatusLabel(download);

    return Row(
      children: [
        Flexible(
          child: Text(progress, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (status != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EpisodeRowActions extends StatelessWidget {
  const _EpisodeRowActions({
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
        _EpisodeDownloadButton(
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

class _EpisodeDownloadButton extends StatelessWidget {
  const _EpisodeDownloadButton({
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.release});

  final DreamRelease release;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return CustomScrollView(
      slivers: [
        _HeaderSliver(release: release),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: ReleasePoster(imageUrl: release.posterUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(
                        color: color,
                        height: 22,
                        widthFactor: 0.9,
                      ),
                      const SizedBox(height: 10),
                      _SkeletonBlock(
                        color: color,
                        height: 14,
                        widthFactor: 0.55,
                      ),
                      const SizedBox(height: 22),
                      _SkeletonBlock(color: color, height: 80, widthFactor: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.color,
    required this.height,
    required this.widthFactor,
  });

  final Color color;
  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}
