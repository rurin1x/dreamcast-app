import 'package:dream_cast/features/releases/data/dto/player_playlist_dto.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_cast_html_parser.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_stream_extractor.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_playlist_decoder.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/schedule/data/dream_cast_schedule_parser.dart';
import 'package:dream_cast/features/schedule/domain/release_schedule.dart';

final class DreamCastParserService {
  const DreamCastParserService({
    this.htmlParser = const DreamCastHtmlParser(),
    this.scheduleParser = const DreamCastScheduleParser(),
    this.playlistDecoder = const PlayerJsPlaylistDecoder(),
    this.streamExtractor = const DreamStreamExtractor(),
  });

  final DreamCastHtmlParser htmlParser;
  final DreamCastScheduleParser scheduleParser;
  final PlayerJsPlaylistDecoder playlistDecoder;
  final DreamStreamExtractor streamExtractor;

  ParsedDreamReleasePage parseReleasePage(String html) {
    return htmlParser.parse(html);
  }

  ReleaseSchedule parseSchedule(String html) {
    return scheduleParser.parse(html);
  }

  PlayerPlaylistDto decodePlaylist({
    required String playerScript,
    required String encodedPayload,
  }) {
    return playlistDecoder.decode(
      playerScript: playerScript,
      encodedPayload: encodedPayload,
    );
  }

  PlayerJsDecodeResult decodePlaylistWithDiagnostics({
    required String playerScript,
    required String encodedPayload,
  }) {
    return playlistDecoder.decodeWithDiagnostics(
      playerScript: playerScript,
      encodedPayload: encodedPayload,
    );
  }

  List<DreamEpisode> extractEpisodes({
    required int releaseId,
    required String playerScript,
    required String encodedPayload,
  }) {
    return decodePlaylist(
      playerScript: playerScript,
      encodedPayload: encodedPayload,
    ).toEpisodes(releaseId);
  }

  DreamEpisodeExtractionResult extractEpisodesWithDiagnostics({
    required int releaseId,
    required String playerScript,
    required String encodedPayload,
  }) {
    final decoded = decodePlaylistWithDiagnostics(
      playerScript: playerScript,
      encodedPayload: encodedPayload,
    );
    logPlayerJsDiagnostic(
      '[stage=episodes.map.start] releaseId=$releaseId, '
      'playlist.files=${decoded.playlist.files.length}, '
      'playlist.runtimeType=${decoded.playlist.runtimeType}',
    );
    final episodes = decoded.playlist.toEpisodes(releaseId);
    final emptyFiles = episodes
        .where((episode) => episode.file.trim().isEmpty)
        .length;
    logPlayerJsDiagnostic(
      '[stage=episodes.map.done] releaseId=$releaseId, '
      'episodes.count=${episodes.length}, emptyFiles=$emptyFiles, '
      'first.runtimeType=${episodes.isEmpty ? null : episodes.first.runtimeType}, '
      'first="${episodes.isEmpty ? '' : '${episodes.first.ordinal}: ${episodes.first.title}'}"',
    );
    final diagnostics = StringBuffer(decoded.diagnostics)
      ..writeln('mapped.episodes=${episodes.length}')
      ..writeln('mapped.emptyFileEpisodes=$emptyFiles')
      ..writeln(
        'mapped.first="${episodes.isEmpty ? '' : '${episodes.first.ordinal}: ${episodes.first.title}'}"',
      )
      ..writeln(
        'mapped.first.file="${episodes.isEmpty ? '' : _snippet(episodes.first.file)}"',
      );

    return DreamEpisodeExtractionResult(
      episodes: episodes,
      diagnostics: diagnostics.toString(),
    );
  }

  List<DreamStream> extractStreams(DreamEpisode episode) {
    return streamExtractor.extract(episode);
  }
}

final class DreamEpisodeExtractionResult {
  const DreamEpisodeExtractionResult({
    required this.episodes,
    required this.diagnostics,
  });

  final List<DreamEpisode> episodes;
  final String diagnostics;
}

String _snippet(String value, {int max = 500}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}
