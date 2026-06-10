import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/progress_photo_model.dart';

/// Repository for managing Progress Photos metadata in Firestore.
class ProgressPhotoRepository {
  ProgressPhotoRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _collectionPath(String userId) => 'users/$userId/progress_photos';

  /// Adds a new progress photo record.
  Future<void> addPhoto(ProgressPhotoModel photo) async {
    await _firestoreService.setDocument(
      path: '${_collectionPath(photo.userId)}/${photo.id}',
      data: photo.toJson(),
    );
  }

  /// Updates an existing progress photo record.
  Future<void> updatePhoto(ProgressPhotoModel photo) async {
    await _firestoreService.updateDocument(
      path: '${_collectionPath(photo.userId)}/${photo.id}',
      data: photo.toJson(),
    );
  }

  /// Deletes a progress photo record.
  Future<void> deletePhoto(String userId, String photoId) async {
    await _firestoreService.deleteDocument(
      '${_collectionPath(userId)}/$photoId',
    );
  }

  /// Streams all progress photos for a given user, ordered by date descending.
  Stream<List<ProgressPhotoModel>> watchProgressPhotos(String userId) {
    return _firestoreService
        .streamCollection(
          path: _collectionPath(userId),
          orderBy: 'date',
          descending: true,
        )
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProgressPhotoModel.fromJson(doc.data());
          }).toList();
        });
  }
}

/// Provider for the [ProgressPhotoRepository].
final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProgressPhotoRepository(firestoreService);
});
