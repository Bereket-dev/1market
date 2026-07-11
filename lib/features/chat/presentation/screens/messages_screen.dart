import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/services/app_state.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final sessions = state.chatSessions;

    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(state.s.messagesTitle,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface)),
              IconButton(
                icon: Icon(Icons.refresh, color: cs.primary),
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(
                        const SnackBar(content: Text('Chat list updated'))),
              ),
            ],
          ),
        ),

        // ── Search bar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: TextField(
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                prefixIcon:
                    Icon(Icons.search, color: cs.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Quick filter chips ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: const [
            _FilterChip(label: 'All', isSelected: true),
            SizedBox(width: 10),
            _FilterChip(label: 'Unread', isSelected: false),
            SizedBox(width: 10),
            _FilterChip(label: 'Archived', isSelected: false),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Chat list ────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final lastMsg = session.messages.lastOrNull;
              final isOnline = index % 2 == 0;

              return Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  onTap: () =>
                      state.pushScreen(ActiveChatScreenRoute(index)),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Stack(children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundImage:
                              NetworkImage(session.partnerAvatar),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                // use tertiary (green in dark, verified green in light)
                                color: cs.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.surfaceContainerHighest,
                                    width: 2),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(session.partnerName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: cs.onSurface)),
                                  Text(lastMsg?.timestamp ?? 'Just now',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.6))),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(session.listingTitle,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                lastMsg?.text ?? 'No messages yet',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: session.unreadCount > 0
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontWeight: session.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]),
                      ),
                      if (session.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: cs.primary,
                          child: Text(session.unreadCount.toString(),
                              style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isSelected
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant)),
    );
  }
}
