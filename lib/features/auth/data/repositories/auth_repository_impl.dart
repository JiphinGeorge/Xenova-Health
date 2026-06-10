import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.authService,
    required this.firestoreService,
  }) {
    // Listen to Firebase auth changes and map to our UserModel
    _authSubscription = authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        _authStateController.add(null);
      } else {
        // We only have the minimal user here. Full user comes from Firestore.
        // We trigger a fetch of the profile.
        getUserProfile(firebaseUser.uid).then((userModel) {
          if (userModel != null) {
            _authStateController.add(userModel);
          } else {
            // User exists in Auth but not in Firestore yet (e.g. just signed up)
            final minimalUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName,
              photoUrl: firebaseUser.photoURL,
              createdAt: DateTime.now(),
            );
            _authStateController.add(minimalUser);
          }
        });
      }
    });
  }

  final FirebaseAuthService authService;
  final FirestoreService firestoreService;

  late final StreamSubscription<User?> _authSubscription;
  final _authStateController = StreamController<UserModel?>.broadcast();

  // Firestore collection path
  static const String _usersCollection = 'users';

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser {
    // This is a synchronous getter, we can't fetch from Firestore synchronously.
    // In a real app we might cache the last known UserModel here.
    return null; // The controller will handle the reactive state.
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await authService.signInWithEmail(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Sign in failed');

      final userModel = await getUserProfile(user.uid);
      if (userModel != null) return userModel;

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await authService.signUpWithEmail(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Sign up failed');

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        createdAt: DateTime.now(),
      );

      await saveUserProfile(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // TODO(auth): Implement Google Sign In
    throw UnimplementedError('Google Sign In is not yet implemented');
  }

  @override
  Future<UserModel> signInWithApple() async {
    // TODO(auth): Implement Apple Sign In
    throw UnimplementedError('Apple Sign In is not yet implemented');
  }

  @override
  Future<void> signOut() async {
    await authService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await firestoreService.setDocument(
        path: '$_usersCollection/${user.uid}',
        data: user.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await firestoreService.getDocument(
        '$_usersCollection/$uid',
      );

      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Exception _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided for that user.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }

  void dispose() {
    _authSubscription.cancel();
    _authStateController.close();
  }
}
