import 'dart:io';

/// Interface defining the contract for file storage operations.
///
/// This abstracts whether the underlying storage is local (placeholder)
/// or remote (Firebase Storage).
abstract interface class StorageRepository {
  /// Uploads a user's profile photo and returns the resulting URI.
  Future<String> uploadProfilePhoto({
    required String userId,
    required File image,
  });

  /// Uploads a progress photo and returns the resulting URI.
  Future<String> uploadProgressPhoto({
    required String userId,
    required String photoId,
    required File image,
  });

  /// Deletes a file at the specified URI.
  Future<void> deleteFile(String pathOrUri);
}
