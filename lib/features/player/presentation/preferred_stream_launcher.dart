import 'package:dream_cast/features/player/data/stream_preference_providers.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the player immediately when the user has selected HLS/DASH as the
/// default stream technology. If the preferred stream is unavailable, the
/// caller should fall back to the manual selection sheet.
Future<bool> openPreferredStreamIfConfigured({
  required BuildContext context,
  required WidgetRef ref,
  required DreamRelease release,
  required DreamEpisode episode,
  required List<DreamEpisode> episodeQueue,
  required Future<DreamData<List<DreamStream>>> Function() loadStreams,
}) async {
  final preference = ref.read(preferredStreamTechnologyProvider);
  final preferredType = streamTypeFromTechnology(preference);
  if (preferredType == null) return false;

  final DreamData<List<DreamStream>> data;
  try {
    data = await loadStreams();
  } catch (_) {
    return false;
  }
  final stream = _firstStreamOfType(data.value, preferredType);
  if (stream == null) return false;
  if (!context.mounted) return true;

  await context.push(
    '/watch',
    extra: PlaybackRequest(
      release: release,
      episode: episode,
      streams: data.value,
      initialStream: stream,
      episodeQueue: episodeQueue,
    ),
  );
  invalidatePlaybackProgressForEpisodes(
    ref,
    release: release,
    episodes: {episode, ...episodeQueue},
  );
  return true;
}

DreamStream? _firstStreamOfType(
  List<DreamStream> streams,
  DreamStreamType type,
) {
  for (final stream in streams) {
    if (stream.type == type) return stream;
  }
  return null;
}
