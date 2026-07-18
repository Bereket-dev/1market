import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final session = state.chatSessions[widget.sessionIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
        ),
        title: Row(children: [
          CachedNetworkImage(
            imageUrl: session.partnerAvatar.isEmpty
                ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80'
                : session.partnerAvatar,
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
        // ── Share phone number action ──────────────────────────────────────
        // Visible when contact has not yet been revealed. Tapping it triggers
        // the explicit-reveal path and persists across both parties' views of
        // the thread via revealContactForThread.
        actions: [
          if (!session.contactRevealed)
            Tooltip(
              message: 'Share phone number',
              child: IconButton(
                icon: Icon(Icons.phone_forwarded_outlined, color: cs.primary),
                onPressed: () {
                  state.revealContactForThread(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number shared with this contact.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
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
          Text(msg.timestamp,
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
