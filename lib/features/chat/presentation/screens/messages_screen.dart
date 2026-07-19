import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

enum _Filter { all, unread, archived }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _Filter _activeFilter = _Filter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatSession> _filtered(List<ChatSession> sessions) {
    var result = sessions;

    // Apply filter chip
    switch (_activeFilter) {
      case _Filter.unread:
        result = result.where((s) => s.unreadCount > 0).toList();
      case _Filter.archived:
        // No archive flag on ChatSession yet — show empty with a hint.
        result = [];
      case _Filter.all:
        break;
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.partnerName.toLowerCase().contains(q) ||
            s.listingTitle.toLowerCase().contains(q) ||
            (s.messages.lastOrNull?.text.toLowerCase().contains(q) ??
                false);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered(state.chatSessions);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.s.messagesTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: cs.primary),
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(
                          SnackBar(content: Text(state.s.messagesRefreshed))),
                ),
              ],
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────
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
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: state.s.messagesSearchHint,
                  hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                  prefixIcon:
                      Icon(Icons.search, color: cs.onSurfaceVariant),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              Icon(Icons.clear, color: cs.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick filter chips ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _FilterChip(
                  label: state.s.messagesFilterAll,
                  isSelected: _activeFilter == _Filter.all,
                  onTap: () =>
                      setState(() => _activeFilter = _Filter.all),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: state.s.messagesFilterUnread,
                  isSelected: _activeFilter == _Filter.unread,
                  onTap: () =>
                      setState(() => _activeFilter = _Filter.unread),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: state.s.messagesFilterArchived,
                  isSelected: _activeFilter == _Filter.archived,
                  onTap: () =>
                      setState(() => _activeFilter = _Filter.archived),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Chat list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _activeFilter != _Filter.all
                              ? state.s.messagesNoResults
                              : state.s.messagesEmpty,
                          style:
                              TextStyle(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context2, idx) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final session = filtered[index];
                      // Find the real index in the full session list for
                      // navigation (ActiveChatScreen uses an index).
                      final realIndex = state.chatSessions
                          .indexWhere((s) => s.id == session.id);
                      return _SessionCard(
                        session: session,
                        onTap: () => state.pushScreen(
                          ActiveChatScreenRoute(
                            realIndex != -1 ? realIndex : index,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side:
            BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
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
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session.partnerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          lastMsg?.timestamp ?? state.s.messagesJustNow,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
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
                        color: session.unreadCount > 0
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                        fontWeight: session.unreadCount > 0
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
              if (session.unreadCount > 0) ...[
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
