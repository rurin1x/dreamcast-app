import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/features/player/data/playback_repository.dart';
import 'package:dream_cast/features/player/domain/playback_position.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playbackRepositoryProvider = Provider<PlaybackRepository>(
  (ref) => PlaybackRepository(ref.watch(appDatabaseProvider)),
);

final continueWatchingProvider = StreamProvider<List<ContinueWatchingItem>>(
  (ref) => ref.watch(playbackRepositoryProvider).watchContinueWatching(),
);

final playbackPositionProvider = FutureProvider.autoDispose
    .family<PlaybackPosition?, ({String releaseId, String episodeId})>(
      (ref, key) => ref
          .watch(playbackRepositoryProvider)
          .getPosition(releaseId: key.releaseId, episodeId: key.episodeId),
    );

final episodeWatchEntryProvider = StreamProvider.autoDispose
    .family<
      ContinueWatchingItem?,
      ({DreamRelease release, DreamEpisode episode})
    >(
      (ref, key) => ref
          .watch(playbackRepositoryProvider)
          .watchEpisodeWatchEntry(release: key.release, episode: key.episode),
    );

void invalidatePlaybackProgressForEpisodes(
  WidgetRef ref, {
  required DreamRelease release,
  required Iterable<DreamEpisode> episodes,
}) {
  ref.invalidate(continueWatchingProvider);
  for (final episode in episodes) {
    ref
      ..invalidate(
        episodeWatchEntryProvider((release: release, episode: episode)),
      )
      ..invalidate(
        playbackPositionProvider((
          releaseId: '${release.id}',
          episodeId: episode.id,
        )),
      );
  }
}
