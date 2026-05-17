import 'package:dio/dio.dart';
import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:dream_cast/core/network/network_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkConfigProvider = Provider<NetworkConfig>(
  (ref) => const NetworkConfig(),
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(networkConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      followRedirects: true,
      maxRedirects: 5,
      headers: config.browserLikeHeaders,
    ),
  );

  dio.interceptors.add(_ErrorMappingInterceptor());
  dio.interceptors.add(_LoggingInterceptor());

  return dio;
});

final class _ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final message = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'Сервер слишком долго не отвечает.',
      DioExceptionType.badResponse when statusCode == 403 =>
        'Доступ временно ограничен. Попробуйте позже или проверьте сеть.',
      DioExceptionType.badResponse =>
        'Сервер вернул ошибку ${statusCode ?? ''}.',
      DioExceptionType.connectionError => 'Нет соединения с сервером.',
      DioExceptionType.cancel => 'Запрос был отменён.',
      _ => 'Не удалось выполнить сетевой запрос.',
    };

    handler.reject(err.copyWith(error: NetworkException(message, cause: err)));
  }
}

final class _LoggingInterceptor extends Interceptor {
  final _log = appLogger('network');
  final _stopwatches = <RequestOptions, Stopwatch>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.fine('🚀 REQUEST START: ${options.method} ${options.uri}');
    _log.fine('Headers: ${options.headers}');
    _stopwatches[options] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final sw = _stopwatches.remove(response.requestOptions);
    sw?.stop();
    final durationMs = sw?.elapsedMilliseconds ?? -1;

    _log.fine('✅ RESPONSE SUCCESS: status=${response.statusCode} (${durationMs}ms) '
        '${response.requestOptions.method} ${response.requestOptions.uri}');
    
    final redirects = response.redirects;
    if (redirects.isNotEmpty) {
      _log.fine('Redirect chain:');
      for (var i = 0; i < redirects.length; i++) {
        final r = redirects[i];
        _log.fine('  [$i] ${r.statusCode} -> ${r.location}');
      }
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = _stopwatches.remove(err.requestOptions);
    sw?.stop();
    final durationMs = sw?.elapsedMilliseconds ?? -1;

    final timeoutStage = switch (err.type) {
      DioExceptionType.connectionTimeout => 'CONNECTION_TIMEOUT',
      DioExceptionType.sendTimeout => 'SEND_TIMEOUT',
      DioExceptionType.receiveTimeout => 'RECEIVE_TIMEOUT',
      _ => 'OTHER_ERROR',
    };

    _log.warning('❌ RESPONSE ERROR: type=${err.type} (stage=$timeoutStage) status=${err.response?.statusCode} (${durationMs}ms) '
        '${err.requestOptions.method} ${err.requestOptions.uri}');
    _log.warning('Error details: ${err.message}');

    handler.next(err);
  }
}
