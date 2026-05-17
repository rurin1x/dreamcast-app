import 'dart:convert';

import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/data/dto/player_playlist_dto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_crypto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_unpacker.dart';

final class PlayerJsPlaylistDecoder {
  const PlayerJsPlaylistDecoder({
    this.unpacker = const PlayerJsUnpacker(),
    this.crypto = const PlayerJsCrypto(),
  });

  final PlayerJsUnpacker unpacker;
  final PlayerJsCrypto crypto;

  static final _cryptCodePatterns = [
    // Parity with the original anicli-api regex: u:\'#1...=\\'
    RegExp(r'''u\s*:\s*\\\s*['"]([^=]+=[\\]+)\s*['"]'''),
    RegExp(r'''u\s*:\s*\\?\s*["']([^"']+)["']'''),
    RegExp(r'''["']u["']\s*:\s*\\?\s*["']([^"']+)["']'''),
  ];

  PlayerPlaylistDto decode({
    required String playerScript,
    required String encodedPayload,
  }) {
    return decodeWithDiagnostics(
      playerScript: playerScript,
      encodedPayload: encodedPayload,
    ).playlist;
  }

  PlayerJsDecodeResult decodeWithDiagnostics({
    required String playerScript,
    required String encodedPayload,
  }) {
    final hasPacked = playerScript.contains("return p}('");
    final diagnostics = StringBuffer()
      ..writeln('payload.length=${encodedPayload.length}')
      ..writeln('payload.preview="${_snippet(encodedPayload)}"')
      ..writeln('payload.marker="${_payloadMarker(encodedPayload)}"')
      ..writeln('playerScript.length=${playerScript.length}')
      ..writeln('playerScript.hasPacked=$hasPacked');

    var stage = 'detect payload format';
    try {
      final direct = _tryDecodeDirectPlaylist(
        encodedPayload,
        playerScript,
        diagnostics,
      );
      if (direct != null) return direct;

      stage = 'legacy playerjs keys';
      return _decodeLegacy(
        playerScript: playerScript,
        encodedPayload: encodedPayload,
        diagnostics: diagnostics,
      );
    } catch (error, stackTrace) {
      diagnostics
        ..writeln('failed.stage=$stage')
        ..writeln('exception.type=${error.runtimeType}')
        ..writeln('exception=$error')
        ..writeln('stackTrace=$stackTrace');
      throw ParserException(
        'Ошибка декодирования PlayerJS на этапе "$stage".\n'
        '${diagnostics.toString()}',
        cause: error,
      );
    }
  }

  PlayerJsDecodeResult _decodeLegacy({
    required String playerScript,
    required String encodedPayload,
    required StringBuffer diagnostics,
  }) {
    diagnostics.writeln('decode.mode=legacy-playerjs-keys');
    final keyMap = _extractKeyMap(
      playerScript: playerScript,
      diagnostics: diagnostics,
      label: 'legacy',
    );
    final payload = encodedPayload.length >= 2
        ? encodedPayload.substring(2)
        : encodedPayload;
    diagnostics
      ..writeln(
        'payload.prefix="${encodedPayload.length >= 2 ? encodedPayload.substring(0, 2) : encodedPayload}"',
      )
      ..writeln('payload.stripped.length=${payload.length}');
    final cleaned = _stripPlaylistKeys(
      payload: payload,
      keyMap: keyMap,
      diagnostics: diagnostics,
      label: 'legacy',
    );
    final result = _decodePayloadCandidates(
      payload: cleaned,
      diagnostics: diagnostics,
      label: 'legacy.cleaned',
    );
    if (result != null) return result;

    throw const ParserException('PlayerJS вернул некорректный плейлист.');
  }

