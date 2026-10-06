import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../progress_photos/presentation/controllers/progress_photos_controller.dart';
import '../controllers/profile_photo_controller.dart';

/// A reusable avatar widget that supports picking, uploading, and viewing a profile photo.
///
/// Handles both network URLs and local file URIs seamlessly with error recovery.
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
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(profilePhotoControllerProvider.notifier)
                      .pickAndUploadPhoto(ImageSource.camera);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Profile picture updated successfully!'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(profilePhotoControllerProvider.notifier)
                      .pickAndUploadPhoto(ImageSource.gallery);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Profile picture updated successfully!'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
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
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await ref
                        .read(profilePhotoControllerProvider.notifier)
                        .deletePhoto();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Profile picture removed successfully.'),
                            ],
                          ),
                          backgroundColor: Colors.blueGrey,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              const SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage(
    BuildContext context,
    String? photoUrl,
    double radius,
  ) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.person,
          size: radius * 1.2,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      );
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => Center(
          child: Icon(
            Icons.person,
            size: radius * 1.2,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Local file path (with or without file://)
    String path = photoUrl;
    File? file;
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(photoUrl).toFilePath();
        file = File(path);
      } catch (_) {
        path = photoUrl.replaceFirst('file://', '');
        file = File(path);
      }
    } else {
      file = File(path);
    }

    if (file.existsSync()) {
      return Image.file(
        file,
        key: ValueKey(photoUrl),
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.person,
            size: radius * 1.2,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
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

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => _showPickerOptions(context, ref, hasPhoto),
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarImage(context, photoUrl, radius),
            ),
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
                    value: isUploading && uploadState.progress > 0
                        ? uploadState.progress
                        : null,
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
              child: Icon(Icons.camera_alt, size: radius * 0.35, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
