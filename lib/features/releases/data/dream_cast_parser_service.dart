import 'package:dream_cast/features/releases/data/dto/player_playlist_dto.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_cast_html_parser.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_stream_extractor.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_playlist_decoder.dart';
import 'package:dream_cast/features/releases/domain/release.dart';

final class DreamCastParserService {
  const DreamCastParserService({
    this.htmlParser = const DreamCastHtmlParser(),
    this.playlistDecoder = const PlayerJsPlaylistDecoder(),
    this.streamExtractor = const DreamStreamExtractor(),
  });

  final DreamCastHtmlParser htmlParser;
  final PlayerJsPlaylistDecoder playlistDecoder;
  final DreamStreamExtractor streamExtractor;

  ParsedDreamReleasePage parseReleasePage(String html) {
    return htmlParser.parse(html);
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

  List<DreamStream> extractStreams(DreamEpisode episode) {
    return streamExtractor.extract(episode);
  }
}
