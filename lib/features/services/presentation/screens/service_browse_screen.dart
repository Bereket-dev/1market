import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';

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
  String _searchQuery = '';
  String _categoryFilter = '';   // '' = All
  String _locationFilter = '';  // '' = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      body: Column(
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
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 14,
          vertical: small ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
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
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Browse card ───────────────────────────────────────────────────────────────

class _ServiceBrowseCard extends StatelessWidget {
  final Service service;
  const _ServiceBrowseCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.pushScreen(ServiceDetailScreenRoute(service.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + availability dot (only available shown, but keep it visible)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // Availability label — visible text, not icon-only
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.servicesAvailable,
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
              // Category
              Text(
                service.category,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Cover description
              Text(
                service.coverDescription,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Location + price row
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.location,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    service.priceRange,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // "View full profile" — labelled action, not bare icon
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.servicesBrowseApplyAction,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBrowse extends StatelessWidget {
  final String message;
  const _EmptyBrowse({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
