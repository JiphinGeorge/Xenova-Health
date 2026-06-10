import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Isolated Firebase Storage service.
///
/// Handles file uploads, downloads, and deletions with
/// progress tracking and metadata management.
class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a file to the specified path.
  ///
  /// Returns the download URL on success.
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
    Map<String, String>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(path);
    final settableMetadata = SettableMetadata(
      contentType: contentType,
      customMetadata: metadata,
    );

    final uploadTask = ref.putFile(file, settableMetadata);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress(progress);
      });
    }

    await uploadTask;
    return ref.getDownloadURL();
  }

  /// Uploads raw bytes to the specified path.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    final ref = _storage.ref(path);
    final settableMetadata = SettableMetadata(
      contentType: contentType ?? 'application/octet-stream',
      customMetadata: metadata,
    );

    await ref.putData(bytes, settableMetadata);
    return ref.getDownloadURL();
  }

  /// Gets the download URL for a file.
  Future<String> getDownloadUrl(String path) async {
    return _storage.ref(path).getDownloadURL();
  }

  /// Deletes a file at the specified path.
  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }

  /// Lists all files in a directory.
  Future<ListResult> listFiles(String path) async {
    return _storage.ref(path).listAll();
  }

  /// Gets metadata for a file.
  Future<FullMetadata> getMetadata(String path) async {
    return _storage.ref(path).getMetadata();
  }
}