  PlayerJsDecodeResult? _tryDecodeDirectPlaylist(
    String encodedPayload,
    String playerScript,
    StringBuffer diagnostics,
  ) {
    final marker = _payloadMarker(encodedPayload);
    if (marker != '#2') {
      diagnostics.writeln('directDecode.skipped=unsupported marker $marker');
      return null;
    }

    diagnostics.writeln('decode.mode=direct-base64-json');
    final payload = encodedPayload.substring(2);
    diagnostics
      ..writeln('direct.payload.length=${payload.length}')
      ..writeln('direct.payload.preview="${_snippet(payload)}"');

    final rawResult = _decodePayloadCandidates(
      payload: payload,
      diagnostics: diagnostics,
      label: 'direct.raw',
    );
    if (rawResult != null) return rawResult;

    diagnostics.writeln('directDecode.cleaningWithPlayerKeys=true');
    final keyMap = _extractKeyMap(
      playerScript: playerScript,
      diagnostics: diagnostics,
      label: 'direct.keyScript',
    );
    final cleaned = _stripPlaylistKeys(
      payload: payload,
      keyMap: keyMap,
      diagnostics: diagnostics,
      label: 'direct.cleaned',
    );
    final cleanedResult = _decodePayloadCandidates(
      payload: cleaned,
      diagnostics: diagnostics,
      label: 'direct.cleaned',
    );
    if (cleanedResult != null) return cleanedResult;

    throw const ParserException(
      'Не удалось декодировать прямой #2 payload Dream Cast.',
    );
  }

  PlayerJsDecodeResult? _decodePayloadCandidates({
    required String payload,
    required StringBuffer diagnostics,
    required String label,
  }) {
    for (final candidate in _directPayloadCandidates(payload)) {
      final decodedPlaylist = _tryDecodePayloadCandidate(
        candidate: candidate,
        diagnostics: diagnostics,
        label: label,
      );
      if (decodedPlaylist == null) continue;

      try {
        final playlistJson = jsonDecode(decodedPlaylist);
        if (playlistJson is! Map) {
          diagnostics.writeln(
            '$label.candidateSkipped=decoded JSON is ${playlistJson.runtimeType}',
          );
          continue;
        }

        final playlistMap = playlistJson.cast<String, Object?>();
        _writeFileDiagnostics(diagnostics, playlistMap['file']);
        final playlist = PlayerPlaylistDto.fromJson(playlistMap);
        diagnostics.writeln('dto.files=${playlist.files.length}');

        return PlayerJsDecodeResult(
          playlist: playlist,
          diagnostics: diagnostics.toString(),
        );
      } catch (error, stackTrace) {
        diagnostics
          ..writeln('$label.jsonFailed.length=${candidate.length}')
          ..writeln('$label.jsonException.type=${error.runtimeType}')
          ..writeln('$label.jsonException=$error')
          ..writeln('$label.jsonStackTrace=$stackTrace');
      }
    }
    return null;
  }

  String? _tryDecodePayloadCandidate({
    required String candidate,
    required StringBuffer diagnostics,
    required String label,
  }) {
    try {
      final decodedPlaylist = _decodeBase64PossiblyUrlEncoded(candidate);
      diagnostics
        ..writeln('$label.candidate.length=${candidate.length}')
        ..writeln('$label.playlistJson.length=${decodedPlaylist.length}')
        ..writeln('$label.playlistJson.preview="${_snippet(decodedPlaylist)}"');
      return decodedPlaylist;
    } catch (error, stackTrace) {
      diagnostics
        ..writeln('$label.candidateFailed.length=${candidate.length}')
        ..writeln('$label.exception.type=${error.runtimeType}')
        ..writeln('$label.exception=$error')
        ..writeln('$label.stackTrace=$stackTrace');
      return null;
    }
  }

  Map<String, Object?> _extractKeyMap({
    required String playerScript,
    required StringBuffer diagnostics,
    required String label,
  }) {
    final unpacked = unpacker.unpack(playerScript);
    diagnostics
      ..writeln('$label.unpacked.length=${unpacked.length}')
      ..writeln('$label.unpacked.preview="${_snippet(unpacked)}"');

    final cryptCode = _extractCryptCode(unpacked);
    diagnostics
      ..writeln('$label.cryptCode.length=${cryptCode.length}')
      ..writeln('$label.cryptCode.preview="${_snippet(cryptCode)}"');

    final decodedConfig = crypto.decode(cryptCode);
    diagnostics
      ..writeln('$label.config.length=${decodedConfig.length}')
      ..writeln('$label.config.preview="${_snippet(decodedConfig)}"');

    final config = jsonDecode(decodedConfig);
    if (config is! Map) {
      throw const ParserException(
        'PlayerJS вернул некорректные ключи декодирования.',
      );
    }

    return config.cast<String, Object?>();
  }

