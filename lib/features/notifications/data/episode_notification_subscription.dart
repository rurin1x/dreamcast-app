import 'package:dream_cast/features/releases/domain/release.dart';

final class EpisodeNotificationSubscription {
  const EpisodeNotificationSubscription({
    required this.release,
    required this.lastKnownEpisodes,
    required this.updatedAt,
  });

  final DreamRelease release;
  final int lastKnownEpisodes;
  final DateTime updatedAt;

  EpisodeNotificationSubscription copyWith({
    DreamRelease? release,
    int? lastKnownEpisodes,
    DateTime? updatedAt,
  }) {
    return EpisodeNotificationSubscription(
      release: release ?? this.release,
      lastKnownEpisodes: lastKnownEpisodes ?? this.lastKnownEpisodes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

int knownEpisodeCount(DreamRelease release) {
  return release.currentEpisodes ?? release.totalEpisodes ?? 0;
}
