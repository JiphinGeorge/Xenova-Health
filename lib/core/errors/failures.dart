/// Base failure class for domain-level error handling.
///
/// All failures in the application extend this class, enabling
/// typed error handling without throwing exceptions in business logic.
abstract class Failure {
  const Failure({required this.message, this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Failure($code): $message';
}

/// Failure originating from a server/API response.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

/// Failure originating from local cache operations.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.stackTrace});
}

/// Failure due to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

/// Failure from Firebase Authentication operations.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.stackTrace});

  /// Maps Firebase Auth error codes to user-friendly messages.
  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthFailure(
          message: 'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthFailure(
          message: 'Incorrect password. Please try again.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          message: 'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          message: 'Password is too weak. Use at least 8 characters.',
          code: 'weak-password',
        );
      case 'invalid-email':
        return const AuthFailure(
          message: 'Invalid email address.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          message: 'This account has been disabled.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many attempts. Please try again later.',
          code: 'too-many-requests',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          message: 'This sign-in method is not enabled.',
          code: 'operation-not-allowed',
        );
      case 'account-exists-with-different-credential':
        return const AuthFailure(
          message: 'An account already exists with a different sign-in method.',
          code: 'account-exists-with-different-credential',
        );
      default:
        return AuthFailure(
          message: 'Authentication failed. Please try again.',
          code: code,
        );
    }
  }
}

/// Failure from Firestore database operations.
class FirestoreFailure extends Failure {
  const FirestoreFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Failure from Firebase Storage operations.
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code, super.stackTrace});
}

/// Failure from input validation.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.stackTrace,
    this.field,
  });

  /// The field name that failed validation.
  final String? field;
}

/// Failure from permission-related issues.
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_DENIED',
    super.stackTrace,
  });
}

/// Failure related to data sync conflicts.
class SyncFailure extends Failure {
  const SyncFailure({
    required super.message,
    super.code = 'SYNC_ERROR',
    super.stackTrace,
  });
}
