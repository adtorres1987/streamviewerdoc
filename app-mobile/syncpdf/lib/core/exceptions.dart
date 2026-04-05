/// Sealed hierarchy of typed app exceptions.
/// All service layer errors must be caught and rethrown as one of these.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Device has no network connectivity or the request timed out.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'No network connection. Please try again.']);
}

/// Authentication-related failures: wrong credentials, expired token, etc.
final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed.']);
}

/// The server returned a 4xx/5xx with a parseable error body.
final class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again later.']);

  /// HTTP status code from the server response, if available.
  factory ServerException.withStatus(int statusCode, String message) =
      _ServerExceptionWithStatus;
}

final class _ServerExceptionWithStatus extends ServerException {
  const _ServerExceptionWithStatus(this.statusCode, String message) : super(message);
  final int statusCode;
}

/// Catch-all for unexpected errors that don't fit the categories above.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
