part of '../hiring_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widgets for HiringManagementScreen
// ─────────────────────────────────────────────────────────────────────────────

// ── Hiring post card ──────────────────────────────────────────────────────────

class _HiringPostCard extends StatelessWidget {
  final HiringPost post;
  const _HiringPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s  = state.s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.pushScreen(HiringEditScreenRoute(post.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title + sync badge ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface),
                    ),
                  ),
                  SyncStatusBadge(status: post.syncStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text(post.category,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(post.description,
                  style: TextStyle(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              // ── Status toggle ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: post.isOpen
                                ? cs.primary
                                : cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('${s.hiringStatusLabel}: ',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        Text(
                          post.isOpen
                              ? s.hiringStatusOpen
                              : s.hiringStatusClosed,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: post.isOpen ? cs.primary : cs.error),
                        ),
                      ],
                    ),
                  ),
                  Text(s.hiringToggleStatus,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  Switch.adaptive(
                    value: post.isOpen,
                    onChanged: (value) => state.toggleHiringPostStatus(
                        post.id, value ? 'open' : 'closed'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Applicant count ───────────────────────────────────────────
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    state.pushScreen(HiringApplicantListScreenRoute(post.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(s.hiringApplicantsBadge(post.applicantCount),
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: cs.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Edit + Delete ─────────────────────────────────────────────
              Row(
                children: [
                  _HiringCardAction(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    iconColor: cs.secondary,
                    onTap: () =>
                        state.pushScreen(HiringEditScreenRoute(post.id)),
                  ),
                  const SizedBox(width: 8),
                  _HiringCardAction(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: cs.error.withValues(alpha: 0.1),
                    iconColor: cs.error,
                    onTap: () =>
                        _confirmDeletePost(context, state, s, post.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Delete confirmation helper ────────────────────────────────────────────────

Future<void> _confirmDeletePost(
  BuildContext context,
  KoolanAppState state,
  dynamic s,
  String postId,
) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.hiringDeleteButton),
      content: Text(s.hiringDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.hiringDeleteCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(s.hiringDeleteConfirmButton),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await state.deleteHiringPost(postId);
  }
}

// ── Icon + label pill action button ──────────────────────────────────────────

class _HiringCardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _HiringCardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor)),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _HiringManagementEmpty extends StatelessWidget {
  const _HiringManagementEmpty();

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_outline,
              size: 56, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(s.hiringNoPostsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(s.hiringNoPostsSub,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
