import 'dart:convert';

import 'package:dream_cast/core/errors/app_exception.dart';

final class PlayerJsCrypto {
  const PlayerJsCrypto();

  static const _oY = 'xx???x=xx?x??=';
  static const _abc = 'ABCDEFGHIJKLMabcdefghijklmNOPQRSTUVWXYZnopqrstuvwxyz';
  static const _saltAlphabet =
      'ABCDEFGHIJKLMabcdefghijklmNOPQRSTUVWXYZnopqrstuvwxyz0123456789+/=';

  String decode(String value) {
    if (value.startsWith('#1')) {
      return _saltDecode(_pepper(value.substring(2), -1));
    }
    if (value.startsWith('#0')) {
      return _saltDecode(value.substring(2));
    }
    return value;
  }

  String saltEncodeForTests(String value) {
    final bytes = utf8.encode(value);
    final output = StringBuffer();

    for (var i = 0; i < bytes.length; i += 3) {
      final byte1 = bytes[i];
      final hasByte2 = i + 1 < bytes.length;
      final hasByte3 = i + 2 < bytes.length;
      final byte2 = hasByte2 ? bytes[i + 1] : 0;
      final byte3 = hasByte3 ? bytes[i + 2] : 0;

      final enc1 = byte1 >> 2;
      final enc2 = ((byte1 & 3) << 4) | (byte2 >> 4);
      final enc3 = hasByte2 ? (((byte2 & 15) << 2) | (byte3 >> 6)) : 64;
      final enc4 = hasByte3 ? (byte3 & 63) : 64;

      output
        ..write(_saltAlphabet[enc1])
        ..write(_saltAlphabet[enc2])
        ..write(_saltAlphabet[enc3])
        ..write(_saltAlphabet[enc4]);
    }

    return output.toString();
  }

  String _saltDecode(String encoded) {
    final filtered = encoded.split('').where(_saltAlphabet.contains).join();
    final bytes = <int>[];
    var index = 0;

    while (index + 3 < filtered.length) {
      final s = _saltAlphabet.indexOf(filtered[index++]);
      final o = _saltAlphabet.indexOf(filtered[index++]);
      final u = _saltAlphabet.indexOf(filtered[index++]);
      final a = _saltAlphabet.indexOf(filtered[index++]);

      if (s < 0 || o < 0 || u < 0 || a < 0) {
        throw const ParserException('Некорректная кодировка PlayerJS.');
      }

      bytes.add((s << 2) | (o >> 4));
      if (u != 64) bytes.add(((o & 15) << 4) | (u >> 2));
      if (a != 64) bytes.add(((u & 3) << 6) | a);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  String _pepper(String source, int n) {
    var s = source.replaceAll('+', '#');
    s = s.replaceAll('#', '+');
    var offset = (_sugar(_oY) * n).toDouble();
    if (n < 0) offset += _abc.length / 2;
    final shift = (offset * 2).toInt();
    final rotated = _abc.substring(shift) + _abc.substring(0, shift);

    return s.replaceAllMapped(
      RegExp('[A-Za-z]'),
      (match) => rotated[_abc.indexOf(match.group(0)!)],
    );
  }

  int _sugar(String value) {
    final buffer = StringBuffer();
    for (final item in value.split('=')) {
      final encoded = item
          .split('')
          .map((char) => char == 'x' ? '1' : '0')
          .join();
      final code = encoded.isEmpty ? 0 : int.parse(encoded, radix: 2);
      buffer.writeCharCode(code);
    }

    final result = buffer.toString();
    if (result.length <= 1) return 0;
    return int.parse(result.substring(0, result.length - 1));
  }
}
