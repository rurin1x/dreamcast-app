import 'package:cached_network_image/cached_network_image.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/metadata_chip.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_poster.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          final episodesState = ref.watch(releaseEpisodesProvider(detail));

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
              SliverToBoxAdapter(
                child: _EpisodePreview(detail: detail, state: episodesState),
              ),
            ],
          );
        },
      ),
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
        detail?.title ?? release.title,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
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
                  detail.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (release.originalTitle.isNotEmpty &&
                    release.originalTitle != detail.title) ...[
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
                if ((detail.description ?? release.description)
                        ?.trim()
                        .isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 14),
                  Text(
                    detail.description ?? release.description!,
                    maxLines: expanded ? null : 5,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.32),
                  ),
                  TextButton(
                    onPressed: onToggleDescription,
                    child: Text(expanded ? 'Свернуть' : 'Показать полностью'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodePreview extends StatelessWidget {
  const _EpisodePreview({required this.detail, required this.state});

  final DreamReleaseDetail detail;
  final AsyncValue<DreamData<List<DreamEpisode>>> state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Серии',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: state.hasValue
                    ? () => context.push('/episodes', extra: detail)
                    : null,
                child: const Text('Все серии'),
              ),
            ],
          ),
          state.when(
            loading: () => const _EpisodePreviewSkeleton(),
            error: (error, stackTrace) => AppErrorView(error: error),
            data: (data) {
              final episodes = data.value.take(6).toList();
              return Column(
                children: [
                  _EpisodeDecodeDiagnostics(
                    count: data.value.length,
                    diagnostics: data.diagnostics,
                    isStale: data.isStale,
                  ),
                  if (data.isStale) const StaleCacheBanner(),
                  for (final episode in episodes)
                    _EpisodeRow(
                      episode: episode,
                      onTap: () => _showStreams(context, episode),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStreams(BuildContext context, DreamEpisode episode) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _EpisodeStreamsSheet(release: detail.release, episode: episode),
    );
  }
}

class _EpisodeDecodeDiagnostics extends StatelessWidget {
  const _EpisodeDecodeDiagnostics({
    required this.count,
    required this.diagnostics,
    required this.isStale,
  });

  final int count;
  final String? diagnostics;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = diagnostics?.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Декодировано серий: $count${isStale ? ' • из кэша' : ''}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview != null && preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.onTap});

  final DreamEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${episode.ordinal}')),
      title: Text(episode.title),
      subtitle: const Text(
        'Прогресс просмотра появится после подключения проигрывателя',
      ),
      trailing: const Icon(Icons.play_arrow),
      onTap: onTap,
    );
  }
}

class _EpisodeStreamsSheet extends ConsumerWidget {
  const _EpisodeStreamsSheet({required this.release, required this.episode});

  final DreamRelease release;
  final DreamEpisode episode;

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
        data: (data) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              episode.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (data.isStale) const StaleCacheBanner(),
            for (final stream in data.value)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(
                  '${_streamTypeLabel(stream.type)} • ${stream.quality}p',
                ),
                subtitle: Text(
                  stream.url.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/watch',
                    extra: PlaybackRequest(
                      release: release,
                      episode: episode,
                      streams: data.value,
                      initialStream: stream,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _streamTypeLabel(DreamStreamType type) {
    return switch (type) {
      DreamStreamType.hls => 'HLS',
      DreamStreamType.dash => 'DASH',
      DreamStreamType.mp4 => 'MP4',
      DreamStreamType.webm => 'WebM',
      DreamStreamType.audio => 'Аудио',
      DreamStreamType.unknown => 'Поток',
    };
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

class _EpisodePreviewSkeleton extends StatelessWidget {
  const _EpisodePreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _SkeletonBlock(color: color, height: 46, widthFactor: 1),
        ),
      ),
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