  String _stripPlaylistKeys({
    required String payload,
    required Map<String, Object?> keyMap,
    required StringBuffer diagnostics,
    required String label,
  }) {
    var cleaned = payload;
    for (var i = 4; i >= 0; i--) {
      final key = keyMap['bk$i'];
      if (key == null || key == '' || key == 'undefined') {
        diagnostics.writeln('$label.bk$i=empty');
        continue;
      }
      final encodedKey = base64EncodeUrlComponent('$key');
      final before = cleaned.length;
      cleaned = cleaned.replaceAll('//$encodedKey', '');
      diagnostics.writeln(
        '$label.bk$i.removed=${before != cleaned.length}, keyPreview="${_snippet('$key', max: 42)}"',
      );
    }
    diagnostics
      ..writeln('$label.payload.length=${cleaned.length}')
      ..writeln('$label.payload.preview="${_snippet(cleaned)}"');
    return cleaned;
  }

  String _extractCryptCode(String script) {
    for (final pattern in _cryptCodePatterns) {
      final match = pattern.firstMatch(script);
      if (match != null) return match.group(1)!;
    }
    throw const ParserException('Не найдены ключи декодирования PlayerJS.');
  }
}

final class PlayerJsDecodeResult {
  const PlayerJsDecodeResult({
    required this.playlist,
    required this.diagnostics,
  });

  final PlayerPlaylistDto playlist;
  final String diagnostics;
}

String base64EncodeUrlComponent(String value) {
  return base64.encode(utf8.encode(Uri.encodeComponent(value)));
}

String base64DecodeUrlComponent(String value) {
  return Uri.decodeComponent(utf8.decode(base64.decode(value)));
}

String _decodeBase64PossiblyUrlEncoded(String value) {
  final bytes = base64.decode(base64.normalize(value));
  final decoded = utf8.decode(bytes, allowMalformed: true);
  final trimmed = decoded.trimLeft();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return decoded;
  return Uri.decodeComponent(decoded);
}

Iterable<String> _directPayloadCandidates(String payload) sync* {
  yield payload;

  final seen = <String>{payload};
  for (final match in RegExp(r'=+').allMatches(payload)) {
    final candidate = payload.substring(0, match.end);
    if (candidate.length < 8 || !seen.add(candidate)) continue;
    yield candidate;
  }
}

String _payloadMarker(String value) {
  if (value.length >= 2 && value.startsWith('#')) return value.substring(0, 2);
  return 'none';
}

void _writeFileDiagnostics(StringBuffer diagnostics, Object? file) {
  switch (file) {
    case final String value:
      diagnostics
        ..writeln('playlist.file.type=String')
        ..writeln('playlist.file.empty=${value.trim().isEmpty}')
        ..writeln('playlist.file.preview="${_snippet(value)}"');
    case final List list:
      var maps = 0;
      var emptyFiles = 0;
      var nullEntries = 0;
      for (final item in list) {
        if (item == null) {
          nullEntries++;
          continue;
        }
        if (item is Map) {
          maps++;
          final fileValue = item['file'];
          if (fileValue is! String || fileValue.trim().isEmpty) {
            emptyFiles++;
          }
        }
      }
      diagnostics
        ..writeln('playlist.file.type=List')
        ..writeln('playlist.file.count=${list.length}')
        ..writeln('playlist.file.mapEntries=$maps')
        ..writeln('playlist.file.nullEntries=$nullEntries')
        ..writeln('playlist.file.emptyFileEntries=$emptyFiles')
        ..writeln(
          'playlist.file.first="${_snippet(list.isEmpty ? '' : '${list.first}')}"',
        );
    default:
      diagnostics
        ..writeln('playlist.file.type=${file.runtimeType}')
        ..writeln('playlist.file.value="${_snippet('$file')}"');
  }
}

String _snippet(String value, {int max = 500}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}
