class ChatMessage {
  final String sender;
  final String text;
  final String timestamp;
  final bool isMe;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatSession {
  final String partnerName;
  final String partnerAvatar;
  final String listingTitle;
  final List<ChatMessage> messages;
  final int unreadCount;

  const ChatSession({
    required this.partnerName,
    required this.partnerAvatar,
    required this.listingTitle,
    required this.messages,
    this.unreadCount = 0,
  });

  ChatSession copyWith({
    String? partnerName,
    String? partnerAvatar,
    String? listingTitle,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    return ChatSession(
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      listingTitle: listingTitle ?? this.listingTitle,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
