import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EpisodeListScreen extends ConsumerWidget {
  const EpisodeListScreen({required this.detail, super.key});

  final DreamReleaseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(releaseEpisodesProvider(detail));

    return Scaffold(
      appBar: AppBar(title: const Text('Серии')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(releaseEpisodesProvider(detail)),
        ),
        data: (data) => Column(
          children: [
            _EpisodeDiagnosticsBanner(
              count: data.value.length,
              diagnostics: data.diagnostics,
              isStale: data.isStale,
            ),
            if (data.isStale) const StaleCacheBanner(),
            Expanded(
              child: ListView.separated(
                itemCount: data.value.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final episode = data.value[index];
                  return _EpisodeTile(
                    release: detail.release,
                    episode: episode,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeDiagnosticsBanner extends StatelessWidget {
  const _EpisodeDiagnosticsBanner({
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
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
              maxLines: 8,
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

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.release, required this.episode});

  final DreamRelease release;
  final DreamEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(episodeStreamsProvider(episode));

    return ListTile(
      leading: CircleAvatar(child: Text('${episode.ordinal}')),
      title: Text(episode.title),
      subtitle: streams.when(
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
      trailing: const Icon(Icons.play_arrow),
      onTap: () => _showStreamSelection(context, ref, streams),
    );
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
