import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/progress_photo_model.dart';

/// Repository for managing Progress Photos metadata locally and in Firestore.
class ProgressPhotoRepository {
  ProgressPhotoRepository(this._firestoreService);

  final FirestoreService _firestoreService;
  final _photosController =
      StreamController<List<ProgressPhotoModel>>.broadcast();

  String _collectionPath(String userId) => 'users/$userId/progress_photos';
  String _cacheKey(String userId) => 'progress_photos_$userId';

  List<ProgressPhotoModel> _loadLocalPhotos(String userId) {
    if (!Hive.isBoxOpen(AppConstants.cacheBox)) return [];
    try {
      final raw = Hive.box<dynamic>(
        AppConstants.cacheBox,
      ).get(_cacheKey(userId));
      if (raw is List) {
        final list = raw.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProgressPhotoModel.fromJson(map);
        }).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalPhotos(
    String userId,
    List<ProgressPhotoModel> photos,
  ) async {
    if (!Hive.isBoxOpen(AppConstants.cacheBox)) return;
    try {
      final list = photos.map((p) => p.toJson()).toList();
      await Hive.box<dynamic>(
        AppConstants.cacheBox,
      ).put(_cacheKey(userId), list);
      _photosController.add(photos);
    } catch (_) {}
  }

  /// Adds a new progress photo record locally and attempts Firestore sync.
  Future<void> addPhoto(ProgressPhotoModel photo) async {
    final current = _loadLocalPhotos(photo.userId);
    current.removeWhere((p) => p.id == photo.id);
    current.insert(0, photo);
    current.sort((a, b) => b.date.compareTo(a.date));
    await _saveLocalPhotos(photo.userId, current);

    try {
      await _firestoreService.setDocument(
        path: '${_collectionPath(photo.userId)}/${photo.id}',
        data: photo.toJson(),
      );
    } catch (_) {}
  }

  /// Updates an existing progress photo record locally and in Firestore.
  Future<void> updatePhoto(ProgressPhotoModel photo) async {
    final current = _loadLocalPhotos(photo.userId);
    final index = current.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      current[index] = photo;
    } else {
      current.add(photo);
    }
    current.sort((a, b) => b.date.compareTo(a.date));
    await _saveLocalPhotos(photo.userId, current);

    try {
      await _firestoreService.updateDocument(
        path: '${_collectionPath(photo.userId)}/${photo.id}',
        data: photo.toJson(),
      );
    } catch (_) {}
  }

  /// Deletes a progress photo record locally and from Firestore.
  Future<void> deletePhoto(String userId, String photoId) async {
    final current = _loadLocalPhotos(userId);
    current.removeWhere((p) => p.id == photoId);
    await _saveLocalPhotos(userId, current);

    try {
      await _firestoreService.deleteDocument(
        '${_collectionPath(userId)}/$photoId',
      );
    } catch (_) {}
  }

  /// Streams all progress photos for a given user, ordered by date descending.
  Stream<List<ProgressPhotoModel>> watchProgressPhotos(String userId) {
    late final StreamController<List<ProgressPhotoModel>> controller;
    StreamSubscription<List<ProgressPhotoModel>>? localSub;
    StreamSubscription<dynamic>? firestoreSub;

    controller = StreamController<List<ProgressPhotoModel>>(
      onListen: () {
        // Emit current cached local photos immediately
        final localList = _loadLocalPhotos(userId);
        controller.add(localList);

        localSub = _photosController.stream.listen((photos) {
          if (!controller.isClosed) {
            controller.add(photos);
          }
        });

        // Best-effort remote listening
        try {
          firestoreSub = _firestoreService
              .streamCollection(
                path: _collectionPath(userId),
                orderBy: 'date',
                descending: true,
              )
              .listen(
                (snapshot) {
                  final remoteList = snapshot.docs.map((doc) {
                    return ProgressPhotoModel.fromJson(doc.data());
                  }).toList();

                  final currentLocal = _loadLocalPhotos(userId);
                  final map = {for (final p in remoteList) p.id: p};
                  for (final p in currentLocal) {
                    map.putIfAbsent(p.id, () => p);
                  }
                  final merged = map.values.toList();
                  merged.sort((a, b) => b.date.compareTo(a.date));
                  _saveLocalPhotos(userId, merged);
                },
                onError: (_) {
                  // Keep using local state if Firestore stream fails or is offline
                },
              );
        } catch (_) {}
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Provider for the [ProgressPhotoRepository].
final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProgressPhotoRepository(firestoreService);
});
