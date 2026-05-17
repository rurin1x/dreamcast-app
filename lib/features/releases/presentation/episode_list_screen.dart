import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            if (data.isStale) const StaleCacheBanner(),
            Expanded(
              child: ListView.separated(
                itemCount: data.value.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final episode = data.value[index];
                  return _EpisodeTile(episode: episode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.episode});

  final DreamEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(episodeStreamsProvider(episode));

    return ListTile(
      leading: CircleAvatar(child: Text('${episode.ordinal}')),
      title: Text(episode.title),
      subtitle: streams.when(
        loading: () => const Text('Проверяем потоки…'),
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Выбор серии работает. Проигрыватель будет следующим этапом.',
            ),
          ),
        );
      },
    );
  }
}
