import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../domain/storage_repository.dart';
import 'firebase_storage_repository_impl.dart';
import 'local_storage_repository_impl.dart';

/// Provides the globally configured [StorageRepository].
///
/// Conditionally injects [FirebaseStorageRepositoryImpl] or [LocalStorageRepositoryImpl]
/// based on the `USE_FIREBASE_STORAGE` environment variable.
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  // Read from dotenv config. Defaults to false if not found.
  final useFirebase =
      dotenv.env['USE_FIREBASE_STORAGE']?.toLowerCase() == 'true';

  if (useFirebase) {
    final firebaseStorageService = ref.watch(firebaseStorageServiceProvider);
    return FirebaseStorageRepositoryImpl(firebaseStorageService);
  } else {
    return LocalStorageRepositoryImpl();
  }
});
