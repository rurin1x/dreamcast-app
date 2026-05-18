import 'package:dream_cast/features/releases/domain/release.dart';

final class PlaybackRequest {
  const PlaybackRequest({
    required this.release,
    required this.episode,
    required this.streams,
    required this.initialStream,
    this.episodeQueue = const [],
  });

  final DreamRelease release;
  final DreamEpisode episode;
  final List<DreamStream> streams;
  final DreamStream initialStream;
  final List<DreamEpisode> episodeQueue;
}

final class ContinueWatchingItem {
  const ContinueWatchingItem({
    required this.releaseId,
    required this.episodeId,
    required this.releaseTitle,
    required this.episodeTitle,
    required this.episodeOrdinal,
    required this.position,
    required this.duration,
    required this.updatedAt,
    this.posterUrl,
    required this.isWatched,
  });

  final String releaseId;
  final String episodeId;
  final String releaseTitle;
  final String episodeTitle;
  final int episodeOrdinal;
  final Duration position;
  final Duration? duration;
  final DateTime updatedAt;
  final String? posterUrl;
  final bool isWatched;

  double? get progress {
    final durationMs = duration?.inMilliseconds;
    if (durationMs == null || durationMs <= 0) return null;
    return (position.inMilliseconds / durationMs).clamp(0, 1).toDouble();
  }
}
