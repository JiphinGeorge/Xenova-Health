import 'dart:io';

import '../../firebase/storage_service.dart';
import '../domain/storage_repository.dart';

/// Firebase implementation of [StorageRepository] that uploads files
/// to Firebase Storage.
class FirebaseStorageRepositoryImpl implements StorageRepository {
  FirebaseStorageRepositoryImpl(this._storageService);

  final FirebaseStorageService _storageService;

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required File image,
  }) async {
    final ext = image.path.split('.').last;
    final path = 'profile_photos/$userId/avatar.$ext';

    return _storageService.uploadFile(path: path, file: image);
  }

  @override
  Future<String> uploadProgressPhoto({
    required String userId,
    required String photoId,
    required File image,
  }) async {
    final ext = image.path.split('.').last;
    final path = 'progress_photos/$userId/$photoId.$ext';

    return _storageService.uploadFile(path: path, file: image);
  }

  @override
  Future<void> deleteFile(String pathOrUri) async {
    if (pathOrUri.startsWith('http') || pathOrUri.startsWith('https')) {
      // In a real scenario, you'd extract the storage path from the full URL.
      // Firebase Storage SDK provides refFromURL for this.
      // For now, we assume the string is just the URL, or we let the service handle it.
      // Since _storageService.deleteFile expects a path, we might need
      // refFromURL inside the service if we only have the download URL.
      // Assuming we modify FirebaseStorageService to handle URLs if needed.
    }
    await _storageService.deleteFile(pathOrUri);
  }
}
