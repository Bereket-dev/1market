import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

enum SyncStatus { local, pending, synced, failed }

mixin SyncableEntity {
  String get id;
  DateTime get localUpdatedAt;
  DateTime? get remoteUpdatedAt;
  SyncStatus get syncStatus;
}

class HiveSyncStore {
  HiveSyncStore._();

  static final HiveSyncStore instance = HiveSyncStore._();

  static bool _initialized = false;

  late Box<String> _authBox;
  late Box<String> _languageBox;
  late Box<String> _themeBox;
  late Box<String> _draftListingsBox;
  late Box<String> _pendingProfileEditsBox;
  late Box<String> _pendingServiceEditsBox;
  late Box<String> _pendingServiceDeletesBox;
  late Box<String> _pendingMessagesBox;
  late Box<String> _conflictsBox;
  late Box<String> _imageCacheBox;
  late Box<String> _metaBox;
  late Box<String> _listingsCacheBox;
  late Box<String> _profileCacheBox;
  // Phase C Part 2 boxes
  late Box<String> _pendingHiringPostEditsBox;
  late Box<String> _pendingHiringPostDeletesBox;
  late Box<String> _pendingApplicationsBox;
  late Box<String> _pendingApplicationStatusUpdatesBox;

  // Profile photo upload queue
  late Box<String> _pendingPhotoUploadsBox;

  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    _authBox = await Hive.openBox<String>('auth_session_box');
    _languageBox = await Hive.openBox<String>('language_box');
    _themeBox = await Hive.openBox<String>('theme_box');
    _draftListingsBox = await Hive.openBox<String>('draft_listings_box');
    _pendingProfileEditsBox = await Hive.openBox<String>(
      'pending_profile_edits_box',
    );
    _pendingServiceEditsBox = await Hive.openBox<String>(
      'pending_service_edits_box',
    );
    _pendingServiceDeletesBox = await Hive.openBox<String>(
      'pending_service_deletes_box',
    );
    _pendingMessagesBox = await Hive.openBox<String>('pending_messages_box');
    _conflictsBox = await Hive.openBox<String>('conflicts_box');
    _imageCacheBox = await Hive.openBox<String>('image_cache_box');
    _metaBox = await Hive.openBox<String>('meta_box');
    _listingsCacheBox = await Hive.openBox<String>('listings_cache_box');
    _profileCacheBox = await Hive.openBox<String>('profile_cache_box');

    // Phase C Part 2 boxes
    _pendingHiringPostEditsBox =
        await Hive.openBox<String>('pending_hiring_post_edits_box');
    _pendingHiringPostDeletesBox =
        await Hive.openBox<String>('pending_hiring_post_deletes_box');
    _pendingApplicationsBox =
        await Hive.openBox<String>('pending_applications_box');
    _pendingApplicationStatusUpdatesBox =
        await Hive.openBox<String>('pending_application_status_updates_box');
    _pendingPhotoUploadsBox =
        await Hive.openBox<String>('pending_photo_uploads_box');

