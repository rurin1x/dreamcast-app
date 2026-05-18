import 'dart:convert';
import 'dart:io';

import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:dream_cast/features/releases/data/dto/dream_release_dto.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_cast_html_parser.dart';
import 'package:dream_cast/features/releases/data/parsers/dream_stream_extractor.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_crypto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_playlist_decoder.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_unpacker.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/schedule/data/dream_cast_schedule_parser.dart';
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

  group('DreamReleaseDto', () {
    test('maps API series fields to released and total episodes', () {
      final release = DreamReleaseDto.fromJson({
        'id': 540,
        'russian': 'Власть книжного червя',
        'original': 'Honzuki no Gekokujou',
        'url': '/home/release/540-honzuki-no-gekokujou',
        'series': 6,
        'currentSeries': 12,
      }).toDomain();

      expect(release.currentEpisodes, 6);
      expect(release.totalEpisodes, 12);
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
    test('decodes newer #2 direct base64 JSON playlist', () {
      final playlistJson = jsonEncode({
        'id': 'player',
        'file': [
          {
            'label': '540',
            'title': 'Серия 1',
            'file':
                'https://play.dreamerscast.com/dash/show/manifest.mpd or https://play.dreamerscast.com/hls/show/master.m3u8',
            'thumbnails': 'https://cache.dreamerscast.com/media/thumbnails.vtt',
            'embed': 'https://player.dreamerscast.com/embed/show',
            'id': 'playlist_1',
            'vars': {'vlc': '0'},
          },
          {
            'label': '540',
            'title': 'Серия 2',
            'file':
                'https://play.dreamerscast.com/dash/show-2/manifest.mpd or https://play.dreamerscast.com/hls/show-2/master.m3u8',
            'id': 'playlist_2',
            'vars': {'vlc': '1'},
          },
        ],
      });
      final encodedPayload = '#2${base64EncodeUrlComponent(playlistJson)}';

      final result = const PlayerJsPlaylistDecoder().decodeWithDiagnostics(
        playerScript: 'not used by #2 direct payload',
        encodedPayload: encodedPayload,
      );
      final episodes = result.playlist.toEpisodes(540);
      final streams = const DreamStreamExtractor().extract(episodes.first);

      expect(result.diagnostics, contains('decode.mode=direct-base64-json'));
      expect(result.diagnostics, contains('playlist.file.count=2'));
      expect(episodes, hasLength(2));
      expect(episodes.first.title, 'Серия 1');
      expect(episodes.first.file, contains('manifest.mpd'));
      expect(episodes.first.file, contains('master.m3u8'));
      expect(
        streams.map((stream) => stream.type),
        contains(DreamStreamType.dash),
      );
      expect(
        streams.map((stream) => stream.type),
        contains(DreamStreamType.hls),
      );
    });

    test('decodes #2 playlist with PlayerJS bk key insertions', () {
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
        'id': 'player',
        'file': [
          {
            'label': '540',
            'title': 'Серия 1',
            'file':
                'https://play.dreamerscast.com/dash/show/manifest.mpd or https://play.dreamerscast.com/hls/show/master.m3u8',
            'id': 'playlist_1',
            'vars': {'vlc': '0'},
          },
        ],
      });
      final encodedJson = base64EncodeUrlComponent(playlistJson);
      final encodedPayload =
          '#2${encodedJson.substring(0, 36)}//${base64EncodeUrlComponent('alpha')}'
          '${encodedJson.substring(36, 92)}//${base64EncodeUrlComponent('beta')}'
          '${encodedJson.substring(92)}';

      final result = const PlayerJsPlaylistDecoder().decodeWithDiagnostics(
        playerScript: playerScript,
        encodedPayload: encodedPayload,
      );
      final episodes = result.playlist.toEpisodes(540);

      expect(result.diagnostics, contains('decode.mode=direct-base64-json'));
      expect(
        result.diagnostics,
        contains('directDecode.cleaningWithPlayerKeys=true'),
      );
      expect(result.diagnostics, contains('direct.cleaned.bk0.removed=true'));
      expect(result.diagnostics, contains('direct.cleaned.bk1.removed=true'));
      expect(episodes, hasLength(1));
      expect(episodes.first.file, contains('manifest.mpd'));
      expect(episodes.first.file, contains('master.m3u8'));
    });

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

  group('DreamCastScheduleParser', () {
    test('extracts day sections and normalizes poster URLs', () {
      const html = '''
      <main id="Content">
        <div class="col-md-12">
          <div class="timetable"><h4>Понедельник</h4></div>
          <div class="row" id="content">
            <div class="col-md-3 col-12 poster">
              <a href="/home/release/561-test-title">
                <div class="poster-rating">4,5</div>
                <div class="poster-img" style="background:url('//cache.dreamerscast.com/releases/561/poster.webp')"></div>
                <span class="s-title-russian">Русское название</span>
                <span class="s-title-original">Romaji Title</span>
                <div class="poster_info">
                  <div class="s-item"><b>Тип: </b></div><span class="s-type-color">TV</span>
                </div>
                <div class="poster_info">
                  <div class="s-item"><b>Год: </b></div><span>2026</span>
                </div>
                <div class="poster_info">
                  <div class="s-item"><b>Эпизодов: </b></div><span>3 из 12</span>
                </div>
              </a>
            </div>
          </div>
          <div class="timetable"><h4>Вторник</h4></div>
          <div class="row" id="content"></div>
        </div>
      </main>
      ''';

      final schedule = const DreamCastScheduleParser().parse(html);
      final release = schedule.days.first.releases.single;

      expect(schedule.days, hasLength(2));
      expect(schedule.days.first.title, 'Понедельник');
      expect(release.id, 561);
      expect(release.title, 'Русское название');
      expect(release.originalTitle, 'Romaji Title');
      expect(
        release.url,
        'https://dreamerscast.com/home/release/561-test-title',
      );
      expect(
        release.posterUrl,
        'https://cache.dreamerscast.com/releases/561/poster.webp',
      );
      expect(release.type, 'TV');
      expect(release.year, 2026);
      expect(release.currentEpisodes, 3);
      expect(release.totalEpisodes, 12);
    });
  });

  group('UrlNormalizer', () {
    test(
      'normalizeDreamCastUrl resolves absolute, relative, protocol-relative and handles encoding',
      () {
        expect(normalizeDreamCastUrl(null), isNull);
        expect(normalizeDreamCastUrl(''), isNull);
        expect(normalizeDreamCastUrl('   '), isNull);

        expect(
          normalizeDreamCastUrl('https://example.com/a'),
          'https://example.com/a',
        );
        expect(
          normalizeDreamCastUrl('//example.com/a'),
          'https://example.com/a',
        );
        expect(
          normalizeDreamCastUrl('/path/to/a'),
          'https://dreamerscast.com/path/to/a',
        );
        expect(
          normalizeDreamCastUrl('//example.com/Тестовый релиз'),
          'https://example.com/%D0%A2%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9%20%D1%80%D0%B5%D0%BB%D0%B8%D0%B7',
        );
      },
    );

    test(
      'normalizeDreamCastImageUrl resolves relative images to CDN instead of main domain',
      () {
        expect(
          normalizeDreamCastImageUrl('/releases/531/1.webp'),
          'https://cache.dreamerscast.com/releases/531/1.webp',
        );
        expect(
          normalizeDreamCastImageUrl('//cache.dreamerscast.com/1.webp'),
          'https://cache.dreamerscast.com/1.webp',
        );
        expect(
          normalizeDreamCastImageUrl('https://other.cdn.com/1.webp'),
          'https://other.cdn.com/1.webp',
        );
      },
    );

    test(
      'isValidHttpUrl rejects empty, invalid and relative, but accepts valid HTTP URLs',
      () {
        expect(isValidHttpUrl(null), isFalse);
        expect(isValidHttpUrl(''), isFalse);
        expect(isValidHttpUrl('//example.com'), isFalse);
        expect(isValidHttpUrl('/path'), isFalse);
        expect(isValidHttpUrl('https://example.com'), isTrue);
        expect(isValidHttpUrl('http://example.com'), isTrue);
      },
    );
  });
}

String _fixture(String name) {
  return File('test/features/releases/fixtures/$name').readAsStringSync();
}
