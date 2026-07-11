import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/services/app_state.dart';

class ActiveChatScreen extends StatefulWidget {
  final int sessionIndex;
  const ActiveChatScreen({super.key, required this.sessionIndex});

  @override
  State<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final session = state.chatSessions[widget.sessionIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => state.popScreen(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(session.partnerAvatar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.partnerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    session.listingTitle,
                    style: const TextStyle(fontSize: 10, color: kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: kSurfaceContainerLowest,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ── Message stream ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: session.messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ChatBubble(msg: session.messages[index]);
              },
            ),
          ),

          // ── Input panel ───────────────────────────────────────────────────
          Container(
            color: kSurfaceContainerLowest,
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: state.s.chatInputHint,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: kPrimary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          state.sendChatMessage(
                            widget.sessionIndex,
                            _messageController.text,
                          );
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = msg.isMe ? kPrimaryContainer : kSurfaceContainerHigh;
    final textColor = msg.isMe ? Colors.white : kOnSurface;
    final alignment =
        msg.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textAlignment =
        msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: textAlignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 16),
              ),
            ),
            child:
                Text(msg.text, style: TextStyle(color: textColor, fontSize: 14)),
          ),
          const SizedBox(height: 2),
          Text(
            msg.timestamp,
            style: TextStyle(
                fontSize: 10, color: kOnSurfaceVariant.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
