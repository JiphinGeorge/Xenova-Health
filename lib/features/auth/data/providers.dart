import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/repositories/auth_repository.dart';
import 'repositories/auth_repository_impl.dart';

/// Provides the authentication repository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  final repository = AuthRepositoryImpl(
    authService: firebaseAuthService,
    firestoreService: firestoreService,
  );

  ref.onDispose(repository.dispose);

  return repository;
});