    await _enforceImageCacheLimit();
    _initialized = true;
  }

  Future<void> setAuthSession(String? value) async {
    await _ensureInitialized();
    if (value == null) {
      await _authBox.delete('session');
      return;
    }
    await _authBox.put('session', value);
  }

  String? getAuthSession() {
    return _authBox.get('session');
  }

  Future<void> setLanguage(String value) async {
    await _ensureInitialized();
    await _languageBox.put('language', value);
  }

  String? getLanguage() => _languageBox.get('language');

  Future<void> setTheme(String value) async {
    await _ensureInitialized();
    await _themeBox.put('theme', value);
  }

  String? getTheme() => _themeBox.get('theme');

  Future<void> saveDraftListing(String id, String payload) async {
    await _ensureInitialized();
    await _draftListingsBox.put(id, payload);
  }

  String? readDraftListing(String id) => _draftListingsBox.get(id);

  Future<void> deleteDraftListing(String id) async {
    await _ensureInitialized();
    await _draftListingsBox.delete(id);
  }

  Future<void> savePendingProfileEdit(String id, String payload) async {
    await _ensureInitialized();
    await _pendingProfileEditsBox.put(id, payload);
  }

  String? readPendingProfileEdit(String id) => _pendingProfileEditsBox.get(id);

  Future<void> deletePendingProfileEdit(String id) async {
    await _ensureInitialized();
    await _pendingProfileEditsBox.delete(id);
  }

  Future<void> savePendingServiceEdit(String id, String payload) async {
    await _ensureInitialized();
    await _pendingServiceEditsBox.put(id, payload);
  }

  String? readPendingServiceEdit(String id) => _pendingServiceEditsBox.get(id);

  Future<void> deletePendingServiceEdit(String id) async {
    await _ensureInitialized();
    await _pendingServiceEditsBox.delete(id);
  }

  Future<void> savePendingServiceDelete(String id, String payload) async {
    await _ensureInitialized();
    await _pendingServiceDeletesBox.put(id, payload);
  }

  String? readPendingServiceDelete(String id) =>
      _pendingServiceDeletesBox.get(id);

  Future<void> deletePendingServiceDelete(String id) async {
    await _ensureInitialized();
    await _pendingServiceDeletesBox.delete(id);
  }

  Future<void> savePendingMessage(String id, String payload) async {
    await _ensureInitialized();
    await _pendingMessagesBox.put(id, payload);
  }

  String? readPendingMessage(String id) => _pendingMessagesBox.get(id);

  Future<void> deletePendingMessage(String id) async {
    await _ensureInitialized();
    await _pendingMessagesBox.delete(id);
  }

  Future<void> cacheListing(String id, String payload) async {
    await _ensureInitialized();
    await _listingsCacheBox.put(id, payload);
  }

  String? readListingCache(String id) => _listingsCacheBox.get(id);

  Future<List<String>> getDraftListingIds() async {
    await _ensureInitialized();
    return _draftListingsBox.keys.cast<String>().toList();
  }

  Future<List<String>> getPendingProfileEditIds() async {
    await _ensureInitialized();
    return _pendingProfileEditsBox.keys.cast<String>().toList();
  }

  Future<List<String>> getPendingServiceEditIds() async {
    await _ensureInitialized();
    return _pendingServiceEditsBox.keys.cast<String>().toList();
  }

  Future<List<String>> getPendingServiceDeleteIds() async {
    await _ensureInitialized();
    return _pendingServiceDeletesBox.keys.cast<String>().toList();
  }

  Future<List<String>> getPendingMessageIds() async {
    await _ensureInitialized();
    return _pendingMessagesBox.keys.cast<String>().toList();
  }

  Future<void> cacheAllListings(String payload) async {
    await _ensureInitialized();
    await _listingsCacheBox.put('all', payload);
  }

  String? readAllListingsCache() => _listingsCacheBox.get('all');

  Future<void> cacheUserProfile(String userId, String payload) async {
    await _ensureInitialized();
    await _profileCacheBox.put(userId, payload);
  }

  String? readUserProfileCache(String userId) => _profileCacheBox.get(userId);

  Future<void> saveConflict(String key, String payload) async {
    await _ensureInitialized();
    await _conflictsBox.put(key, payload);
  }

  Future<void> clearExpiredConflicts() async {
    await _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    final keys = _conflictsBox.keys.toList();
    for (final key in keys) {
      final value = _conflictsBox.get(key);
      if (value == null) continue;
      final parts = value.split('|');
      if (parts.length == 2) {
        final createdAt = int.tryParse(parts[0]) ?? 0;
        if (now - createdAt > 24 * 60 * 60 * 1000) {
          await _conflictsBox.delete(key);
        }
      }
    }
  }

  // ── Phase C Part 2: Hiring post edits ────────────────────────────────────────
  Future<void> savePendingHiringPostEdit(String id, String payload) async {
    await _ensureInitialized();
    await _pendingHiringPostEditsBox.put(id, payload);
  }

  String? readPendingHiringPostEdit(String id) =>
      _pendingHiringPostEditsBox.get(id);

  Future<void> deletePendingHiringPostEdit(String id) async {
    await _ensureInitialized();
    await _pendingHiringPostEditsBox.delete(id);
  }

  Future<List<String>> getPendingHiringPostEditIds() async {
    await _ensureInitialized();
    return _pendingHiringPostEditsBox.keys.cast<String>().toList();
  }

  // ── Phase C Part 2: Hiring post deletes ──────────────────────────────────────
  Future<void> savePendingHiringPostDelete(String id, String payload) async {
    await _ensureInitialized();
    await _pendingHiringPostDeletesBox.put(id, payload);
  }

  String? readPendingHiringPostDelete(String id) =>
      _pendingHiringPostDeletesBox.get(id);

  Future<void> deletePendingHiringPostDelete(String id) async {
    await _ensureInitialized();
    await _pendingHiringPostDeletesBox.delete(id);
  }

  Future<List<String>> getPendingHiringPostDeleteIds() async {
    await _ensureInitialized();
    return _pendingHiringPostDeletesBox.keys.cast<String>().toList();
  }

  // ── Phase C Part 2: Applications ─────────────────────────────────────────────
  Future<void> savePendingApplication(String id, String payload) async {
    await _ensureInitialized();
    await _pendingApplicationsBox.put(id, payload);
  }

  String? readPendingApplication(String id) =>
      _pendingApplicationsBox.get(id);

  Future<void> deletePendingApplication(String id) async {
    await _ensureInitialized();
    await _pendingApplicationsBox.delete(id);
  }

  Future<List<String>> getPendingApplicationIds() async {
    await _ensureInitialized();
    return _pendingApplicationsBox.keys.cast<String>().toList();
  }

  // ── Phase C Part 2: Application status updates ───────────────────────────────
  Future<void> savePendingApplicationStatusUpdate(
    String id,
    String payload,
  ) async {
    await _ensureInitialized();
    await _pendingApplicationStatusUpdatesBox.put(id, payload);
  }

  String? readPendingApplicationStatusUpdate(String id) =>
      _pendingApplicationStatusUpdatesBox.get(id);

  Future<void> deletePendingApplicationStatusUpdate(String id) async {
    await _ensureInitialized();
    await _pendingApplicationStatusUpdatesBox.delete(id);
  }

  Future<List<String>> getPendingApplicationStatusUpdateIds() async {
    await _ensureInitialized();
    return _pendingApplicationStatusUpdatesBox.keys.cast<String>().toList();
  }

  // ── Profile photo upload queue ────────────────────────────────────────────────
  // Key: "<userId>:<bucket>" e.g. "abc123:avatars"
  // Value: JSON with localPath, bucket, remotePath

  Future<void> savePendingPhotoUpload(String key, String payload) async {
    await _ensureInitialized();
    await _pendingPhotoUploadsBox.put(key, payload);
  }

  String? readPendingPhotoUpload(String key) =>
      _pendingPhotoUploadsBox.get(key);

  Future<void> deletePendingPhotoUpload(String key) async {
    await _ensureInitialized();
    await _pendingPhotoUploadsBox.delete(key);
  }

  Future<List<String>> getPendingPhotoUploadKeys() async {
    await _ensureInitialized();
    return _pendingPhotoUploadsBox.keys.cast<String>().toList();
  }

  Future<void> cacheImage(String key, String value) async {
    await _ensureInitialized();
    await _imageCacheBox.put(key, value);
    await _enforceImageCacheLimit();
  }

  String? readImageCache(String key) => _imageCacheBox.get(key);

  Future<void> setOnboardingComplete(bool value) async {
    await _ensureInitialized();
    await _metaBox.put('onboarding_complete', value.toString());
  }

  bool getOnboardingComplete() => _metaBox.get('onboarding_complete') == 'true';

  Future<void> setLocationPermissionGranted(bool granted) async {
    await _ensureInitialized();
    await _metaBox.put('location_permission_granted', granted.toString());
  }

  bool getLocationPermissionGranted() =>
      _metaBox.get('location_permission_granted') == 'true';

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _enforceImageCacheLimit() async {
    const maxBytes = 200 * 1024 * 1024;
    final entries = _imageCacheBox.toMap();
    if (entries.isEmpty) return;

    final accessTimes = <String, int>{};
    for (final key in entries.keys) {
      final metaKey = ' meta_$key';
      final lastAccess = int.tryParse(_imageCacheBox.get(metaKey) ?? '') ?? 0;
      accessTimes[key as String] = lastAccess;
    }

    int totalBytes = 0;
    for (final value in entries.values) {
      totalBytes += value.length;
    }

    if (totalBytes <= maxBytes) return;

    final orderedKeys = accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in orderedKeys) {
      if (totalBytes <= maxBytes) break;
      final key = entry.key;
      final value = _imageCacheBox.get(key);
      if (value == null) continue;
      totalBytes -= value.length;
      await _imageCacheBox.delete(key);
      await _imageCacheBox.delete(' meta_$key');
    }
  }
}
