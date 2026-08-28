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
  void initState() {
    super.initState();
    // Ensure unread/archived flags are applied after hot reload / cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = OnemarketAppStateScope.of(context);
      state.refreshChatSessions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatSession> _filtered(List<ChatSession> sessions) {
    var result = sessions;

    switch (_activeFilter) {
      case _Filter.unread:
        result = result
            .where((s) => !s.isArchived && s.unreadCount > 0)
            .toList();
      case _Filter.archived:
        result = result.where((s) => s.isArchived).toList();
      case _Filter.all:
        result = result.where((s) => !s.isArchived).toList();
    }

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

  Future<void> _refresh(OnemarketAppState state) async {
    await state.refreshChatSessions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.s.messagesRefreshed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered(state.chatSessions);
    final unreadTotal = state.totalUnreadChatCount;

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
                  onPressed: () => _refresh(state),
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
                  label: unreadTotal > 0
                      ? '${state.s.messagesFilterUnread} ($unreadTotal)'
                      : state.s.messagesFilterUnread,
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
          if (_activeFilter == _Filter.archived) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.s.messagesArchiveHint,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Chat list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _activeFilter == _Filter.archived
                              ? Icons.archive_outlined
                              : Icons.chat_bubble_outline,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeFilter == _Filter.archived &&
                                  _searchQuery.isEmpty
                              ? state.s.messagesArchivedEmpty
                              : _searchQuery.isNotEmpty ||
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (context2, idx) => Divider(
                      height: 1,
                      indent: 72,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      final session = filtered[index];
                      final realIndex = state.chatSessions
                          .indexWhere((s) => s.id == session.id);
                      return _SessionCard(
                        session: session,
                        onTap: () {
                          state.markChatThreadRead(session.id);
                          state.pushScreen(
                            ActiveChatScreenRoute(
                              realIndex != -1 ? realIndex : index,
                            ),
                          );
                        },
                        onArchiveToggle: () {
                          final archived = session.isArchived;
                          final future = archived
                              ? state.unarchiveChatThread(session.id)
                              : state.archiveChatThread(session.id);
                          future.then((_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  archived
                                      ? state.s.messagesUnarchivedSnack
                                      : state.s.messagesArchivedSnack,
                                ),
                                action: archived
                                    ? null
                                    : SnackBarAction(
                                        label: state.s.messagesUnarchive,
                                        onPressed: () => state
                                            .unarchiveChatThread(session.id),
                                      ),
                              ),
                            );
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
