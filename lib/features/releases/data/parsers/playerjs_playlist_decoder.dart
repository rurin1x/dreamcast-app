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
    RegExp(r'''u\s*:\s*\\?\s*["']([^"']+)["']'''),
    RegExp(r'''["']u["']\s*:\s*\\?\s*["']([^"']+)["']'''),
  ];

  PlayerPlaylistDto decode({
    required String playerScript,
    required String encodedPayload,
  }) {
    final unpacked = unpacker.unpack(playerScript);
    final cryptCode = _extractCryptCode(unpacked);
    final config = jsonDecode(crypto.decode(cryptCode));

    if (config is! Map) {
      throw const ParserException('PlayerJS вернул некорректные ключи.');
    }

    final keyMap = config.cast<String, Object?>();
    keyMap['file3_separator'] = '//';
    var payload = encodedPayload.length >= 2
        ? encodedPayload.substring(2)
        : encodedPayload;

    for (var i = 4; i >= 0; i--) {
      final key = keyMap['bk$i'];
      if (key == null || key == '' || key == 'undefined') continue;
      payload = payload.replaceAll('//${base64EncodeUrlComponent('$key')}', '');
    }

    final playlistJson = jsonDecode(base64DecodeUrlComponent(payload));
    if (playlistJson is! Map) {
      throw const ParserException('PlayerJS вернул некорректный плейлист.');
    }

    return PlayerPlaylistDto.fromJson(playlistJson.cast<String, Object?>());
  }

  String _extractCryptCode(String script) {
    for (final pattern in _cryptCodePatterns) {
      final match = pattern.firstMatch(script);
      if (match != null) return match.group(1)!;
    }
    throw const ParserException('Не найдены ключи декодирования PlayerJS.');
  }
}

String base64EncodeUrlComponent(String value) {
  return base64.encode(utf8.encode(Uri.encodeComponent(value)));
}

String base64DecodeUrlComponent(String value) {
  return Uri.decodeComponent(utf8.decode(base64.decode(value)));
}
