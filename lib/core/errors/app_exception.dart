sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

final class ParserException extends AppException {
  const ParserException(super.message, {super.cause});
}

final class ProfileException extends AppException {
  const ProfileException(super.message, {super.cause});
}

String userMessageFromError(Object error) {
  if (error is AppException) return error.message;
  return 'Что-то пошло не так. Попробуйте ещё раз.';
}
