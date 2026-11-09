sealed class AppError {
  const AppError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$runtimeType($code)';
}

final class NetworkError extends AppError {
  const NetworkError([String message = 'Network request failed'])
    : super('network', message);
}

final class TimeoutAppError extends AppError {
  const TimeoutAppError([String message = 'Operation timed out'])
    : super('timeout', message);
}

final class RateLimitError extends AppError {
  const RateLimitError({this.retryAfter, String message = 'Rate limited'})
    : super('rate_limit', message);

  final Duration? retryAfter;
}

final class AuthAppError extends AppError {
  const AuthAppError([String message = 'Authentication required'])
    : super('auth', message);
}

final class ValidationAppError extends AppError {
  const ValidationAppError([String message = 'Input is invalid'])
    : super('validation', message);
}

final class StorageError extends AppError {
  const StorageError([String message = 'Storage operation failed'])
    : super('storage', message);
}

final class NotFoundAppError extends AppError {
  const NotFoundAppError([String message = 'Resource not found'])
    : super('not_found', message);
}

final class UnavailableError extends AppError {
  const UnavailableError([String message = 'Service unavailable'])
    : super('unavailable', message);
}

final class UnknownAppError extends AppError {
  const UnknownAppError([String message = 'Unexpected failure'])
    : super('unknown', message);
}
