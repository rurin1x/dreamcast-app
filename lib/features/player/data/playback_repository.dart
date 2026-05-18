import 'dart:convert';

import 'package:dream_cast/core/database/app_database.dart'
    hide PlaybackPosition, StreamSession;
import 'package:dream_cast/features/player/domain/playback_position.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/player/domain/stream_session.dart';
import 'package:dream_cast/features/player/domain/video_stream.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:drift/drift.dart';

final class PlaybackRepository {
  const PlaybackRepository(this._database);

  final AppDatabase _database;

  Future<void> savePosition(PlaybackPosition position) {
    return _database.savePlaybackPosition(
      PlaybackPositionsCompanion(
        releaseId: Value(position.releaseId),
        episodeId: Value(position.episodeId),
        positionMs: Value(position.position.inMilliseconds),
        durationMs: Value(position.duration?.inMilliseconds),
        updatedAt: Value(position.updatedAt),
      ),
    );
  }

  Future<PlaybackPosition?> getPosition({
    required String releaseId,
    required String episodeId,
  }) async {
    final row = await _database.playbackPosition(releaseId, episodeId);
    if (row == null) return null;
    return PlaybackPosition(
      releaseId: row.releaseId,
      episodeId: row.episodeId,
      position: Duration(milliseconds: row.positionMs),
      duration: row.durationMs == null
          ? null
          : Duration(milliseconds: row.durationMs!),
      updatedAt: row.updatedAt,
    );
  }

  Future<ContinueWatchingItem?> getEpisodeWatchEntry({
    required DreamRelease release,
    required DreamEpisode episode,
  }) async {
    final row = await _database.watchEntry('${release.id}', episode.id);
    if (row == null) return null;
    return ContinueWatchingItem(
      releaseId: row.releaseId,
      episodeId: row.episodeId,
      releaseTitle: row.releaseTitle,
      episodeTitle: row.episodeTitle,
      episodeOrdinal: row.episodeOrdinal,
      position: Duration(milliseconds: row.positionMs),
      duration: row.durationMs == null
          ? null
          : Duration(milliseconds: row.durationMs!),
      updatedAt: row.updatedAt,
      posterUrl: row.posterUrl,
      isWatched: row.isWatched,
    );
  }

  Future<void> saveWatchProgress({
    required DreamRelease release,
    required DreamEpisode episode,
    required Duration position,
    required Duration? duration,
  }) async {
    final durationMs = duration?.inMilliseconds;
    final positionMs = position.inMilliseconds;
    final isWatched =
        durationMs != null && durationMs > 0 && positionMs / durationMs >= 0.9;
    final now = DateTime.now();

    await savePosition(
      PlaybackPosition(
        releaseId: '${release.id}',
        episodeId: episode.id,
        position: position,
        duration: duration,
        updatedAt: now,
      ),
    );

    await _database.upsertWatchEntry(
      WatchEntriesCompanion(
        releaseId: Value('${release.id}'),
        episodeId: Value(episode.id),
        releaseTitle: Value(release.title),
        episodeTitle: Value(episode.title),
        posterUrl: Value(release.posterUrl),
        episodeOrdinal: Value(episode.ordinal),
        positionMs: Value(positionMs),
        durationMs: Value(durationMs),
        isWatched: Value(isWatched),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> saveDreamStreamSession({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
  }) {
    return _database.saveStreamSession(
      StreamSessionsCompanion(
        id: Value(stream.id),
        releaseId: Value('${release.id}'),
        episodeId: Value(episode.id),
        url: Value(stream.url.toString()),
        type: Value(stream.type.name),
        quality: Value(stream.quality),
        headersJson: Value(jsonEncode(stream.headers)),
        createdAt: Value(DateTime.now()),
        expiresAt: Value(stream.expiresAt),
      ),
    );
  }

  Stream<List<ContinueWatchingItem>> watchContinueWatching() {
    return _database.watchRecentEntries().map(
      (rows) => rows
          .where((row) => !row.isWatched)
          .map(
            (row) => ContinueWatchingItem(
              releaseId: row.releaseId,
              episodeId: row.episodeId,
              releaseTitle: row.releaseTitle,
              episodeTitle: row.episodeTitle,
              episodeOrdinal: row.episodeOrdinal,
              position: Duration(milliseconds: row.positionMs),
              duration: row.durationMs == null
                  ? null
                  : Duration(milliseconds: row.durationMs!),
              updatedAt: row.updatedAt,
              posterUrl: row.posterUrl,
              isWatched: row.isWatched,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<PlaybackRequest?> restorePlaybackRequest(
    ContinueWatchingItem item,
  ) async {
    final row = await _database.latestStreamSession(
      item.releaseId,
      item.episodeId,
    );
    if (row == null) return null;

    final release = DreamRelease(
      id: int.tryParse(item.releaseId) ?? 0,
      title: item.releaseTitle,
      originalTitle: '',
      url: '',
      posterUrl: item.posterUrl,
    );
    final episode = DreamEpisode(
      id: item.episodeId,
      releaseId: release.id,
      ordinal: item.episodeOrdinal,
      title: item.episodeTitle,
      file: row.url,
    );
    final stream = DreamStream(
      id: row.id,
      releaseId: release.id,
      episodeId: item.episodeId,
      url: Uri.parse(row.url),
      type: _dreamStreamTypeFromName(row.type),
      quality: row.quality,
      headers: _decodeHeaders(row.headersJson),
      expiresAt: row.expiresAt,
    );

    return PlaybackRequest(
      release: release,
      episode: episode,
      streams: [stream],
      initialStream: stream,
    );
  }

  Future<void> saveStreamSession(StreamSession session) {
    return _database.saveStreamSession(
      StreamSessionsCompanion(
        id: Value(session.id),
        releaseId: Value(session.releaseId),
        episodeId: Value(session.episodeId),
        url: Value(session.stream.url.toString()),
        type: Value(session.stream.type.name),
        quality: Value(session.stream.quality),
        headersJson: Value(jsonEncode(session.stream.headers)),
        createdAt: Value(session.createdAt),
        expiresAt: Value(session.expiresAt),
      ),
    );
  }
}

DreamStreamType _dreamStreamTypeFromName(String name) {
  return switch (name) {
    'hls' => DreamStreamType.hls,
    'dash' => DreamStreamType.dash,
    'mp4' => DreamStreamType.mp4,
    'webm' => DreamStreamType.webm,
    'audio' => DreamStreamType.audio,
    _ => DreamStreamType.unknown,
  };
}

Map<String, String> _decodeHeaders(String json) {
  try {
    final value = jsonDecode(json);
    if (value is! Map) return const {};
    return value.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  } on FormatException {
    return const {};
  }
}

VideoStreamType videoStreamTypeFromExtension(String extension) {
  return switch (extension.toLowerCase()) {
    'm3u8' => VideoStreamType.hls,
    'mpd' => VideoStreamType.dash,
    'mp4' => VideoStreamType.mp4,
    'webm' => VideoStreamType.webm,
    _ => VideoStreamType.mp4,
  };
}
