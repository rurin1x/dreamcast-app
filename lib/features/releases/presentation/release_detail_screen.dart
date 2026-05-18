import 'package:cached_network_image/cached_network_image.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/library/data/release_bookmark_providers.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_providers.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/player/presentation/preferred_stream_launcher.dart';
import 'package:dream_cast/features/player/presentation/stream_selection_sheet.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
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
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Серии',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.arrow_downward),
                        label: Text('1...'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.arrow_upward),
                        label: Text('...1'),
                      ),
                    ],
                    selected: {_ascending},
                    onSelectionChanged: (value) {
                      setState(() => _ascending = value.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => AppErrorView(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(releaseEpisodesProvider(widget.detail)),
                  ),
                  data: (data) {
                    final queue = [...data.value]
                      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
                    final visible = _ascending
                        ? queue
                        : queue.reversed.toList();

                    return Column(
                      children: [
                        if (data.isStale) const StaleCacheBanner(),
                        Expanded(
                          child: ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${episode.ordinal}')),
      title: Text(episode.title),
      subtitle: progress.when(
        loading: () => const Text('Проверяем прогресс...'),
        error: (error, stackTrace) => const Text('Прогресс не загружен'),
        data: (entry) => Text(_progressLabel(entry)),
      ),
      trailing: const Icon(Icons.play_arrow),
      onTap: () => _showStreams(context, ref),
    );
  }

  String _progressLabel(ContinueWatchingItem? entry) {
    if (entry == null) return 'Не просмотрено';
    if (entry.isWatched) return 'Просмотрено';
    return 'Остановились на ${_formatDuration(entry.position)}';
  }

  Future<void> _showStreams(BuildContext context, WidgetRef ref) async {
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
      builder: (context) => _EpisodeStreamsSheet(
        release: release,
        episode: episode,
        episodeQueue: episodeQueue,
      ),
    );
  }
}

class _EpisodeStreamsSheet extends ConsumerWidget {
  const _EpisodeStreamsSheet({
    required this.release,
    required this.episode,
    required this.episodeQueue,
  });

  final DreamRelease release;
  final DreamEpisode episode;
  final List<DreamEpisode> episodeQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(episodeStreamsProvider(episode));

    return SafeArea(
      child: streams.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => AppErrorView(error: error),
        data: (data) => StreamSelectionSheet(
          release: release,
          episode: episode,
          streams: data.value,
          episodeQueue: episodeQueue,
          isStale: data.isStale,
        ),
      ),
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

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
