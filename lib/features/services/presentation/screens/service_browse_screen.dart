import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
part 'widgets/service_browse_widgets.dart';

/// Browse screen — shows all services where [availability == true].
/// Searchable by title/category, filterable by category and location.
///
/// This screen is the Part 1 entry point for "Apply to" flow.
/// The full apply/hiring linkage is Phase C Part 2.
class ServiceBrowseScreen extends StatefulWidget {
  const ServiceBrowseScreen({super.key});

  @override
  State<ServiceBrowseScreen> createState() => _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends State<ServiceBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _categoryFilter = '';   // '' = All
  String _locationFilter = '';  // '' = All

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
      KoolanAppStateScope.of(context).loadMoreServices();
    }
  }

  Future<void> _onRefresh() => KoolanAppStateScope.of(context).loadAllData();

  List<Service> _filter(List<Service> all) {
    return all.where((s) {
      // Only available services shown to browsers.
      if (!s.availability) return false;

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.coverDescription.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q);

      final matchesCategory = _categoryFilter.isEmpty ||
          s.category.toLowerCase() ==
              _categoryFilter.toLowerCase();

      final matchesLocation = _locationFilter.isEmpty ||
          s.location.toLowerCase().contains(
                _locationFilter.toLowerCase(),
              );

      return matchesQuery && matchesCategory && matchesLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final results = _filter(state.allServices);

    // Unique categories and locations for filter chips.
    final categories = state.allServices
        .where((svc) => svc.availability)
        .map((svc) => svc.category)
        .toSet()
        .toList()
      ..sort();
    final locations = state.allServices
        .where((svc) => svc.availability)
        .map((svc) => svc.location)
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
          // ── Header + search bar ───────────────────────────────────────────
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
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: s.servicesBrowseSearchHint,
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: cs.onSurfaceVariant),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              s.servicesBrowseTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: cs.onSurface,
              ),
            ),
          ),
          // ── Category filter chips ─────────────────────────────────────────
          if (categories.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // "All" chip
                  _FilterChip(
                    label: s.servicesBrowseFilterAll,
                    selected: _categoryFilter.isEmpty,
                    onTap: () => setState(() => _categoryFilter = ''),
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
          // ── Location filter chips ─────────────────────────────────────────
          if (locations.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: s.servicesBrowseFilterAll,
                    selected: _locationFilter.isEmpty,
                    onTap: () => setState(() => _locationFilter = ''),
                    small: true,
                  ),
                  const SizedBox(width: 8),
                  ...locations.map(
                    (loc) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: loc,
                        selected: _locationFilter == loc,
                        onTap: () => setState(
                          () => _locationFilter =
                              _locationFilter == loc ? '' : loc,
                        ),
                        small: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          // ── Results ───────────────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? _EmptyBrowse(message: s.servicesBrowseNoResults)
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = results[index];
                      return _ServiceBrowseCard(service: service);
                    },
                  ),
          ),
          // ── Load-more indicator ────────────────────────────────────────────
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
