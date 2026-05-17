final class NetworkConfig {
  const NetworkConfig({
    this.baseUrl = 'https://dreamerscast.com',
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  Map<String, String> get browserLikeHeaders => const {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'x-requested-with': 'XMLHttpRequest',
    'Sec-Ch-Ua-Mobile': '?1',
    'Sec-Ch-Ua-Platform': '"Android"',
  };
}
