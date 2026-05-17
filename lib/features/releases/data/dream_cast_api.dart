import 'package:dio/dio.dart';
import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/core/network/dio_provider.dart';
import 'package:dream_cast/features/releases/data/dto/dream_release_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dreamCastApiProvider = Provider<DreamCastApi>(
  (ref) => DreamCastApi(ref.watch(dioProvider)),
);

final class DreamCastApi {
  const DreamCastApi(this._dio);

  final Dio _dio;

  Future<DreamReleaseListDto> getReleases({
    String query = '',
    String status = '',
    int page = 1,
    int pageSize = 16,
    CancelToken? cancelToken,
  }) async {
    final response = await _requestWithRetry<Object?>(
      () => _dio.post<Object?>(
        '/',
        data: {
          'search': query,
          'status': status,
          'pageNumber': page,
          'pageSize': pageSize,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
        cancelToken: cancelToken,
      ),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body is! Map) {
      throw const ParserException('Сервер вернул неожиданный формат данных.');
    }

    return DreamReleaseListDto.fromJson(body.cast<String, Object?>());
  }

  Future<String> getReleaseHtml(String url, {CancelToken? cancelToken}) async {
    final response = await _requestWithRetry<String>(
      () => _dio.get<String>(
        url,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.plain),
      ),
      cancelToken: cancelToken,
    );

    return response.data ?? '';
  }

  Future<String> getPlayerScript(String url, {CancelToken? cancelToken}) async {
    final response = await _requestWithRetry<String>(
      () => _dio.get<String>(
        url,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.plain),
      ),
      cancelToken: cancelToken,
    );

    return response.data ?? '';
  }

  Future<Response<T>> _requestWithRetry<T>(
    Future<Response<T>> Function() request, {
    CancelToken? cancelToken,
    int maxAttempts = 3,
  }) async {
    var delay = const Duration(milliseconds: 350);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (cancelToken?.isCancelled == true) {
        throw const NetworkException('Запрос был отменён.');
      }

      try {
        return await request();
      } on DioException catch (error) {
        if (CancelToken.isCancel(error) ||
            !_canRetry(error) ||
            attempt == maxAttempts) {
          final mapped = error.error;
          if (mapped is AppException) throw mapped;
          throw NetworkException(
            'Не удалось выполнить сетевой запрос.',
            cause: error,
          );
        }
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }

    throw const NetworkException('Не удалось выполнить сетевой запрос.');
  }

  bool _canRetry(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => _isRetryableStatus(
        error.response?.statusCode,
      ),
      _ => false,
    };
  }

  bool _isRetryableStatus(int? statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503;
  }
}
