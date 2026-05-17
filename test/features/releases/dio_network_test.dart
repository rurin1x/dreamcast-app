import 'package:dream_cast/core/network/network_config.dart';
import 'package:dream_cast/features/releases/data/dream_cast_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dio Network Compatibility Tests', () {
    test('NetworkConfig provides 45s timeouts and extensive browser headers', () {
      const config = NetworkConfig();

      expect(config.connectTimeout, const Duration(seconds: 45));
      expect(config.receiveTimeout, const Duration(seconds: 45));
      expect(config.sendTimeout, const Duration(seconds: 45));

      final headers = config.browserLikeHeaders;
      expect(headers['User-Agent'], contains('Android 10'));
      expect(headers['Accept'], contains('text/html'));
      expect(headers['Accept-Language'], contains('ru-RU'));
      expect(headers['Connection'], 'keep-alive');
      expect(headers['Origin'], 'https://dreamerscast.com');
      expect(headers['Referer'], 'https://dreamerscast.com/');
    });
  });
}
