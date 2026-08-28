import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/profile.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/public_profile_tabs.dart';
part 'widgets/public_profile_header.dart';

/// Read-only public profile view for any user identified by [userId].
///
/// Shows avatar, name, bio, rating, services and reviews received.
class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = OnemarketAppStateScope.of(context);
    // If already cached, show instantly with no spinner.
    if (state.getCachedPublicProfile(widget.userId) != null) {
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = OnemarketAppStateScope.of(context);
    try {
      // Run both fetches in parallel — single await for both.
      await Future.wait([
        state.loadPublicProfile(widget.userId),
        state.loadReviewsForUser(widget.userId),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    final profile = state.getCachedPublicProfile(widget.userId);
    final reviews = state.getReviewsForUser(widget.userId);
    // Only services this user has marked as publicly available
    final services = state.allServices
        .where((sv) => sv.ownerId == widget.userId && sv.availability)
        .toList();

    if (_loading && profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(s.publicProfileTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(s.publicProfileLoading,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    if (_error != null && profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(s.publicProfileTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: cs.outline),
                const SizedBox(height: 16),
                Text(s.publicProfileNotFound,
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _load,
                  child: Text(s.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ProfileSliverHeader(
            state: state,
            profile: profile,
            reviews: reviews,
            onBack: () => state.popScreen(),
          ),
        ],
        body: Column(
          children: [
            // Tab bar
            Material(
              color: cs.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: cs.primary,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                tabs: [
                  Tab(text: s.publicProfileServices),
                  Tab(
                    text: s.publicProfileReviews +
                        (reviews.isNotEmpty ? ' (${reviews.length})' : ''),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Services tab ────────────────────────────────────────────
                  _ServicesTab(
                    services: services,
                    state: state,
                  ),
                  // ── Reviews tab ─────────────────────────────────────────────
                  _ReviewsTab(reviews: reviews, state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver header: banner, avatar, name, bio, stats
// ─────────────────────────────────────────────────────────────────────────────
