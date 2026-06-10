import 'package:firebase_auth/firebase_auth.dart';

/// Isolated Firebase Authentication service.
///
/// All Firebase Auth interactions go through this service,
/// keeping Firebase SDK details out of the repository layer.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Current authenticated user, or null if signed out.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user changes (includes token refresh).
  Stream<User?> get userChanges => _auth.userChanges();

  /// Current user's UID, or null.
  String? get uid => _auth.currentUser?.uid;

  /// Whether the user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Whether the user's email is verified.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Creates a new account with email and password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with a Google credential.
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return _auth.signInWithCredential(credential);
  }

  /// Signs in with an Apple credential.
  Future<UserCredential> signInWithApple(AuthCredential credential) async {
    return _auth.signInWithCredential(credential);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sends an email verification to the current user.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reloads the current user's data.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Updates the current user's display name.
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Updates the current user's photo URL.
  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
  }

  /// Deletes the current user's account.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Re-authenticates the user with email credential (for sensitive operations).
  Future<UserCredential?> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return _auth.currentUser?.reauthenticateWithCredential(credential);
  }
}
