import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../gamification/application/services/achievement_engine_service.dart';
import '../../../../core/storage/data/storage_provider.dart';
import '../../data/repositories/progress_photo_repository.dart';
import '../../domain/models/progress_photo_model.dart';

enum UploadStatus { pending, uploading, completed, failed }

class UploadState {
  final UploadStatus status;
  final double progress;
  
  const UploadState({
    required this.status,
    this.progress = 0.0,
  });
}

final progressPhotoUploadStateProvider = StateProvider<UploadState>((ref) {
  return const UploadState(status: UploadStatus.pending);
});

/// Stream of the current user's progress photos.
final progressPhotosStreamProvider = StreamProvider<List<ProgressPhotoModel>>((
  ref,
) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(progressPhotoRepositoryProvider);
  return repository.watchProgressPhotos(user.uid);
});

/// Controller for managing progress photos (uploading and deleting).
class ProgressPhotosController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Uploads a new progress photo and saves metadata to Firestore.
  Future<void> addPhoto({
    required File image,
    required double weight,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final photoId = const Uuid().v4();
      final storageRepo = ref.read(storageRepositoryProvider);

      ref.read(progressPhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.uploading, progress: 0.0);

      final result = await storageRepo.uploadProgressPhoto(
        userId: user.uid,
        photoId: photoId,
        image: image,
        onProgress: (progress) {
          ref.read(progressPhotoUploadStateProvider.notifier).state = 
              UploadState(status: UploadStatus.uploading, progress: progress);
        },
      );
      final photoUrl = result.$1;
      final thumbnailUrl = result.$2;

      final bytes = await image.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      final photo = ProgressPhotoModel(
        id: photoId,
        userId: user.uid,
        photoUrl: photoUrl,
        thumbnailUrl: thumbnailUrl,
        weightAtTime: weight,
        date: DateTime.now(),
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );

      await ref.read(progressPhotoRepositoryProvider).addPhoto(photo);

      // Trigger achievement hooks asynchronously
      _checkMilestones(photo);

      ref.read(progressPhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.completed, progress: 1.0);

      state = const AsyncData(null);
    } catch (e, st) {
      ref.read(progressPhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.failed, progress: 0.0);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void _checkMilestones(ProgressPhotoModel newPhoto) {
    Future.delayed(const Duration(seconds: 1), () {
      final photos = ref.read(progressPhotosStreamProvider).value ?? [];

      if (photos.isEmpty || photos.length == 1) {
        ref.read(achievementEngineProvider).processProgressPhotoEvent(1);
        return;
      }

      final firstPhoto = photos.last; // Ordered newest first usually
      final daysDiff = newPhoto.date.difference(firstPhoto.date).inDays;

      ref.read(achievementEngineProvider).processProgressPhotoEvent(daysDiff);
    });
  }

  /// Deletes a progress photo from storage and Firestore.
  Future<void> deletePhoto(ProgressPhotoModel photo) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final storageRepo = ref.read(storageRepositoryProvider);
      await storageRepo.deleteFile(photo.photoUrl);
      if (photo.thumbnailUrl != null) {
        await storageRepo.deleteFile(photo.thumbnailUrl!);
      }

      final repository = ref.read(progressPhotoRepositoryProvider);
      await repository.deletePhoto(user.uid, photo.id);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Deletes all progress photos for the current user.
  Future<void> deleteAllPhotos() async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final photos = ref.read(progressPhotosStreamProvider).value ?? [];
      final storageRepo = ref.read(storageRepositoryProvider);
      final repository = ref.read(progressPhotoRepositoryProvider);

      for (final photo in photos) {
        try {
          await storageRepo.deleteFile(photo.photoUrl);
          if (photo.thumbnailUrl != null) {
            await storageRepo.deleteFile(photo.thumbnailUrl!);
          }
        } catch (_) {
          // Ignore storage deletion errors to continue deleting metadata
        }
        await repository.deletePhoto(user.uid, photo.id);
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Provider for [ProgressPhotosController].
final progressPhotosControllerProvider =
    AsyncNotifierProvider<ProgressPhotosController, void>(() {
      return ProgressPhotosController();
    });
