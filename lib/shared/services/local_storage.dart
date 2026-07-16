import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _languageKey = 'koolan_language';
  static const _sessionRestoredKey = 'koolan_session_restored';

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

  static Future<void> clearSessionRestored() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionRestoredKey);
  }
}
