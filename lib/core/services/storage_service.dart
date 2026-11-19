/// VYRO AI â€” Storage Service
///
/// Wraps Firebase Storage for uploading/downloading videos, thumbnails and
/// AI-generated assets. All file references are under user-scoped paths.


import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import './firebase_service.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  FirebaseStorage get _storage => FirebaseService.instance.storage;

  /// Upload a video file. Returns the download URL.
  Future<String> uploadVideo({
    required String uid,
    required File file,
    String? customFileName,
    ProgressCallback? onProgress,
  }) async {
    final name = customFileName ?? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('users/$uid/videos/$name');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );

    task.snapshotEvents.listen((event) {
      if (onProgress != null) {
        final total = event.totalBytes;
        final transferred = event.bytesTransferred;
        if (total != null && total > 0) {
          onProgress((transferred / total) * 100);
        }
      }
    });

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload an image file. Returns the download URL.
  Future<String> uploadImage({
    required String uid,
    required File file,
    String? customFileName,
    ProgressCallback? onProgress,
  }) async {
    final name = customFileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$uid/images/$name');
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    task.snapshotEvents.listen((event) {
      if (onProgress != null) {
        final total = event.totalBytes;
        final transferred = event.bytesTransferred;
        if (total != null && total > 0) {
          onProgress((transferred / total) * 100);
        }
      }
    });

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a thumbnail.
  Future<String> uploadThumbnail({
    required String uid,
    required File file,
    String? videoId,
  }) async {
    final name = videoId ?? 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$uid/thumbnails/$name');
    final snapshot = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file by download URL.
  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }

  /// Get a download URL for a storage path (e.g. a template preview).
  Future<String?> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

typedef ProgressCallback = void Function(double percent);
