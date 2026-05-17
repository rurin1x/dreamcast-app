import 'package:dream_cast/core/errors/app_exception.dart';

final class PlayerJsPackedParams {
  const PlayerJsPackedParams({
    required this.payload,
    required this.radix,
    required this.count,
    required this.symbols,
  });

  final String payload;
  final int radix;
  final int count;
  final List<String> symbols;
}

final class PlayerJsUnpacker {
  const PlayerJsUnpacker();

  static const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  static final _packedCallPattern = RegExp(
    r'''return\s+p\}\('((?:\\.|[^\\'])*)',\s*(\d+),\s*(\d+),\s*'((?:\\.|[^'])*)'\.split\('\|'\)''',
    dotAll: true,
  );

  String unpack(String packedScript) {
    if (!packedScript.contains("return p}('")) {
      return packedScript;
    }

    final params = parseParams(packedScript);
    final dictionary = <String, String>{};

    for (var i = params.count - 1; i >= 0; i--) {
      final key = _encodeBase(i, params.radix);
      dictionary[key] =
          i < params.symbols.length && params.symbols[i].isNotEmpty
          ? params.symbols[i]
          : key;
    }

    return params.payload.replaceAllMapped(
      RegExp(r'\b\w+\b'),
      (match) => dictionary[match.group(0)] ?? match.group(0)!,
    );
  }

  PlayerJsPackedParams parseParams(String packedScript) {
    final match = _packedCallPattern.firstMatch(packedScript);
    if (match != null) {
      return PlayerJsPackedParams(
        payload: _unescapePackedString(match.group(1)!),
        radix: int.parse(match.group(2)!),
        count: int.parse(match.group(3)!),
        symbols: match.group(4)!.split('|'),
      );
    }

    throw const ParserException('Не удалось распаковать PlayerJS.');
  }

  String _encodeBase(int value, int radix) {
    if (radix <= 0) {
      throw const ParserException(
        'Некорректное основание упаковщика PlayerJS.',
      );
    }
    final remainder = value % radix;
    final prefix = value < radix ? '' : _encodeBase(value ~/ radix, radix);
    final digit = remainder > 35
        ? String.fromCharCode(remainder + 29)
        : _alphabet[remainder];
    return '$prefix$digit';
  }

  String _unescapePackedString(String value) {
    return value
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }
}
