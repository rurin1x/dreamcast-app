final class PlaybackPosition {
  const PlaybackPosition({
    required this.releaseId,
    required this.episodeId,
    required this.position,
    this.duration,
    required this.updatedAt,
  });

  final String releaseId;
  final String episodeId;
  final Duration position;
  final Duration? duration;
  final DateTime updatedAt;
}
