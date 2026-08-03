part of '../messages_screen.dart';

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onArchiveToggle;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onArchiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = KoolanAppStateScope.of(context);
    final lastMsg = session.messages.lastOrNull;
    final archived = session.isArchived;
    final hasUnread = session.unreadCount > 0 && !archived;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onArchiveToggle,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: hasUnread
                ? cs.primaryContainer.withValues(alpha: 0.35)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasUnread
                  ? cs.primary.withValues(alpha: 0.7)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: hasUnread ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar — tappable to public profile
                GestureDetector(
                  onTap: session.partnerUserId != null
                      ? () => state.pushScreen(
                            PublicProfileScreenRoute(session.partnerUserId!),
                          )
                      : null,
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: session.partnerAvatar.isEmpty
                            ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80'
                            : session.partnerAvatar,
                        cacheManager: KoolanImageCacheManager.instance,
                        imageBuilder: (ctx, provider) => CircleAvatar(
                          radius: 27,
                          backgroundImage: provider,
                        ),
                        placeholder: (ctx, url) => const CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.grey,
                        ),
                        errorWidget: (ctx, url, err) => const CircleAvatar(
                          radius: 27,
                          child: Icon(Icons.person),
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.partnerName,
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 16,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lastMsg?.timestamp ?? state.s.messagesJustNow,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: hasUnread
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.listingTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsg?.text ?? state.s.messagesNoMessages,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread ? cs.onSurface : cs.onSurfaceVariant,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.unreadCount > 99
                          ? '99+'
                          : session.unreadCount.toString(),
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: archived
                      ? state.s.messagesUnarchive
                      : state.s.messagesArchive,
                  icon: Icon(
                    archived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onArchiveToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
