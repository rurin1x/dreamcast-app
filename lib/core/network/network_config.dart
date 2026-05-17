final class NetworkConfig {
  const NetworkConfig({
    this.baseUrl = 'https://dreamerscast.com',
    this.connectTimeout = const Duration(seconds: 45),
    this.receiveTimeout = const Duration(seconds: 45),
    this.sendTimeout = const Duration(seconds: 45),
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  Map<String, String> get browserLikeHeaders => const {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    'Connection': 'keep-alive',
    'Origin': 'https://dreamerscast.com',
    'Referer': 'https://dreamerscast.com/',
    'x-requested-with': 'XMLHttpRequest',
    'Sec-Ch-Ua': '"Chromium";v="124", "Not.A/Brand";v="8"',
    'Sec-Ch-Ua-Mobile': '?1',
    'Sec-Ch-Ua-Platform': '"Android"',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
  };
}
