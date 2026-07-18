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

  static Future<void> saveListingsCache(List<Map<String, dynamic>> listings) async {
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
}
