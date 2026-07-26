part of '../messages_screen.dart';

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = KoolanAppStateScope.of(context);
    final lastMsg = session.messages.lastOrNull;
    final hasUnread = session.unreadCount > 0;

    return Card(
      elevation: 0,
      color: hasUnread
          ? cs.primaryContainer.withValues(alpha: 0.15)
          : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: hasUnread
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                child: CachedNetworkImage(
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
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Partner name — tappable to public profile
                        GestureDetector(
                          onTap: session.partnerUserId != null
                              ? () => state.pushScreen(
                                    PublicProfileScreenRoute(
                                        session.partnerUserId!),
                                  )
                              : null,
                          child: Text(
                            session.partnerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          lastMsg?.timestamp ?? state.s.messagesJustNow,
                          style: TextStyle(
                            fontSize: 11,
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
                        color: hasUnread
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread badge
              if (hasUnread) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: cs.primary,
                  child: Text(
                    session.unreadCount.toString(),
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
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
            color: isSelected
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
