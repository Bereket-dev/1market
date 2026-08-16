import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

class ActiveChatScreen extends StatefulWidget {
  final int sessionIndex;
  const ActiveChatScreen({super.key, required this.sessionIndex});

  @override
  State<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _markedRead = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_markedRead) return;
    _markedRead = true;
    final state = KoolanAppStateScope.of(context);
    if (widget.sessionIndex >= 0 &&
        widget.sessionIndex < state.chatSessions.length) {
      final id = state.chatSessions[widget.sessionIndex].id;
      // Defer so we don't notifyListeners during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.markChatThreadRead(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    if (widget.sessionIndex < 0 ||
        widget.sessionIndex >= state.chatSessions.length) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
        ),
        body: Center(child: Text(state.s.messagesNoMessages)),
      );
    }
    final session = state.chatSessions[widget.sessionIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
        ),
        title: GestureDetector(
          onTap: session.partnerUserId != null
              ? () => state.pushScreen(
                    PublicProfileScreenRoute(session.partnerUserId!),
                  )
              : null,
          child: Row(children: [
            session.partnerAvatar.isEmpty
                ? const CircleAvatar(radius: 18, child: Icon(Icons.person))
                : CachedNetworkImage(
                    imageUrl: session.partnerAvatar,
                    cacheManager: KoolanImageCacheManager.instance,
                    imageBuilder: (_, provider) => CircleAvatar(
                      radius: 18,
                      backgroundImage: provider,
                    ),
                    placeholder: (_, __) =>
                        const CircleAvatar(radius: 18, backgroundColor: Colors.grey),
                    errorWidget: (_, __, ___) =>
                        const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.partnerName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface)),
                Text(session.listingTitle,
                    style: TextStyle(fontSize: 10, color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
        // ── Call partner directly when their phone is on file ─────────────────
        actions: [
          if (session.partnerPhone != null &&
              session.partnerPhone!.trim().isNotEmpty)
            Tooltip(
              message: state.s.chatCall,
              child: IconButton(
                icon: Icon(Icons.call, color: cs.primary),
                onPressed: () {
                  launchUrl(Uri.parse('tel:${session.partnerPhone}'));
                },
              ),
            ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      body: Column(children: [
        // ── Message stream ──────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: session.messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ChatBubble(msg: session.messages[i]),
          ),
        ),

        // ── Input bar ───────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35))),
          ),
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: state.s.chatInputHint,
                      hintStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: cs.primary,
                radius: 24,
                child: IconButton(
                  icon: Icon(Icons.send, color: cs.onPrimary),
                  onPressed: () {
                    if (_ctrl.text.trim().isNotEmpty) {
                      state.sendChatMessage(session.id, _ctrl.text);
                      _ctrl.clear();
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    // My bubbles: primaryContainer bg, onPrimaryContainer text — guaranteed contrast.
    // Incoming: surfaceContainerHighest bg, onSurface text.
    final bg = msg.isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = msg.isMe ? cs.onPrimaryContainer : cs.onSurface;

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 16),
              ),
            ),
            child: Text(msg.text, style: TextStyle(color: fg, fontSize: 14)),
          ),
          const SizedBox(height: 2),
          Text(s.formatChatTimestamp(msg.displayTime),
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
