import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _languageKey = 'koolan_language';
  static const _sessionRestoredKey = 'koolan_session_restored';
  static const _onboardingPhaseKey = 'koolan_onboarding_phase';
  static const _onboardingCompleteKey = 'koolan_onboarding_complete';
  static const _profileCacheKey = 'koolan_profile_cache';
  static const _listingsCacheKey = 'koolan_listings_cache';
  static const _servicesCacheKey = 'koolan_services_cache';
  // Device-level prefs — persisted across logout, never cleared on sign-out.
  static const _darkModeKey = 'koolan_dark_mode';
  static const _preferredCategoryKey = 'koolan_preferred_category';

  // Notification preferences — device-level, persisted across logout.
  static const _notifPushEnabledKey    = 'koolan_notif_push_enabled';
  static const _notifMessagesEnabledKey = 'koolan_notif_messages_enabled';
  static const _notifPriceAlertsKey    = 'koolan_notif_price_alerts';

  // Location CTA — stores the Unix-ms timestamp until which the CTA is snoozed.
  static const _locationCtaSnoozedUntilKey = 'koolan_location_cta_snoozed_until';

  static final Map<String, Object?> _memoryStore = {};

  static Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException catch (_) {
      return null;
    } on PlatformException catch (_) {
      return null;
    }
  }

  static Future<String?> getLanguage() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getString(_languageKey);
    }
    return _memoryStore[_languageKey] as String?;
  }

  static Future<void> saveLanguage(String language) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setString(_languageKey, language);
    } else {
      _memoryStore[_languageKey] = language;
    }
  }

  static Future<void> clearLanguage() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.remove(_languageKey);
    } else {
      _memoryStore.remove(_languageKey);
    }
  }

  /// True when the user authenticated in a previous session (skip language gate).
  static Future<bool> wasSessionRestored() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getBool(_sessionRestoredKey) ?? false;
    }
    return _memoryStore[_sessionRestoredKey] as bool? ?? false;
  }

  static Future<void> markSessionRestored() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_sessionRestoredKey, true);
    } else {
      _memoryStore[_sessionRestoredKey] = true;
    }
  }

  static Future<void> saveOnboardingPhase(String phase) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setString(_onboardingPhaseKey, phase);
    } else {
      _memoryStore[_onboardingPhaseKey] = phase;
    }
  }

  static Future<String?> getOnboardingPhase() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getString(_onboardingPhaseKey);
    }
    return _memoryStore[_onboardingPhaseKey] as String?;
  }

  static Future<void> clearOnboardingPhase() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.remove(_onboardingPhaseKey);
    } else {
      _memoryStore.remove(_onboardingPhaseKey);
    }
  }

  static Future<void> clearSessionRestored() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.remove(_sessionRestoredKey);
    } else {
      _memoryStore.remove(_sessionRestoredKey);
    }
  }

  // ── Onboarding complete ──────────────────────────────────────────────────────

  static Future<void> markOnboardingComplete() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_onboardingCompleteKey, true);
    } else {
      _memoryStore[_onboardingCompleteKey] = true;
    }
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    }
    return _memoryStore[_onboardingCompleteKey] as bool? ?? false;
  }

  static Future<void> clearOnboardingComplete() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.remove(_onboardingCompleteKey);
    } else {
      _memoryStore.remove(_onboardingCompleteKey);
    }
  }

  // ── Profile cache ─────────────────────────────────────────────────────────────

  static Future<void> saveProfileCache(Map<String, dynamic> profileJson) async {
    final prefs = await _prefsOrNull();
    final encoded = jsonEncode(profileJson);
    if (prefs != null) {
      await prefs.setString(_profileCacheKey, encoded);
    } else {
      _memoryStore[_profileCacheKey] = encoded;
    }
  }

  static Future<Map<String, dynamic>?> getProfileCache() async {
    final prefs = await _prefsOrNull();
    final raw = prefs != null
        ? prefs.getString(_profileCacheKey)
        : _memoryStore[_profileCacheKey] as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearProfileCache() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.remove(_profileCacheKey);
    } else {
      _memoryStore.remove(_profileCacheKey);
    }
  }

  // ── Listings cache ────────────────────────────────────────────────────────────

  static Future<void> saveListingsCache(
    List<Map<String, dynamic>> listings,
  ) async {
    final prefs = await _prefsOrNull();
    final encoded = jsonEncode(listings);
    if (prefs != null) {
      await prefs.setString(_listingsCacheKey, encoded);
    } else {
      _memoryStore[_listingsCacheKey] = encoded;
    }
  }

  static Future<List<Map<String, dynamic>>?> getListingsCache() async {
    final prefs = await _prefsOrNull();
    final raw = prefs != null
        ? prefs.getString(_listingsCacheKey)
        : _memoryStore[_listingsCacheKey] as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveServicesCache(
    List<Map<String, dynamic>> services,
  ) async {
    final prefs = await _prefsOrNull();
    final encoded = jsonEncode(services);
    if (prefs != null) {
      await prefs.setString(_servicesCacheKey, encoded);
    } else {
      _memoryStore[_servicesCacheKey] = encoded;
    }
  }

  static Future<List<Map<String, dynamic>>?> getServicesCache() async {
    final prefs = await _prefsOrNull();
    final raw = prefs != null
        ? prefs.getString(_servicesCacheKey)
        : _memoryStore[_servicesCacheKey] as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Dark mode (device preference — never cleared on logout) ──────────────────

  static Future<void> saveDarkMode(bool value) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_darkModeKey, value);
    } else {
      _memoryStore[_darkModeKey] = value;
    }
  }

  static Future<bool?> getDarkMode() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.containsKey(_darkModeKey)
          ? prefs.getBool(_darkModeKey)
          : null;
    }
    return _memoryStore.containsKey(_darkModeKey)
        ? _memoryStore[_darkModeKey] as bool?
        : null;
  }

  // ── Preferred category (device preference — never cleared on logout) ──────────

  static Future<void> savePreferredCategory(String category) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setString(_preferredCategoryKey, category);
    } else {
      _memoryStore[_preferredCategoryKey] = category;
    }
  }

  static Future<String?> getPreferredCategory() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getString(_preferredCategoryKey);
    }
    return _memoryStore[_preferredCategoryKey] as String?;
  }

  // ── Notification preferences (device-level, never cleared on logout) ─────────

  static Future<void> saveNotifPushEnabled(bool value) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_notifPushEnabledKey, value);
    } else {
      _memoryStore[_notifPushEnabledKey] = value;
    }
  }

  static Future<bool> getNotifPushEnabled() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getBool(_notifPushEnabledKey) ?? true;
    }
    return _memoryStore[_notifPushEnabledKey] as bool? ?? true;
  }

  static Future<void> saveNotifMessagesEnabled(bool value) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_notifMessagesEnabledKey, value);
    } else {
      _memoryStore[_notifMessagesEnabledKey] = value;
    }
  }

  static Future<bool> getNotifMessagesEnabled() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getBool(_notifMessagesEnabledKey) ?? true;
    }
    return _memoryStore[_notifMessagesEnabledKey] as bool? ?? true;
  }

  static Future<void> saveNotifPriceAlerts(bool value) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setBool(_notifPriceAlertsKey, value);
    } else {
      _memoryStore[_notifPriceAlertsKey] = value;
    }
  }

  static Future<bool> getNotifPriceAlerts() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getBool(_notifPriceAlertsKey) ?? false;
    }
    return _memoryStore[_notifPriceAlertsKey] as bool? ?? false;
  }

  // ── Location CTA snooze ──────────────────────────────────────────────────────
  // Stores the UTC Unix-ms timestamp until which the location CTA is snoozed.
  // 0 (or absent) means "show immediately".

  /// Saves the UTC timestamp (ms since epoch) until which the CTA is hidden.
  static Future<void> saveLocationCtaSnoozedUntil(int timestampMs) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setInt(_locationCtaSnoozedUntilKey, timestampMs);
    } else {
      _memoryStore[_locationCtaSnoozedUntilKey] = timestampMs;
    }
  }

  /// Returns the UTC timestamp (ms since epoch) until which the CTA is snoozed,
  /// or 0 if never snoozed.
  static Future<int> getLocationCtaSnoozedUntil() async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      return prefs.getInt(_locationCtaSnoozedUntilKey) ?? 0;
    }
    return _memoryStore[_locationCtaSnoozedUntilKey] as int? ?? 0;
  }

  // ── Chat local state (per-device read + archive) ─────────────────────────────

  static const _chatLastReadKey = 'koolan_chat_last_read';
  static const _chatArchivedKey = 'koolan_chat_archived';

  /// Map of threadId → last-read UTC ms.
  static Future<Map<String, int>> getChatLastReadMap() async {
    final raw = await _getString(_chatLastReadKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> setChatLastRead(String threadId, int timestampMs) async {
    final map = await getChatLastReadMap();
    map[threadId] = timestampMs;
    await _setString(_chatLastReadKey, jsonEncode(map));
  }

  /// Set of archived thread IDs.
  static Future<Set<String>> getArchivedChatIds() async {
    final raw = await _getString(_chatArchivedKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return {};
    }
  }

  static Future<void> setChatArchived(String threadId, bool archived) async {
    final ids = await getArchivedChatIds();
    if (archived) {
      ids.add(threadId);
    } else {
      ids.remove(threadId);
    }
    await _setString(_chatArchivedKey, jsonEncode(ids.toList()));
  }

  static Future<String?> _getString(String key) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) return prefs.getString(key);
    return _memoryStore[key] as String?;
  }

  static Future<void> _setString(String key, String value) async {
    final prefs = await _prefsOrNull();
    if (prefs != null) {
      await prefs.setString(key, value);
    } else {
      _memoryStore[key] = value;
    }
  }
}
