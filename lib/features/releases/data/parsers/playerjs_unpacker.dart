import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';

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

  String unpack(String packedScript) {
    final hasPackedMarker = packedScript.contains("return p}('");
    logPlayerJsDiagnostic(
      '[stage=unpack.start] input.type=${packedScript.runtimeType}, '
      'input.length=${packedScript.length}, hasPackedMarker=$hasPackedMarker',
    );

    if (!hasPackedMarker) {
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

    logPlayerJsDiagnostic(
      '[stage=unpack.dictionary] radix=${params.radix}, count=${params.count}, '
      'symbols=${params.symbols.length}, dictionary=${dictionary.length}',
    );

    final unpacked = params.payload.replaceAllMapped(
      RegExp(r'\b\w+\b'),
      (match) => dictionary[match.group(0)] ?? match.group(0)!,
    );
    logPlayerJsDiagnostic(
      '[stage=unpack.done] output.length=${unpacked.length}',
    );
    return unpacked;
  }

  PlayerJsPackedParams parseParams(String packedScript) {
    final markerIndex = packedScript.indexOf("return p}(");
    logPlayerJsDiagnostic(
      '[stage=unpack.scan] markerIndex=$markerIndex, input.length=${packedScript.length}',
    );
    if (markerIndex >= 0) {
      final firstQuote = packedScript.indexOf("'", markerIndex);
      if (firstQuote >= 0) {
        final payloadString = _readSingleQuotedString(packedScript, firstQuote);
        final radixToken = _readIntArgument(packedScript, payloadString.end);
        final countToken = _readIntArgument(packedScript, radixToken.end);
        final symbolsQuote = packedScript.indexOf("'", countToken.end);
        if (symbolsQuote >= 0) {
          final symbolsString = _readSingleQuotedString(
            packedScript,
            symbolsQuote,
          );
          final payload = _unescapePackedString(payloadString.value);
          final symbols = _unescapePackedString(symbolsString.value).split('|');
          logPlayerJsDiagnostic(
            '[stage=unpack.params] payload.length=${payload.length}, '
            'radix=${radixToken.value}, count=${countToken.value}, '
            'symbols=${symbols.length}',
          );
          return PlayerJsPackedParams(
            payload: payload,
            radix: radixToken.value,
            count: countToken.value,
            symbols: symbols,
          );
        }
      }
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

final class _ParsedString {
  const _ParsedString({required this.value, required this.end});

  final String value;
  final int end;
}

final class _ParsedInt {
  const _ParsedInt({required this.value, required this.end});

  final int value;
  final int end;
}

_ParsedString _readSingleQuotedString(String source, int quoteIndex) {
  if (quoteIndex < 0 ||
      quoteIndex >= source.length ||
      source[quoteIndex] != "'") {
    throw const ParserException('Некорректная строка упаковщика PlayerJS.');
  }

  final buffer = StringBuffer();
  var escaped = false;
  for (var index = quoteIndex + 1; index < source.length; index++) {
    final char = source[index];
    if (escaped) {
      buffer
        ..write(r'\')
        ..write(char);
      escaped = false;
      continue;
    }
    if (char == r'\') {
      escaped = true;
      continue;
    }
    if (char == "'") {
      return _ParsedString(value: buffer.toString(), end: index + 1);
    }
    buffer.write(char);
  }

  throw const ParserException('Не найдена закрывающая кавычка PlayerJS.');
}

_ParsedInt _readIntArgument(String source, int start) {
  var index = start;
  while (index < source.length) {
    final code = source.codeUnitAt(index);
    if (code == 44 || code == 32 || code == 9 || code == 10 || code == 13) {
      index++;
      continue;
    }
    break;
  }

  final numberStart = index;
  while (index < source.length) {
    final code = source.codeUnitAt(index);
    if (code < 48 || code > 57) break;
    index++;
  }

  if (numberStart == index) {
    throw const ParserException('Не найден числовой аргумент PlayerJS.');
  }

  return _ParsedInt(
    value: int.parse(source.substring(numberStart, index)),
    end: index,
  );
}
