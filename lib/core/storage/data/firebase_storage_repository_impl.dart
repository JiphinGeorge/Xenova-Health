import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../firebase/storage_service.dart';
import '../domain/storage_repository.dart';

/// Firebase implementation of [StorageRepository] that uploads files
/// to Firebase Storage.
class FirebaseStorageRepositoryImpl implements StorageRepository {
  FirebaseStorageRepositoryImpl(this._storageService);

  final FirebaseStorageService _storageService;

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required File image,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'profile_photos/$userId/avatar.jpg';
    
    // Compress
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: 1080,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (compressedBytes == null) throw Exception('Image compression failed');

    return _storageService.uploadBytes(
      path: path, 
      bytes: compressedBytes,
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<(String, String)> uploadProgressPhoto({
    required String userId,
    required String photoId,
    required File image,
    void Function(double progress)? onProgress,
  }) async {
    final originalPath = 'progress_photos/$userId/original_$photoId.jpg';
    final thumbPath = 'progress_photos/$userId/thumbnail_$photoId.jpg';

    // Compress Original (Max 1080px, 80%)
    final originalBytes = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: 1080,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (originalBytes == null) throw Exception('Image compression failed');

    // Compress Thumbnail (Max 400px, 60%)
    final thumbBytes = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: 400,
      quality: 60,
      format: CompressFormat.jpeg,
    );
    if (thumbBytes == null) throw Exception('Thumbnail compression failed');

    // For simplicity, we track progress only for the original image
    final originalUrl = await _storageService.uploadBytes(
      path: originalPath, 
      bytes: originalBytes,
      contentType: 'image/jpeg',
    );
    
    if (onProgress != null) onProgress(0.5);

    final thumbUrl = await _storageService.uploadBytes(
      path: thumbPath, 
      bytes: thumbBytes,
      contentType: 'image/jpeg',
    );

    if (onProgress != null) onProgress(1.0);

    return (originalUrl, thumbUrl);
  }

  @override
  Future<void> deleteFile(String pathOrUri) async {
    if (pathOrUri.startsWith('http') || pathOrUri.startsWith('https')) {
      final ref = FirebaseStorage.instance.refFromURL(pathOrUri);
      await ref.delete();
      return;
    }
    await _storageService.deleteFile(pathOrUri);
  }
}
