import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/hiring_post.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
part 'widgets/hiring_management_widgets.dart';

/// Management screen for the current user's hiring posts.
/// Accessible from Profile when the user has posted (or is posting) jobs.
/// Shows all their posts regardless of open/closed status.
class HiringManagementScreen extends StatelessWidget {
  const HiringManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final posts = state.getMyHiringPosts();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.hiringTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(s.hiringAddNew),
              onPressed: () =>
                  state.pushScreen(HiringEditScreenRoute(null)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 16),
            if (posts.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 56,
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.hiringNoPostsYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.hiringNoPostsSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (context2, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _HiringPostCard(post: posts[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Hiring post card ──────────────────────────────────────────────────────────
