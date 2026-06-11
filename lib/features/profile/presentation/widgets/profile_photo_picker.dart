import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../progress_photos/presentation/controllers/progress_photos_controller.dart';
import '../controllers/profile_photo_controller.dart';

/// A reusable avatar widget that supports picking and displaying a profile photo.
///
/// Handles both network URLs and local file URIs seamlessly.
class ProfilePhotoPicker extends ConsumerWidget {
  const ProfilePhotoPicker({super.key, this.radius = 60});

  final double radius;

  void _showPickerOptions(BuildContext context, WidgetRef ref, bool hasPhoto) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.spacingSm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profilePhotoControllerProvider.notifier)
                      .pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profilePhotoControllerProvider.notifier)
                      .pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(profilePhotoControllerProvider.notifier)
                        .deletePhoto();
                  },
                ),
              const SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final uploadState = ref.watch(profilePhotoUploadStateProvider);
    final isUploading = uploadState.status == UploadStatus.uploading;
    final photoState = ref.watch(profilePhotoControllerProvider);
    final isLoading = photoState.isLoading;

    final photoUrl = user?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasPhoto) {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        imageProvider = CachedNetworkImageProvider(photoUrl);
      } else if (photoUrl.startsWith('file://')) {
        // Strip the file:// prefix for the local File object
        imageProvider = FileImage(File(photoUrl.replaceFirst('file://', '')));
      }
    }

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => _showPickerOptions(context, ref, hasPhoto),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.person,
                    size: radius * 1.2,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  )
                : null,
          ),

          if (isLoading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: isUploading && uploadState.progress > 0 ? uploadState.progress : null,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXs),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(Icons.edit, size: radius * 0.35, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
