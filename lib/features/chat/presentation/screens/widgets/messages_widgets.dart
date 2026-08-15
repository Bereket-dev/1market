part of '../messages_screen.dart';

// ── Session card (Telegram-style unread treatment) ───────────────────────────

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
    final unread = archived ? 0 : session.unreadCount;
    final hasUnread = unread > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onArchiveToggle,
        child: Ink(
          color: hasUnread
              ? cs.primaryContainer.withValues(alpha: 0.28)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar — tappable to public profile
                GestureDetector(
                  onTap: session.partnerUserId != null
                      ? () => state.pushScreen(
                            PublicProfileScreenRoute(session.partnerUserId!),
                          )
                      : null,
                  child: session.partnerAvatar.isEmpty
                      ? const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.person),
                        )
                      : CachedNetworkImage(
                          imageUrl: session.partnerAvatar,
                          cacheManager: KoolanImageCacheManager.instance,
                          imageBuilder: (ctx, provider) => CircleAvatar(
                            radius: 28,
                            backgroundImage: provider,
                          ),
                          placeholder: (ctx, url) => const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey,
                          ),
                          errorWidget: (ctx, url, err) => const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.person),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Name + listing + preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.partnerName,
                        style: TextStyle(
                          fontWeight:
                              hasUnread ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 16,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (session.listingTitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          session.listingTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        lastMsg?.text ?? state.s.messagesNoMessages,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          color: hasUnread
                              ? cs.onSurface
                              : cs.onSurfaceVariant.withValues(alpha: 0.85),
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Telegram-style trailing: time on top, unread count below
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastMsg?.timestamp ?? state.s.messagesJustNow,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w400,
                        color: hasUnread
                            ? cs.primary
                            : cs.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasUnread)
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: archived
                            ? state.s.messagesUnarchive
                            : state.s.messagesArchive,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          archived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                        onPressed: onArchiveToggle,
                      ),
                  ],
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
