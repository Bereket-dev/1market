import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/hiring_post.dart';
import '../../../../shared/services/app_state.dart';
part 'widgets/hiring_browse_widgets.dart';

/// Browseable list of open hiring posts for users who want to apply.
/// Searchable by title/category/location.
/// Tapping a card shows [HiringDetailScreen] before allowing apply.
class HiringBrowseScreen extends StatefulWidget {
  const HiringBrowseScreen({super.key});

  @override
  State<HiringBrowseScreen> createState() => _HiringBrowseScreenState();
}

class _HiringBrowseScreenState extends State<HiringBrowseScreen> {
  final TextEditingController _searchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll - 300) {
      KoolanAppStateScope.of(context).loadMoreHiringPosts();
    }
  }

  Future<void> _onRefresh() => KoolanAppStateScope.of(context).loadAllData(forceRefresh: true);

  List<HiringPost> _filter(List<HiringPost> all) {
    return all.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
      final matchesCategory = _categoryFilter.isEmpty ||
          p.category.toLowerCase() ==
              _categoryFilter.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final results = _filter(state.getBrowsableHiringPosts());

    final categories = state
        .getBrowsableHiringPosts()
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 60,
        strokeWidth: 2.5,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + search ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.primary),
                  tooltip: s.wizardBack,
                  onPressed: () => state.popScreen(),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: s.hiringBrowseSearchHint,
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: cs.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Text(
              s.hiringBrowseTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: cs.onSurface,
              ),
            ),
          ),
          // ── Category filters ──────────────────────────────────────────
          if (categories.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: s.hiringBrowseFilterAll,
                    selected: _categoryFilter.isEmpty,
                    onTap: () =>
                        setState(() => _categoryFilter = ''),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat,
                        selected: _categoryFilter == cat,
                        onTap: () => setState(
                          () => _categoryFilter =
                              _categoryFilter == cat ? '' : cat,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          // ── Results ───────────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      s.hiringBrowseNoResults,
                      style:
                          TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (context2, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context2, index) =>
                        _HiringBrowseCard(post: results[index]),
                  ),
          ),
          // ── Load-more indicator ────────────────────────────────────────
          if (state.isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      ), // RefreshIndicator
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
