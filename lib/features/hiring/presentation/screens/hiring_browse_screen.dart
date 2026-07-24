import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/hiring_post.dart';
import '../../../../shared/services/app_state.dart';

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

  Future<void> _onRefresh() => KoolanAppStateScope.of(context).loadAllData();

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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? cs.onPrimary
                : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Browse card ───────────────────────────────────────────────────────────────

class _HiringBrowseCard extends StatelessWidget {
  final HiringPost post;
  const _HiringBrowseCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            state.pushScreen(HiringDetailScreenRoute(post.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + open badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.hiringStatusOpen,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                post.category,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.description,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      post.location,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.priceRange.isNotEmpty)
                    Text(
                      post.priceRange,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Labelled "View details" — never bare icon
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.hiringDetailTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
