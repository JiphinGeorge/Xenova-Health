import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  UserModel? _cachedUser;

  AuthRepositoryImpl({
    required this.authService,
    required this.firestoreService,
  }) {
    // Listen to Firebase auth changes and map to our UserModel
    _authSubscription = authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        _cachedUser = null;
        if (Hive.isBoxOpen(AppConstants.userBox)) {
          try {
            Hive.box<dynamic>(AppConstants.userBox).delete('current_user');
          } catch (_) {}
        }
        _authStateController.add(null);
      } else {
        getUserProfile(firebaseUser.uid).then((userModel) {
          if (userModel != null) {
            _cachedUser = userModel;
            _authStateController.add(userModel);
          } else {
            final fallbackUser = _cachedUser ?? UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName,
              photoUrl: firebaseUser.photoURL,
              createdAt: DateTime.now(),
            );
            _cachedUser = fallbackUser;
            _authStateController.add(fallbackUser);
          }
        }).catchError((_) {
          final fallbackUser = _cachedUser ?? UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            createdAt: DateTime.now(),
          );
          _cachedUser = fallbackUser;
          _authStateController.add(fallbackUser);
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
    if (_cachedUser != null) return _cachedUser;

    if (Hive.isBoxOpen(AppConstants.userBox)) {
      try {
        final raw = Hive.box<dynamic>(AppConstants.userBox).get('current_user');
        if (raw != null) {
          _cachedUser = UserModel.fromJson(Map<String, dynamic>.from(raw as Map));
          return _cachedUser;
        }
      } catch (_) {}
    }

    final fbUser = authService.currentUser;
    if (fbUser != null) {
      return UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName,
        photoUrl: fbUser.photoURL,
        createdAt: DateTime.now(),
      );
    }
    return null;
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
    _cachedUser = user;
    _authStateController.add(user);

    if (Hive.isBoxOpen(AppConstants.userBox)) {
      try {
        await Hive.box<dynamic>(AppConstants.userBox).put('current_user', user.toJson());
      } catch (_) {}
    }

    try {
      await firestoreService.setDocument(
        path: '$_usersCollection/${user.uid}',
        data: user.toJson(),
      );
    } catch (_) {
      // Local state remains persisted in Hive even when offline
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await firestoreService.getDocument(
        '$_usersCollection/$uid',
      );

      if (snapshot.exists && snapshot.data() != null) {
        final user = UserModel.fromJson(snapshot.data()!);
        _cachedUser = user;
        if (Hive.isBoxOpen(AppConstants.userBox)) {
          try {
            await Hive.box<dynamic>(AppConstants.userBox).put('current_user', user.toJson());
          } catch (_) {}
        }
        return user;
      }
    } catch (_) {}

    if (Hive.isBoxOpen(AppConstants.userBox)) {
      try {
        final raw = Hive.box<dynamic>(AppConstants.userBox).get('current_user');
        if (raw != null) {
          final user = UserModel.fromJson(Map<String, dynamic>.from(raw as Map));
          _cachedUser = user;
          return user;
        }
      } catch (_) {}
    }

    return null;
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
