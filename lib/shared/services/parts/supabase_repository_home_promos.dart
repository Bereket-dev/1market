part of '../supabase_repository.dart';

// ── Home Promos ───────────────────────────────────────────────────────────────

extension SupabaseRepositoryHomePromos on SupabaseRepository {
  /// Fetches active promo slots ordered by slot number.
  /// Returns an empty list on any error so the carousel can use its fallback.
  Future<List<HomePromo>> fetchHomePromos() async {
    final rows = await _client
        .from('home_promos')
        .select('slot, headline, subtitle, image_url, theme')
        .order('slot', ascending: true);

    return (rows as List)
        .map((row) => HomePromo.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
