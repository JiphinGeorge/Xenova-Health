import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/progress_photo_model.dart';
import '../../domain/models/progress_photo_model.dart';
import '../controllers/progress_photos_controller.dart';
import '../widgets/add_progress_photo_dialog.dart';
import 'photo_comparison_screen.dart';

/// Screen displaying the user's progress photos.
/// Supports grid and timeline views.
class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  bool _isGridView = true;
  bool _isSelectionMode = false;
  final Set<ProgressPhotoModel> _selectedPhotos = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPhotos.clear();
    });
  }

  void _togglePhotoSelection(ProgressPhotoModel photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        if (_selectedPhotos.length < 2) {
          _selectedPhotos.add(photo);
        } else {
          // If 2 already selected, replace the oldest selection
          _selectedPhotos.remove(_selectedPhotos.first);
          _selectedPhotos.add(photo);
        }
      }
    });
  }

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const AddProgressPhotoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosStreamProvider);
    final uploadState = ref.watch(progressPhotoUploadStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        actions: [
          if (_isSelectionMode)
            TextButton.icon(
              onPressed: _selectedPhotos.length == 2
                  ? () {
                      final list = _selectedPhotos.toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoComparisonScreen(
                            photo1: list[0],
                            photo2: list[1],
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.compare),
              label: const Text('Compare'),
            )
          else
            IconButton(
              icon: const Icon(Icons.compare),
              onPressed: () => _toggleSelectionMode(),
              tooltip: 'Compare Photos',
            ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Timeline View' : 'Grid View',
          ),
        ],
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_back,
                    size: 80,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    'Capture your first transformation photo.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'Track your visual progress over time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Log Progress'),
                  ),
                ],
              ),
            );
          }

          final content = _isGridView
              ? _buildGridView(photos)
              : _buildTimelineView(photos);
              
          return Column(
            children: [
              if (uploadState.status == UploadStatus.uploading)
                LinearProgressIndicator(value: uploadState.progress),
              if (uploadState.status == UploadStatus.failed)
                Container(
                  color: AppColors.error.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Upload failed. Please try again.')),
                      TextButton(
                        onPressed: _showAddDialog,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Expanded(child: content),
            ],
          );
        },
        loading: () => const Center(child: XenovaLoadingIndicator()),
        error: (e, st) =>
            Center(child: XenovaErrorWidget(message: e.toString())),
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            )
          : photosAsync.hasValue && photosAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photo'),
            )
          : null,
    );
  }

  Widget _buildGridView(List<ProgressPhotoModel> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.spacingMd,
        mainAxisSpacing: AppDimensions.spacingMd,
        childAspectRatio: 0.75, // Taller than wide
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = _selectedPhotos.contains(photo);
        return _PhotoCard(
          photo: photo,
          isGrid: true,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: _isSelectionMode ? () => _togglePhotoSelection(photo) : null,
        );
      },
    );
  }

  Widget _buildTimelineView(List<ProgressPhotoModel> photos) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      itemCount: photos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingLg),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = _selectedPhotos.contains(photo);
        return _TimelineCard(
          photo: photo,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: _isSelectionMode ? () => _togglePhotoSelection(photo) : null,
        );
      },
    );
  }
}

class _PhotoCard extends ConsumerWidget {
  const _PhotoCard({
    required this.photo,
    required this.isGrid,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
  });

  final ProgressPhotoModel photo;
  final bool isGrid;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;

  ImageProvider _getImageProvider() {
    if (photo.thumbnailUrl != null && photo.thumbnailUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(photo.thumbnailUrl!);
    } else if (photo.photoUrl.startsWith('http://') ||
        photo.photoUrl.startsWith('https://')) {
      return CachedNetworkImageProvider(photo.photoUrl);
    } else if (photo.photoUrl.startsWith('file://')) {
      return FileImage(File(photo.photoUrl.replaceFirst('file://', '')));
    }
    // Fallback if not recognized
    return const AssetImage('assets/images/placeholder.png');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await ref
            .read(progressPhotosControllerProvider.notifier)
            .deletePhoto(photo);
      } on Exception catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        '${photo.date.year}-${photo.date.month.toString().padLeft(2, '0')}-${photo.date.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      onLongPress: isSelectionMode ? null : () => _delete(context, ref),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 4)
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            isSelected ? AppDimensions.radiusMd - 4 : AppDimensions.radiusMd,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: _getImageProvider(), fit: BoxFit.cover),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${photo.weightAtTime} kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({
    required this.photo,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
  });

  final ProgressPhotoModel photo;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;

  ImageProvider _getImageProvider() {
    if (photo.photoUrl.startsWith('http://') ||
        photo.photoUrl.startsWith('https://')) {
      return CachedNetworkImageProvider(photo.photoUrl);
    } else if (photo.photoUrl.startsWith('file://')) {
      return FileImage(File(photo.photoUrl.replaceFirst('file://', '')));
    }
    return const AssetImage('assets/images/placeholder.png');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await ref
            .read(progressPhotosControllerProvider.notifier)
            .deletePhoto(photo);
      } on Exception catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr =
        '${photo.date.year}-${photo.date.month.toString().padLeft(2, '0')}-${photo.date.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : Colors.white,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 4)
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Image(
                  image: _getImageProvider(),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (!isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: () => _delete(context, ref),
                    ),
                  ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingSm,
                          vertical: AppDimensions.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          '${photo.weightAtTime} kg',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (photo.note != null && photo.note!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      photo.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
