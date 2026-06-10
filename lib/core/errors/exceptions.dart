/// Base exception class for data-layer error handling.
///
/// Exceptions are caught in repositories and converted to [Failure] types
/// for the domain layer. This ensures clean architecture separation.
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Exception thrown by remote data sources (API calls, Firebase operations).
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

/// Exception thrown by local data sources (Hive, SharedPreferences).
class CacheException extends AppException {
  const CacheException({required super.message, super.code, super.stackTrace});
}

/// Exception thrown when the device is offline.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

/// Exception thrown during authentication operations.
class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.stackTrace});
}

/// Exception thrown during Firebase Storage operations.
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}
