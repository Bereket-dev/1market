part of '../supabase_repository.dart';

// ── Services ──────────────────────────────────────────────────────────

extension SupabaseRepositoryServices on SupabaseRepository {
  // ── Services ─────────────────────────────────────────────────────────────────

  /// Inserts a new service row and returns the Supabase-assigned id.
  Future<String> insertService(Map<String, dynamic> fields) async {
    final row = await _client
        .from('services')
        .insert(fields)
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Updates an existing service row by id.
  Future<void> updateService(String serviceId, Map<String, dynamic> fields) async {
    await _client.from('services').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', serviceId);
  }

  /// Hard-deletes a service row. No-op if the row no longer exists.
  Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }

  // ── Hiring posts ──────────────────────────────────────────────────────────────

  /// Inserts a new hiring post and returns the Supabase-assigned id.
  Future<String> insertHiringPost(Map<String, dynamic> fields) async {
    final row = await _client
        .from('hiring_posts')
        .insert(fields)
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Updates an existing hiring post row by id.
  Future<void> updateHiringPost(String postId, Map<String, dynamic> fields) async {
    await _client.from('hiring_posts').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }

  /// Hard-deletes a hiring post row.
  Future<void> deleteHiringPost(String postId) async {
    await _client.from('hiring_posts').delete().eq('id', postId);
  }
}
