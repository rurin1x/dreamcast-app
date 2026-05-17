import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
        'Connection': 'keep-alive',
        'Referer': 'https://dreamerscast.com/',
      },
    ),
  );

  final List<_TestLog> _logs = [];
  bool _isTestingAll = false;

  Future<void> _runTest({
    required String name,
    required String method,
    required String url,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final log = _TestLog(
      name: name,
      method: method,
      url: url,
      status: _TestStatus.running,
    );

    setState(() {
      _logs.insert(0, log);
    });

    final stopwatch = Stopwatch()..start();

    try {
      final Response<dynamic> response;
      if (method == 'POST') {
        response = await _dio.post<dynamic>(
          url,
          data: data,
          options: options ?? Options(contentType: Headers.formUrlEncodedContentType),
        );
      } else {
        response = await _dio.get<dynamic>(
          url,
          options: options,
        );
      }

      stopwatch.stop();

      setState(() {
        log.status = _TestStatus.success;
        log.elapsedMs = stopwatch.elapsedMilliseconds;
        log.statusCode = response.statusCode;
        log.responseLength = response.data?.toString().length ?? 0;
        log.headers = response.headers.map;
        log.redirects = response.redirects.map((r) => '${r.statusCode} -> ${r.location}').toList();
        log.snippet = response.data?.toString().substring(0, response.data.toString().length > 400 ? 400 : response.data.toString().length);
      });
    } on DioException catch (e) {
      stopwatch.stop();

      final timeoutStage = switch (e.type) {
        DioExceptionType.connectionTimeout => 'CONNECTION_TIMEOUT',
        DioExceptionType.sendTimeout => 'SEND_TIMEOUT',
        DioExceptionType.receiveTimeout => 'RECEIVE_TIMEOUT',
        _ => 'OTHER_ERROR',
      };

      setState(() {
        log.status = _TestStatus.failed;
        log.elapsedMs = stopwatch.elapsedMilliseconds;
        log.statusCode = e.response?.statusCode;
        log.errorType = '${e.type} ($timeoutStage)';
        log.errorMessage = e.message;
        log.headers = e.response?.headers.map;
        log.snippet = e.response?.data?.toString();
      });
    } catch (e) {
      stopwatch.stop();

      setState(() {
        log.status = _TestStatus.failed;
        log.elapsedMs = stopwatch.elapsedMilliseconds;
        log.errorType = 'UNKNOWN';
        log.errorMessage = e.toString();
      });
    }
  }

  Future<void> _testAll() async {
    if (_isTestingAll) return;
    setState(() {
      _isTestingAll = true;
    });

    await _runTest(
      name: 'Google Connectivity Test',
      method: 'GET',
      url: 'https://www.google.com/',
    );

    await _runTest(
      name: 'Dream Cast GET Home',
      method: 'GET',
      url: 'https://dreamerscast.com/',
    );

    await _runTest(
      name: 'Dream Cast POST Search (Empty Query)',
      method: 'POST',
      url: 'https://dreamerscast.com/',
      data: {
        'search': '',
        'pageNumber': 1,
        'pageSize': 16,
        'status': '',
      },
    );

    await _runTest(
      name: 'Dream Cast Image CDN Test',
      method: 'GET',
      url: 'https://cache.dreamerscast.com/releases/531/79d0919c-fa60-4d9e-80cb-aa0a3086257c.webp',
      options: Options(responseType: ResponseType.bytes),
    );

    setState(() {
      _isTestingAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сетевой отладчик (Dio Raw)'),
        actions: [
          IconButton(
            tooltip: 'Очистить логи',
            onPressed: () => setState(() => _logs.clear()),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Инструменты диагностики',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_isTestingAll)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isTestingAll ? null : _testAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Запустить все тесты связи'),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.language, size: 16),
                        label: const Text('GET Google'),
                        onPressed: () => _runTest(
                          name: 'Google Connectivity',
                          method: 'GET',
                          url: 'https://www.google.com/',
                        ),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.home, size: 16),
                        label: const Text('GET DC Home'),
                        onPressed: () => _runTest(
                          name: 'Dream Cast GET Home',
                          method: 'GET',
                          url: 'https://dreamerscast.com/',
                        ),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.search, size: 16),
                        label: const Text('POST DC Search'),
                        onPressed: () => _runTest(
                          name: 'Dream Cast POST Search (Empty Query)',
                          method: 'POST',
                          url: 'https://dreamerscast.com/',
                          data: {
                            'search': '',
                            'pageNumber': 1,
                            'pageSize': 16,
                            'status': '',
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.image, size: 16),
                        label: const Text('GET CDN Image'),
                        onPressed: () => _runTest(
                          name: 'Dream Cast Image CDN',
                          method: 'GET',
                          url: 'https://cache.dreamerscast.com/releases/531/79d0919c-fa60-4d9e-80cb-aa0a3086257c.webp',
                          options: Options(responseType: ResponseType.bytes),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Логи пусты. Запустите один или несколько тестов связи, чтобы диагностировать проблемы с TLS, DNS или тайм-аутами.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _TestLogCard(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

enum _TestStatus { running, success, failed }

class _TestLog {
  _TestLog({
    required this.name,
    required this.method,
    required this.url,
    required this.status,
    this.elapsedMs,
    this.statusCode,
    this.responseLength,
    this.headers,
    this.redirects,
    this.errorType,
    this.errorMessage,
    this.snippet,
  });

  final String name;
  final String method;
  final String url;
  _TestStatus status;
  int? elapsedMs;
  int? statusCode;
  int? responseLength;
  Map<String, List<String>>? headers;
  List<String>? redirects;
  String? errorType;
  String? errorMessage;
  String? snippet;
}

class _TestLogCard extends StatelessWidget {
  const _TestLogCard({required this.log});

  final _TestLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = switch (log.status) {
      _TestStatus.running => Colors.blue.shade50,
      _TestStatus.success => Colors.green.shade50,
      _TestStatus.failed => Colors.red.shade50,
    };
    final borderColor = switch (log.status) {
      _TestStatus.running => Colors.blue.shade300,
      _TestStatus.success => Colors.green.shade300,
      _TestStatus.failed => Colors.red.shade300,
    };
    final tagColor = switch (log.status) {
      _TestStatus.running => Colors.blue.shade900,
      _TestStatus.success => Colors.green.shade900,
      _TestStatus.failed => Colors.red.shade900,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      color: cardColor,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.name,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                log.status.name.toUpperCase(),
                style: TextStyle(
                  color: tagColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.method} ${log.url}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
              if (log.elapsedMs != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Время: ${log.elapsedMs}ms • Код: ${log.statusCode ?? 'N/A'} • Длина: ${log.responseLength ?? 0}b',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (log.errorType != null) ...[
                  _detailRow(context, 'Тип ошибки', log.errorType!),
                  const SizedBox(height: 6),
                ],
                if (log.errorMessage != null) ...[
                  _detailRow(context, 'Сообщение ошибки', log.errorMessage!),
                  const SizedBox(height: 6),
                ],
                if (log.redirects != null && log.redirects!.isNotEmpty) ...[
                  _detailRow(context, 'Цепочка редиректов', log.redirects!.join('\n')),
                  const SizedBox(height: 6),
                ],
                if (log.headers != null) ...[
                  _detailRow(
                    context,
                    'Заголовки ответа',
                    log.headers!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join('\n'),
                  ),
                  const SizedBox(height: 6),
                ],
                if (log.snippet != null && log.snippet!.isNotEmpty) ...[
                  _detailRow(context, 'Фрагмент ответа', log.snippet!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
