import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/syncable_entity.dart';
import 'offline/hive_sync_store.dart' show HiveSyncStore;

/// Maximum allowed CV file size: 5 MB.
const int kCvMaxBytes = 5 * 1024 * 1024;

/// Describes the current state of a pending CV upload.
class PendingCvUpload {
  const PendingCvUpload({
    required this.serviceId,
    required this.localPath,
    required this.fileName,
    required this.status,
  });

  final String serviceId;
  final String localPath;
  final String fileName;
  final SyncStatus status;

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'localPath': localPath,
        'fileName': fileName,
        'status': status.name,
      };

  static PendingCvUpload? fromJson(Map<String, dynamic> json) {
    try {
      final statusStr = json['status'] as String? ?? 'pending';
      final status = switch (statusStr) {
        'local' => SyncStatus.local,
        'synced' => SyncStatus.synced,
        'failed' => SyncStatus.failed,
        _ => SyncStatus.pending,
      };
      return PendingCvUpload(
        serviceId: json['serviceId'] as String,
        localPath: json['localPath'] as String,
        fileName: json['fileName'] as String,
        status: status,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of a CV pick/upload attempt.
sealed class CvUploadResult {}

/// File exceeds the allowed size limit.
class CvUploadTooLarge extends CvUploadResult {
  final int fileSizeBytes;
  CvUploadTooLarge(this.fileSizeBytes);
}

/// User cancelled the picker without selecting.
class CvUploadCancelled extends CvUploadResult {}

/// File was picked; upload is pending (offline path) or complete (online path).
class CvUploadQueued extends CvUploadResult {
  /// The remote URL if uploaded online, otherwise null (pending).
  final String? remoteUrl;
  final String localPath;
  final String fileName;
  final SyncStatus status;
  CvUploadQueued({
    required this.remoteUrl,
    required this.localPath,
    required this.fileName,
    required this.status,
  });
}

class CvUploadError extends CvUploadResult {
  final String message;
  CvUploadError(this.message);
}

/// Handles CV file picking, validation, Supabase Storage upload, and offline
/// queuing via a dedicated Hive box.
class CvUploadService {
  CvUploadService._();
  static final CvUploadService instance = CvUploadService._();

  static const _boxName = 'pending_cv_uploads_box';
  static const _storageBucket = 'cv-files';

  Box<String>? _box;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    if (!Hive.isBoxOpen(_boxName)) {
      Hive.init(dir.path);
    }
    _box = await Hive.openBox<String>(_boxName);
    _initialized = true;
  }

  /// Presents the system file picker (PDF, JPG, PNG), validates the size,
  /// then either uploads immediately (online) or queues for later (offline).
  ///
  /// Returns a [CvUploadResult] describing the outcome.
  Future<CvUploadResult> pickAndUpload({required String serviceId}) async {
    await initialize();
    await HiveSyncStore.instance.initialize();

    // ── Pick file ────────────────────────────────────────────────────────────
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      return CvUploadError(e.toString());
    }

    if (result == null || result.files.isEmpty) {
      return CvUploadCancelled();
    }

    final picked = result.files.first;
    final localPath = picked.path;
    if (localPath == null) return CvUploadError('Could not read file path');

    // ── Size check ───────────────────────────────────────────────────────────
    final file = File(localPath);
    int fileSize;
    try {
      fileSize = await file.length();
    } catch (_) {
      fileSize = picked.size;
    }
    if (fileSize > kCvMaxBytes) {
      return CvUploadTooLarge(fileSize);
    }

    final fileName = picked.name;

    // ── Try online upload ────────────────────────────────────────────────────
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        final remoteUrl = await _uploadToStorage(client, serviceId, file, fileName);
        return CvUploadQueued(
          remoteUrl: remoteUrl,
          localPath: localPath,
          fileName: fileName,
          status: SyncStatus.synced,
        );
      }
    } catch (e) {
      debugPrint('CV upload failed, will queue: $e');
      // Fall through to offline queue.
    }

    // ── Offline queue ────────────────────────────────────────────────────────
    final pending = PendingCvUpload(
      serviceId: serviceId,
      localPath: localPath,
      fileName: fileName,
      status: SyncStatus.pending,
    );
    await _box!.put(serviceId, jsonEncode(pending.toJson()));

    return CvUploadQueued(
      remoteUrl: null,
      localPath: localPath,
      fileName: fileName,
      status: SyncStatus.pending,
    );
  }

  /// Retries any queued CV uploads. Called from the SyncService sync pass.
  /// On success, calls [onUploaded] with (serviceId, remoteUrl).
  Future<void> flushPendingUploads({
    required Future<void> Function(String serviceId, String remoteUrl)
        onUploaded,
  }) async {
    await initialize();
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;

    final keys = _box!.keys.cast<String>().toList();
    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final pending = PendingCvUpload.fromJson(data);
        if (pending == null) continue;

        final file = File(pending.localPath);
        if (!await file.exists()) {
          // File was deleted — remove from queue silently.
          await _box!.delete(key);
          continue;
        }

        final remoteUrl = await _uploadToStorage(
          client,
          pending.serviceId,
          file,
          pending.fileName,
        );
        await onUploaded(pending.serviceId, remoteUrl);
        await _box!.delete(key);
      } catch (e) {
        debugPrint('CV upload flush failed for key $key: $e');
        // Keep in queue for next pass.
      }
    }
  }

  Future<String> _uploadToStorage(
    SupabaseClient client,
    String serviceId,
    File file,
    String fileName,
  ) async {
    final userId = client.auth.currentUser?.id ?? 'unknown';
    final remotePath = '$userId/$serviceId/$fileName';
    final bytes = await file.readAsBytes();

    // upsert: overwrite if the same path exists.
    await client.storage.from(_storageBucket).uploadBinary(
          remotePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return client.storage.from(_storageBucket).getPublicUrl(remotePath);
  }

  /// Returns the pending upload for [serviceId], or null.
  Future<PendingCvUpload?> getPendingUpload(String serviceId) async {
    await initialize();
    final raw = _box!.get(serviceId);
    if (raw == null) return null;
    try {
      return PendingCvUpload.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
