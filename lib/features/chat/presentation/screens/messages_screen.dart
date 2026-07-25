import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/messages_widgets.dart';

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
