import 'dart:convert';

import 'package:dream_cast/core/database/app_database.dart'
    hide PlaybackPosition, StreamSession;
import 'package:dream_cast/features/player/domain/playback_position.dart';
import 'package:dream_cast/features/player/domain/stream_session.dart';
import 'package:dream_cast/features/player/domain/video_stream.dart';
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

VideoStreamType videoStreamTypeFromExtension(String extension) {
  return switch (extension.toLowerCase()) {
    'm3u8' => VideoStreamType.hls,
    'mpd' => VideoStreamType.dash,
    'mp4' => VideoStreamType.mp4,
    'webm' => VideoStreamType.webm,
    _ => VideoStreamType.mp4,
  };
}
