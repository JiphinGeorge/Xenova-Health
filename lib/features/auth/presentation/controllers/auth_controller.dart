import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../gamification/application/services/achievement_engine_service.dart';

/// Controller managing the global authentication state.
class AuthController extends AsyncNotifier<UserModel?> {
  late final AuthRepository _repository;

  @override
  FutureOr<UserModel?> build() {
    _repository = ref.watch(authRepositoryProvider);

    // Subscribe to auth state changes from repository
    final sub = _repository.authStateChanges.listen((user) {
      state = AsyncData(user);
      if (user != null) {
        // Gamification Hook for daily logins
        ref.read(achievementEngineProvider).processLoginEvent();
      }
    });

    ref.onDispose(sub.cancel);

    return _repository.currentUser;
  }

  /// Signs the user in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Registers a new user with email and password.
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Signs the user out.
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _repository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates and saves the user profile in Firestore.
  Future<void> saveUserProfile(UserModel user) async {
    state = const AsyncLoading();
    try {
      await _repository.saveUserProfile(user);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Provider for the [AuthController].
final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(() {
      return AuthController();
    });
