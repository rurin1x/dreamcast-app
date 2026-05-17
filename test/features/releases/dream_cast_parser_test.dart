import 'dart:convert';
import 'dart:io';

import 'package:dream_cast/features/releases/data/parsers/dream_cast_html_parser.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_stream_extractor.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_crypto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_playlist_decoder.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_unpacker.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DreamCastHtmlParser', () {
    test('extracts release page fields from fixture', () {
      final html = _fixture(
        'release_page.html',
      ).replaceAll('{{PLAYER_PAYLOAD}}', '#0encoded-payload');

      final page = const DreamCastHtmlParser().parse(html);

      expect(page.title, 'Тестовый релиз Dream Cast');
      expect(page.description, 'Описание с лишними пробелами.');
      expect(page.thumbnailUrl, 'https://cdn.example.test/poster.jpg');
      expect(page.playerPayload, '#0encoded-payload');
      expect(
        page.playerScriptUrl,
        'https://dreamerscast.com/js/playerjs-2026.js',
      );
    });
  });

  group('PlayerJsUnpacker', () {
    test('unpacks packed token payload', () {
      final script = _fixture('playerjs_packed.js');

      final unpacked = const PlayerJsUnpacker().unpack(script);

      expect(unpacked, 'hello world hello');
    });
  });

  group('PlayerJsPlaylistDecoder', () {
    test('decodes playlist and preserves episode metadata', () {
      final crypto = const PlayerJsCrypto();
      final keysJson = jsonEncode({
        'bk0': 'alpha',
        'bk1': 'beta',
        'bk2': '',
        'bk3': 'undefined',
        'bk4': null,
      });
      final cryptCode = '#0${crypto.saltEncodeForTests(keysJson)}';
      final playerScript = _fixture(
        'playerjs_direct.js',
      ).replaceAll('{{CRYPT_CODE}}', cryptCode);
      final playlistJson = jsonEncode({
        'id': 'playlist-1',
        'file': [
          {
            'title': 'Серия 1',
            'label': '1080p',
            'file':
                'https://play.dreamerscast.com/hls/show/1080/master.m3u8 https://play.dreamerscast.com/dash/show/1080/manifest.mpd',
            'thumbnails': 'https://cdn.example.test/1.jpg',
            'embed': '',
            'id': 'episode-1',
            'vars': {'vlc': '0'},
          },
          {
            'title': 'Серия 2',
            'label': '1080p',
            'file': 'https://play.dreamerscast.com/hls/show/720/master.m3u8',
            'id': 'episode-2',
            'vars': {'vlc': '1'},
          },
        ],
      });
      final encodedPayload =
          '#0${base64EncodeUrlComponent(playlistJson)}//${base64EncodeUrlComponent('alpha')}//${base64EncodeUrlComponent('beta')}';

      final playlist = const PlayerJsPlaylistDecoder().decode(
        playerScript: playerScript,
        encodedPayload: encodedPayload,
      );
      final episodes = playlist.toEpisodes(42);

      expect(episodes, hasLength(2));
      expect(episodes.first.id, 'episode-1');
      expect(episodes.first.releaseId, 42);
      expect(episodes.first.title, 'Серия 1');
      expect(episodes.first.vars['vlc'], '0');
    });
  });

  group('DreamStreamExtractor', () {
    test('extracts HLS and DASH streams from episode file field', () {
      const episode = DreamEpisode(
        id: 'episode-1',
        releaseId: 42,
        ordinal: 1,
        title: 'Серия 1',
        file:
            'https://play.dreamerscast.com/dash/show/1080/manifest.mpd https://play.dreamerscast.com/hls/show/1080/master.m3u8',
      );

      final streams = const DreamStreamExtractor().extract(episode);

      expect(streams, hasLength(2));
      expect(streams.first.type, DreamStreamType.hls);
      expect(streams.first.quality, 1080);
      expect(streams.last.type, DreamStreamType.dash);
    });
  });
}

String _fixture(String name) {
  return File('test/features/releases/fixtures/$name').readAsStringSync();
}
