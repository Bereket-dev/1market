import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _languageKey = 'koolan_language';
  static const _sessionRestoredKey = 'koolan_session_restored';
  static const _onboardingPhaseKey = 'koolan_onboarding_phase';
  static const _onboardingCompleteKey = 'koolan_onboarding_complete';
  static const _profileCacheKey = 'koolan_profile_cache';
  static const _listingsCacheKey = 'koolan_listings_cache';

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<void> clearLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }

  /// True when the user authenticated in a previous session (skip language gate).
  static Future<bool> wasSessionRestored() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionRestoredKey) ?? false;
  }

  static Future<void> markSessionRestored() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionRestoredKey, true);
  }

  static Future<void> saveOnboardingPhase(String phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingPhaseKey, phase);
  }

  static Future<String?> getOnboardingPhase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_onboardingPhaseKey);
  }

  static Future<void> clearOnboardingPhase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingPhaseKey);
  }

  static Future<void> clearSessionRestored() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionRestoredKey);
  }

  // ── Onboarding complete ──────────────────────────────────────────────────────

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> clearOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
  }

  // ── Profile cache ─────────────────────────────────────────────────────────────

  static Future<void> saveProfileCache(Map<String, dynamic> profileJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonEncode(profileJson));
  }

  static Future<Map<String, dynamic>?> getProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileCacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
  }

  // ── Listings cache ────────────────────────────────────────────────────────────

  static Future<void> saveListingsCache(List<Map<String, dynamic>> listings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listingsCacheKey, jsonEncode(listings));
  }

  static Future<List<Map<String, dynamic>>?> getListingsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listingsCacheKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}
