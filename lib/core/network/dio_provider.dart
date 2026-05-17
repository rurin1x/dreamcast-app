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
      followRedirects: true,
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

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.fine('${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log.fine('${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }
}
