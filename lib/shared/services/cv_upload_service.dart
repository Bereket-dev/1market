import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/syncable_entity.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_reporter.dart';
import 'cloudinary_upload_service.dart';
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
        withData: true,
        withReadStream: false,
      );
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cv_pick');
      return CvUploadError('pick_failed');
    }

    if (result == null || result.files.isEmpty) {
      return CvUploadCancelled();
    }

    final picked = result.files.first;
    final persisted = await _persistPickedFile(
      serviceId: serviceId,
      picked: picked,
    );
    if (persisted == null) {
      return CvUploadError('Could not read the selected file');
    }
    final file = persisted;
    final localPath = file.path;

    // ── Size check ───────────────────────────────────────────────────────────
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

    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      return CvUploadError('unauthorized');
    }

    // ── Try online upload ────────────────────────────────────────────────────
    var queueForLater = false;
    try {
      final userId = client.auth.currentUser?.id ?? 'unknown';
      final upload = await CloudinaryUploadService.instance.uploadRawFile(
        file: file,
        userId: userId,
        serviceId: serviceId,
      );
      if (upload is CloudinaryUploadSuccess) {
        await _box!.delete(serviceId);
        return CvUploadQueued(
          remoteUrl: upload.secureUrl,
          localPath: localPath,
          fileName: fileName,
          status: SyncStatus.synced,
        );
      }
      if (upload is CloudinaryUploadFailure) {
        if (upload.code == CloudinaryFailureCode.network) {
          queueForLater = true;
          if (kDebugMode) {
            debugPrint('CV Cloudinary upload failed, will queue: ${upload.code}');
          }
        } else {
          return CvUploadError(upload.code.name);
        }
      }
    } catch (e, st) {
      if (AppError.isTransientNetwork(e)) {
        queueForLater = true;
        if (kDebugMode) debugPrint('CV upload failed, will queue: $e');
      } else {
        unawaited(ErrorReporter.recordError(e, st, reason: 'cv_upload'));
        return CvUploadError('unexpected');
      }
    }

    if (!queueForLater) {
      return CvUploadError('unexpected');
    }

    // ── Offline queue (network failures only) ────────────────────────────────
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

  /// Copies the picker result into app documents so the file survives cache
  /// cleanup and still exists when an offline upload is flushed later.
  Future<File?> _persistPickedFile({
    required String serviceId,
    required PlatformFile picked,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/cv_uploads/$serviceId');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final rawName = picked.name;
    final ext = rawName.contains('.')
        ? '.${rawName.split('.').last.toLowerCase()}'
        : '';
    final dest = File('${folder.path}/cv$ext');

    try {
      if (await dest.exists()) await dest.delete();
      if (picked.path != null) {
        await File(picked.path!).copy(dest.path);
        return dest;
      }
      final bytes = picked.bytes;
      if (bytes != null) {
        await dest.writeAsBytes(bytes, flush: true);
        return dest;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CV persist failed: $e');
    }
    return null;
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
    final userId = client.auth.currentUser?.id ?? 'unknown';

    final keys = _box!.keys.cast<String>().toList();
    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final pending = PendingCvUpload.fromJson(data);
        if (pending == null) {
          await _box!.delete(key);
          continue;
        }

        final file = File(pending.localPath);
        if (!await file.exists()) {
          await _box!.delete(key);
          continue;
        }

        final result = await CloudinaryUploadService.instance.uploadRawFile(
          file: file,
          userId: userId,
          serviceId: pending.serviceId,
        );

        if (result is CloudinaryUploadSuccess) {
          await onUploaded(pending.serviceId, result.secureUrl);
          await _box!.delete(key);
        } else if (result is CloudinaryUploadFailure) {
          if (kDebugMode) {
            debugPrint('CV upload flush failed for key $key: ${result.code}');
          }
          // Keep in queue for next pass.
        }
      } catch (e) {
        if (kDebugMode) debugPrint('CV upload flush failed for key $key: $e');
      }
    }
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

  /// Moves a queued upload from a local service id to the real Supabase id.
  Future<void> rekeyPendingUpload(String oldServiceId, String newServiceId) async {
    if (oldServiceId == newServiceId) return;
    await initialize();
    final raw = _box!.get(oldServiceId);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data['serviceId'] = newServiceId;
      await _box!.put(newServiceId, jsonEncode(data));
      await _box!.delete(oldServiceId);
    } catch (e) {
      if (kDebugMode) debugPrint('CV rekey failed: $e');
    }
  }
}
