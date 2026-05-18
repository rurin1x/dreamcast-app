import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Серии')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(releaseEpisodesProvider(widget.detail)),
        ),
        data: (data) => Column(
          children: [
            if (data.isStale) const StaleCacheBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('По возрастанию')),
                    ButtonSegment(value: false, label: Text('По убыванию')),
                  ],
                  selected: {_ascending},
                  onSelectionChanged: (value) {
                    setState(() => _ascending = value.first);
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _visibleEpisodes(data.value).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final queue = [...data.value]
                    ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
                  final episode = _ascending
                      ? queue[index]
                      : queue.reversed.toList()[index];
                  return _EpisodeTile(
                    release: widget.detail.release,
                    episode: episode,
                    episodeQueue: queue,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DreamEpisode> _visibleEpisodes(List<DreamEpisode> episodes) {
    final queue = [...episodes]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return _ascending ? queue : queue.reversed.toList();
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
    final streams = ref.watch(episodeStreamsProvider(episode));
    final progress = ref.watch(
      episodeWatchEntryProvider((release: release, episode: episode)),
    );

    return ListTile(
      leading: CircleAvatar(child: Text('${episode.ordinal}')),
      title: Text(episode.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          progress.when(
            loading: () => const Text('Проверяем прогресс...'),
            error: (error, stackTrace) => const Text('Прогресс не загружен'),
            data: (entry) => Text(_progressLabel(entry)),
          ),
          streams.when(
            loading: () => const Text('Проверяем доступные потоки...'),
            error: (error, stackTrace) => const Text('Потоки не найдены'),
            data: (data) => Text(
              [
                '${data.value.length} потоков',
                if (data.value.isNotEmpty) '${data.value.first.quality}p',
                if (data.isStale) 'из кэша',
              ].join(' • '),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.play_arrow),
      onTap: () => _showStreamSelection(context, ref, streams),
    );
  }

  String _progressLabel(ContinueWatchingItem? entry) {
    if (entry == null) return 'Не просмотрено';
    if (entry.isWatched) return 'Просмотрено';
    return 'Остановились на ${_formatDuration(entry.position)}';
  }

  void _showStreamSelection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DreamData<List<DreamStream>>> streams,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: streams.when(
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
                ref.invalidate(episodeStreamsProvider(episode));
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

            return ListView(
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
                      Navigator.pop(sheetContext);
                      context.push(
                        '/watch',
                        extra: PlaybackRequest(
                          release: release,
                          episode: episode,
                          streams: data.value,
                          initialStream: stream,
                          episodeQueue: episodeQueue,
                        ),
                      );
                    },
                  ),
              ],
            );
          },
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

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
