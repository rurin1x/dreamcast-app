import 'dart:convert';

import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:dream_cast/features/releases/data/dto/player_playlist_dto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_crypto.dart';
import 'package:dream_cast/features/releases/data/parsers/playerjs_unpacker.dart';
import 'package:flutter/foundation.dart';

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
    final diagnostics = StringBuffer();
    _stage(
      diagnostics,
      'start',
      'build=${_buildMode()}, payload.type=${encodedPayload.runtimeType}, '
          'payload.null=false, payload.length=${encodedPayload.length}, '
          'payload.preview="${_snippet(encodedPayload)}"',
    );
    _stage(
      diagnostics,
      'start',
      'payload.marker="${_payloadMarker(encodedPayload)}", '
          'playerScript.type=${playerScript.runtimeType}, '
          'playerScript.null=false, playerScript.length=${playerScript.length}, '
          'playerScript.hasPacked=$hasPacked',
    );

    var stage = 'detect payload format';
    try {
      stage = 'direct playlist decode';
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
      _stage(
        diagnostics,
        'failure',
        'failed.stage=$stage, exception.type=${error.runtimeType}, '
            'exception=$error, stackTrace=$stackTrace',
      );
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
    _stage(diagnostics, 'legacy', 'decode.mode=legacy-playerjs-keys');
    final keyMap = _extractKeyMap(
      playerScript: playerScript,
      diagnostics: diagnostics,
      label: 'legacy',
    );
    final payload = encodedPayload.length >= 2
        ? encodedPayload.substring(2)
        : encodedPayload;
    _stage(
      diagnostics,
      'legacy.payload',
      'payload.prefix="${encodedPayload.length >= 2 ? encodedPayload.substring(0, 2) : encodedPayload}", '
          'payload.stripped.length=${payload.length}, '
          'base64.valid=${_isBase64Like(payload)}',
    );
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
      _stage(
        diagnostics,
        'direct.detect',
        'directDecode.skipped=unsupported marker $marker',
      );
      return null;
    }

    _stage(diagnostics, 'direct.detect', 'decode.mode=direct-base64-json');
    final payload = encodedPayload.substring(2);
    _stage(
      diagnostics,
      'direct.payload',
      'direct.payload.length=${payload.length}, '
          'direct.payload.preview="${_snippet(payload)}", '
          'base64.valid=${_isBase64Like(payload)}, '
          'padding.matches=${RegExp(r'=+').allMatches(payload).length}',
    );

    final rawResult = _decodePayloadCandidates(
      payload: payload,
      diagnostics: diagnostics,
      label: 'direct.raw',
    );
    if (rawResult != null) return rawResult;

    _stage(
      diagnostics,
      'direct.clean',
      'directDecode.cleaningWithPlayerKeys=true',
    );
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
    final candidates = _directPayloadCandidates(
      payload,
    ).toList(growable: false);
    _stage(
      diagnostics,
      '$label.candidates',
      'payload.length=${payload.length}, candidates.count=${candidates.length}',
    );

    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      _stage(
        diagnostics,
        '$label.candidate.$index',
        'candidate.type=${candidate.runtimeType}, candidate.null=false, '
            'candidate.length=${candidate.length}, '
            'base64.valid=${_isBase64Like(candidate)}, '
            'preview="${_snippet(candidate)}"',
      );
      final decodedPlaylist = _tryDecodePayloadCandidate(
        candidate: candidate,
        diagnostics: diagnostics,
        label: label,
      );
      if (decodedPlaylist == null) continue;

      try {
        final playlistJson = jsonDecode(decodedPlaylist);
        _stage(
          diagnostics,
          '$label.json',
          'json.runtimeType=${playlistJson.runtimeType}, '
              'json.preview="${_snippet(decodedPlaylist)}"',
        );
        if (playlistJson is! Map) {
          _stage(
            diagnostics,
            '$label.json',
            '$label.candidateSkipped=decoded JSON is ${playlistJson.runtimeType}',
          );
          continue;
        }

        final playlistMap = _toStringKeyMap(playlistJson);
        _writeFileDiagnostics(diagnostics, playlistMap['file']);
        final playlist = PlayerPlaylistDto.fromJson(playlistMap);
        _stage(
          diagnostics,
          '$label.dto',
          'dto.runtimeType=${playlist.runtimeType}, dto.files=${playlist.files.length}',
        );

        return PlayerJsDecodeResult(
          playlist: playlist,
          diagnostics: diagnostics.toString(),
        );
      } catch (error, stackTrace) {
        _stage(
          diagnostics,
          '$label.json',
          '$label.jsonFailed.length=${candidate.length}, '
              '$label.jsonException.type=${error.runtimeType}, '
              '$label.jsonException=$error, '
              '$label.jsonStackTrace=$stackTrace',
        );
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
      final decodedPlaylist = _decodeBase64PossiblyUrlEncoded(
        candidate,
        diagnostics: diagnostics,
        label: label,
      );
      _stage(
        diagnostics,
        '$label.utf8',
        '$label.candidate.length=${candidate.length}, '
            '$label.playlistJson.length=${decodedPlaylist.length}, '
            '$label.playlistJson.preview="${_snippet(decodedPlaylist)}"',
      );
      return decodedPlaylist;
    } catch (error, stackTrace) {
      _stage(
        diagnostics,
        '$label.decode',
        '$label.candidateFailed.length=${candidate.length}, '
            '$label.exception.type=${error.runtimeType}, '
            '$label.exception=$error, '
            '$label.stackTrace=$stackTrace',
      );
      return null;
    }
  }

  Map<String, Object?> _extractKeyMap({
    required String playerScript,
    required StringBuffer diagnostics,
    required String label,
  }) {
    final unpacked = unpacker.unpack(playerScript);
    _stage(
      diagnostics,
      '$label.unpack',
      '$label.unpacked.type=${unpacked.runtimeType}, '
          '$label.unpacked.length=${unpacked.length}, '
          '$label.unpacked.preview="${_snippet(unpacked)}"',
    );

    final cryptCode = _extractCryptCode(
      unpacked,
      diagnostics: diagnostics,
      label: label,
    );
    _stage(
      diagnostics,
      '$label.crypt',
      '$label.cryptCode.type=${cryptCode.runtimeType}, '
          '$label.cryptCode.length=${cryptCode.length}, '
          '$label.cryptCode.preview="${_snippet(cryptCode)}"',
    );

    final decodedConfig = crypto.decode(cryptCode);
    _stage(
      diagnostics,
      '$label.config',
      '$label.config.type=${decodedConfig.runtimeType}, '
          '$label.config.length=${decodedConfig.length}, '
          '$label.config.preview="${_snippet(decodedConfig)}"',
    );

    final config = jsonDecode(decodedConfig);
    _stage(
      diagnostics,
      '$label.config',
      '$label.config.json.runtimeType=${config.runtimeType}',
    );
    if (config is! Map) {
      throw const ParserException(
        'PlayerJS вернул некорректные ключи декодирования.',
      );
    }

    final keyMap = _toStringKeyMap(config);
    _stage(
      diagnostics,
      '$label.config',
      '$label.config.keys=${keyMap.keys.join(',')}',
    );
    return keyMap;
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
        _stage(
          diagnostics,
          '$label.keys',
          '$label.bk$i=empty, runtimeType=${key.runtimeType}, null=${key == null}',
        );
        continue;
      }
      final encodedKey = base64EncodeUrlComponent('$key');
      final before = cleaned.length;
      final needle = '//$encodedKey';
      final matches = needle.isEmpty ? 0 : needle.allMatches(cleaned).length;
      cleaned = cleaned.replaceAll(needle, '');
      _stage(
        diagnostics,
        '$label.keys',
        '$label.bk$i.removed=${before != cleaned.length}, '
            'matches=$matches, key.runtimeType=${key.runtimeType}, '
            'encodedKey.length=${encodedKey.length}, '
            'keyPreview="${_snippet('$key', max: 42)}"',
      );
    }
    _stage(
      diagnostics,
      '$label.payload',
      '$label.payload.length=${cleaned.length}, '
          '$label.payload.preview="${_snippet(cleaned)}", '
          'base64.valid=${_isBase64Like(cleaned)}',
    );
    return cleaned;
  }

  String _extractCryptCode(
    String script, {
    required StringBuffer diagnostics,
    required String label,
  }) {
    for (var index = 0; index < _cryptCodePatterns.length; index++) {
      final pattern = _cryptCodePatterns[index];
      final matches = pattern.allMatches(script).toList(growable: false);
      _stage(
        diagnostics,
        '$label.crypt.regex.$index',
        'pattern="$pattern", matches=${matches.length}',
      );
      if (matches.isNotEmpty) return matches.first.group(1)!;
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

String _decodeBase64PossiblyUrlEncoded(
  String value, {
  required StringBuffer diagnostics,
  required String label,
}) {
  final bytes = _decodeBase64Bytes(
    value,
    diagnostics: diagnostics,
    label: label,
  );
  late final String decoded;
  try {
    decoded = utf8.decode(bytes);
    _stage(
      diagnostics,
      '$label.utf8',
      'utf8.success=true, utf8.allowMalformed=false, decoded.length=${decoded.length}',
    );
  } on FormatException catch (error) {
    decoded = utf8.decode(bytes, allowMalformed: true);
    _stage(
      diagnostics,
      '$label.utf8',
      'utf8.success=false, utf8.allowMalformedFallback=true, '
          'error=$error, decoded.length=${decoded.length}',
    );
  }

  final trimmed = decoded.trimLeft();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return decoded;
  final uriDecoded = Uri.decodeComponent(decoded);
  _stage(
    diagnostics,
    '$label.uri',
    'uriDecode.applied=true, uriDecoded.length=${uriDecoded.length}, '
        'uriDecoded.preview="${_snippet(uriDecoded)}"',
  );
  return uriDecoded;
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

List<int> _decodeBase64Bytes(
  String value, {
  required StringBuffer diagnostics,
  required String label,
}) {
  try {
    final normalized = base64.normalize(value);
    final bytes = base64.decode(normalized);
    _stage(
      diagnostics,
      '$label.base64',
      'base64.codec=standard, base64.valid=true, '
          'input.length=${value.length}, normalized.length=${normalized.length}, '
          'bytes.length=${bytes.length}',
    );
    return bytes;
  } on FormatException catch (standardError) {
    _stage(
      diagnostics,
      '$label.base64',
      'base64.codec=standard, base64.valid=false, '
          'input.length=${value.length}, error=$standardError',
    );
    final normalized = base64Url.normalize(value);
    final bytes = base64Url.decode(normalized);
    _stage(
      diagnostics,
      '$label.base64',
      'base64.codec=url, base64.valid=true, '
          'input.length=${value.length}, normalized.length=${normalized.length}, '
          'bytes.length=${bytes.length}',
    );
    return bytes;
  }
}

String _payloadMarker(String value) {
  if (value.length >= 2 && value.startsWith('#')) return value.substring(0, 2);
  return 'none';
}

void _writeFileDiagnostics(StringBuffer diagnostics, Object? file) {
  switch (file) {
    case final String value:
      _stage(
        diagnostics,
        'playlist.file',
        'playlist.file.type=String, playlist.file.runtimeType=${value.runtimeType}, '
            'playlist.file.null=false, playlist.file.empty=${value.trim().isEmpty}, '
            'playlist.file.preview="${_snippet(value)}"',
      );
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
      _stage(
        diagnostics,
        'playlist.file',
        'playlist.file.type=List, playlist.file.runtimeType=${list.runtimeType}, '
            'playlist.file.count=${list.length}, playlist.file.mapEntries=$maps, '
            'playlist.file.nullEntries=$nullEntries, '
            'playlist.file.emptyFileEntries=$emptyFiles, '
            'playlist.file.first="${_snippet(list.isEmpty ? '' : '${list.first}')}"',
      );
    default:
      _stage(
        diagnostics,
        'playlist.file',
        'playlist.file.type=${file.runtimeType}, playlist.file.null=${file == null}, '
            'playlist.file.value="${_snippet('$file')}"',
      );
  }
}

Map<String, Object?> _toStringKeyMap(Map<dynamic, dynamic> source) {
  final result = <String, Object?>{};
  source.forEach((key, value) {
    result[key.toString()] = value;
  });
  return result;
}

bool _isBase64Like(String value) {
  try {
    base64.decode(base64.normalize(value));
    return true;
  } on FormatException {
    try {
      base64Url.decode(base64Url.normalize(value));
      return true;
    } on FormatException {
      return false;
    }
  }
}

void _stage(StringBuffer diagnostics, String stage, String message) {
  final line = '[stage=$stage] $message';
  diagnostics.writeln(line);
  logPlayerJsDiagnostic(line);
}

String _buildMode() {
  if (kReleaseMode) return 'release';
  if (kProfileMode) return 'profile';
  return 'debug';
}

String _snippet(String value, {int max = 500}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}
