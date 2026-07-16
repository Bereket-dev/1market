class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final senderId = json['sender_id'] as String;
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    return ChatMessage(
      id: json['id'] as String,
      sender: senderId == currentUserId ? 'Me' : 'Partner',
      text: json['text'] as String,
      timestamp: _formatTimestamp(createdAt),
      isMe: senderId == currentUserId,
    );
  }

  static String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class ChatSession {
  final String id;
  final String partnerName;
  final String partnerAvatar;
  final String listingTitle;
  final List<ChatMessage> messages;
  final int unreadCount;

  const ChatSession({
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.listingTitle,
    required this.messages,
    this.unreadCount = 0,
  });

  ChatSession copyWith({
    String? id,
    String? partnerName,
    String? partnerAvatar,
    String? listingTitle,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      listingTitle: listingTitle ?? this.listingTitle,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
