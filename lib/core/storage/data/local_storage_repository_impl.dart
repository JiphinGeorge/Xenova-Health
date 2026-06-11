// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/storage_repository.dart';

/// Local implementation of [StorageRepository] that saves files directly
/// to the device's application documents directory.
///
/// Returns absolute `file://` URIs.
class LocalStorageRepositoryImpl implements StorageRepository {
  /// Gets the local directory dedicated to this app's storage.
  Future<Directory> _getStorageDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${root.path}/xenova_storage');
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    // Future-proof directory structure
    final profileDir = Directory('${storageDir.path}/profile_photos');
    final progressDir = Directory('${storageDir.path}/progress_photos');
    final exportsDir = Directory('${storageDir.path}/exports');

    if (!await profileDir.exists()) await profileDir.create();
    if (!await progressDir.exists()) await progressDir.create();
    if (!await exportsDir.exists()) await exportsDir.create();

    return storageDir;
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required File image,
    void Function(double progress)? onProgress,
  }) async {
    final storageDir = await _getStorageDirectory();
    final profileDir = Directory('${storageDir.path}/profile_photos/$userId');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final ext = image.path.split('.').last;
    final savedFile = await image.copy('${profileDir.path}/avatar.$ext');
    if (onProgress != null) onProgress(1.0);
    return 'file://${savedFile.path}';
  }

  @override
  Future<(String, String)> uploadProgressPhoto({
    required String userId,
    required String photoId,
    required File image,
    void Function(double progress)? onProgress,
  }) async {
    final storageDir = await _getStorageDirectory();
    final progressDir = Directory('${storageDir.path}/progress_photos/$userId');
    if (!await progressDir.exists()) {
      await progressDir.create(recursive: true);
    }

    final ext = image.path.split('.').last;
    final originalFile = await image.copy('${progressDir.path}/$photoId.$ext');
    final thumbnailFile = await image.copy('${progressDir.path}/${photoId}_thumb.$ext');
    
    if (onProgress != null) onProgress(1.0);
    return ('file://${originalFile.path}', 'file://${thumbnailFile.path}');
  }

  @override
  Future<void> deleteFile(String pathOrUri) async {
    if (!pathOrUri.startsWith('file://')) return;

    final path = pathOrUri.replaceFirst('file://', '');
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
