part of '../supabase_repository.dart';

// ── Profile ──────────────────────────────────────────────────────────

extension SupabaseRepositoryProfile on SupabaseRepository {
  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return SafeParse.tryMap(data, UserProfile.fromJson, context: 'profile');
  }

  Future<UserProfile> ensureProfile() async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    var profile = await fetchProfile(userId);
    if (profile != null) return profile;

    final user = _client.auth.currentUser!;
    final meta = user.userMetadata ?? {};
    final displayName = meta['full_name'] as String? ??
        meta['name'] as String? ??
        user.email?.split('@').first ??
        'User';
    // Seed phone from Supabase auth (populated when user signs up with
    // email+phone or phone OTP). Google Sign-In does not provide a phone.
    final phone = user.phone?.isNotEmpty == true
        ? user.phone
        : (meta['phone'] as String?)?.isNotEmpty == true
            ? meta['phone'] as String?
            : null;

    await _client.from('profiles').insert({
      'id': userId,
      'display_name': displayName,
      'avatar_url': meta['avatar_url'],
      'phone': phone,
    });

    profile = await fetchProfile(userId);
    return profile!;
  }

  Future<void> updateLanguage(String language) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('profiles').update({
      'language': language,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('profiles').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Clears a stale FCM token (e.g. after the user reinstalls the app).
  Future<void> clearFcmToken() async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client
        .from('profiles')
        .update({'fcm_token': null})
        .eq('id', userId);
  }

}
