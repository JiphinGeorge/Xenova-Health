import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../domain/models/progress_photo_model.dart';

class PhotoComparisonScreen extends StatefulWidget {
  const PhotoComparisonScreen({
    required this.photo1,
    required this.photo2,
    super.key,
  });

  final ProgressPhotoModel photo1;
  final ProgressPhotoModel photo2;

  @override
  State<PhotoComparisonScreen> createState() => _PhotoComparisonScreenState();
}

class _PhotoComparisonScreenState extends State<PhotoComparisonScreen> {
  late ProgressPhotoModel _leftPhoto;
  late ProgressPhotoModel _rightPhoto;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    // Default left to older, right to newer
    if (widget.photo1.date.isBefore(widget.photo2.date)) {
      _leftPhoto = widget.photo1;
      _rightPhoto = widget.photo2;
    } else {
      _leftPhoto = widget.photo2;
      _rightPhoto = widget.photo1;
    }
  }

  void _swapPhotos() {
    setState(() {
      final temp = _leftPhoto;
      _leftPhoto = _rightPhoto;
      _rightPhoto = temp;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  Future<void> exportComparison() async {
    // TODO: Implement export generation logic (PDF, Shareable Cards, Before/After reports)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming in future update.'),
      ),
    );
  }

  ImageProvider _getImageProvider(ProgressPhotoModel photo) {
    if (photo.photoUrl.startsWith('http://') ||
        photo.photoUrl.startsWith('https://')) {
      return CachedNetworkImageProvider(photo.photoUrl);
    } else if (photo.photoUrl.startsWith('file://')) {
      return FileImage(File(photo.photoUrl.replaceFirst('file://', '')));
    }
    return const AssetImage('assets/images/placeholder.png');
  }

  @override
  Widget build(BuildContext context) {
    final weightDiff = _rightPhoto.weightAtTime - _leftPhoto.weightAtTime;
    final daysDiff = _rightPhoto.date.difference(_leftPhoto.date).inDays.abs();
    final pctChange = (weightDiff / _leftPhoto.weightAtTime) * 100;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: _isFullscreen ? Colors.black : bgColor,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: const Text('Compare Photos'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _swapPhotos,
                  tooltip: 'Swap Photos',
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullscreen,
                  tooltip: 'Fullscreen',
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed: exportComparison,
                  tooltip: 'Export',
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: _isFullscreen ? 1 : 2,
              child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                image: _getImageProvider(_leftPhoto),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: _buildLabel('Before'),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 4, color: Colors.black),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                image: _getImageProvider(_rightPhoto),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _buildLabel('After'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isFullscreen)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ),
                ],
              ),
            ),
            if (!_isFullscreen) ...[
              const Divider(height: 1),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Weight Diff',
                            '${weightDiff > 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg',
                            weightDiff <= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          _buildStatCard(
                            'Time Elapsed',
                            '$daysDiff Days',
                            AppColors.primary,
                          ),
                          _buildStatCard(
                            '% Change',
                            '${pctChange > 0 ? "+" : ""}${pctChange.toStringAsFixed(1)}%',
                            weightDiff <= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildProgressInsight(weightDiff, daysDiff),
                      const SizedBox(height: AppDimensions.spacingXl),
                      _buildNotesComparison(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesComparison() {
    final leftDate =
        '${_leftPhoto.date.year}-${_leftPhoto.date.month.toString().padLeft(2, '0')}-${_leftPhoto.date.day.toString().padLeft(2, '0')}';
    final rightDate =
        '${_rightPhoto.date.year}-${_rightPhoto.date.month.toString().padLeft(2, '0')}-${_rightPhoto.date.day.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before ($leftDate)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_leftPhoto.weightAtTime} kg',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_leftPhoto.note != null && _leftPhoto.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _leftPhoto.note!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text('No notes.', style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'After ($rightDate)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_rightPhoto.weightAtTime} kg',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_rightPhoto.note != null && _rightPhoto.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _rightPhoto.note!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text('No notes.', style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressInsight(double weightDiff, int daysDiff) {
    if (daysDiff == 0) return const SizedBox.shrink();

    final isLoss = weightDiff < 0;
    final absDiff = weightDiff.abs();
    final weeks = daysDiff / 7.0;
    final avgPerWeek = weeks > 0 ? (absDiff / weeks) : 0.0;

    String insightText;
    if (absDiff < 0.5) {
      insightText =
          'Weight maintained over $daysDiff days. Consistent habits shown.';
    } else {
      final direction = isLoss ? 'decreased' : 'increased';
      insightText =
          'Weight $direction by ${absDiff.toStringAsFixed(1)} kg in $daysDiff days. '
          'Average change: ${avgPerWeek.toStringAsFixed(2)} kg/week. '
          'Visible progress achieved.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Text(
              insightText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
