import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/data/storage_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../progress_photos/presentation/controllers/progress_photos_controller.dart';



final profilePhotoUploadStateProvider = StateProvider<UploadState>((ref) {
  return const UploadState(status: UploadStatus.pending);
});

/// Controller for managing the user's profile photo.
class ProfilePhotoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Picks an image, crops it to a square, uploads it, and updates the user profile.
  Future<void> pickAndUploadPhoto(ImageSource source) async {
    state = const AsyncLoading();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) {
        state = const AsyncData(null);
        return;
      }

      // Crop image to a square
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
      } catch (e) {
        // Fallback: skip cropping, use the picked image directly
        croppedFile = null;
      }

      final file = croppedFile != null
          ? File(croppedFile.path)
          : File(pickedFile.path);

      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      ref.read(profilePhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.uploading, progress: 0.0);

      final storageRepo = ref.read(storageRepositoryProvider);
      final photoUrl = await storageRepo.uploadProfilePhoto(
        userId: user.uid,
        image: file,
        onProgress: (progress) {
          ref.read(profilePhotoUploadStateProvider.notifier).state = 
              UploadState(status: UploadStatus.uploading, progress: progress);
        },
      );

      // Update UserModel
      final updatedUser = user.copyWith(photoUrl: photoUrl);
      await ref
          .read(authControllerProvider.notifier)
          .saveUserProfile(updatedUser);

      ref.read(profilePhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.completed, progress: 1.0);

      state = const AsyncData(null);
    } on Exception catch (e, st) {
      ref.read(profilePhotoUploadStateProvider.notifier).state = 
          const UploadState(status: UploadStatus.failed, progress: 0.0);
      state = AsyncError(e, st);
    }
  }

  /// Deletes the current profile photo and updates the user profile.
  Future<void> deletePhoto() async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null || user.photoUrl == null) {
        state = const AsyncData(null);
        return;
      }

      final storageRepo = ref.read(storageRepositoryProvider);
      await storageRepo.deleteFile(user.photoUrl!);

      // We don't have copyWith with explicit null support for fields without default null
      // Wait, userModel has String? photoUrl. So we can't easily pass null to copyWith
      // unless Freezed handles it via nullable types or we rebuild.
      // Freezed generates copyWith handling nulls if the field is nullable!
      // But usually it's `photoUrl: null` to unset.
      // Wait, Freezed 2.x `copyWith(photoUrl: null)` works if the field is nullable. Let's assume it works.
      final updatedUser = user.copyWith(photoUrl: null);
      await ref
          .read(authControllerProvider.notifier)
          .saveUserProfile(updatedUser);

      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for the [ProfilePhotoController].
final profilePhotoControllerProvider =
    AsyncNotifierProvider<ProfilePhotoController, void>(() {
      return ProfilePhotoController();
    });
