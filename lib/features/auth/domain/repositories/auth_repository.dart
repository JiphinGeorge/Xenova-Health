import '../models/user_model.dart';

/// Abstract interface for authentication operations.
///
/// Ensures the presentation layer is decoupled from Firebase implementation details.
abstract interface class AuthRepository {
  /// Stream of the current authenticated user's model.
  Stream<UserModel?> get authStateChanges;

  /// Gets the current authenticated user synchronously.
  UserModel? get currentUser;

  /// Signs in with email and password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in with Google credential.
  Future<UserModel> signInWithGoogle();

  /// Signs in with Apple credential.
  Future<UserModel> signInWithApple();

  /// Signs out the current user.
  Future<void> signOut();

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Saves or updates the user profile data in the database.
  Future<void> saveUserProfile(UserModel user);

  /// Retrieves the user profile from the database by UID.
  Future<UserModel?> getUserProfile(String uid);
}
