import '../models/syncable_entity.dart';

class ChatMessage with SyncableEntity {
  @override
  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final bool isMe;
  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  // Not const: the initializer list uses DateTime.now(), which is a runtime
  // call and can never be a compile-time constant.
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
  }) : localUpdatedAt = localUpdatedAt ?? DateTime.now();

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
      localUpdatedAt: createdAt ?? DateTime.now(),
      remoteUpdatedAt: createdAt,
      syncStatus: SyncStatus.synced,
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

  /// The listing this thread is about. Used to look up thread state from the
  /// listing detail screen.
  final String? listingId;

  final List<ChatMessage> messages;
  final int unreadCount;

  /// True once contact details have been revealed for this thread — either
  /// by an explicit "Share phone number" tap or by the 3-message auto-reveal.
  /// Stays true once set; never resets for this thread.
  final bool contactRevealed;

  /// Count of real (sent) messages in this thread. Used to auto-reveal at 3.
  final int totalMessages;

  /// The partner's phone number, populated once contact has been revealed.
  final String? partnerPhone;

  /// The partner's user ID, used for navigating to their public profile.
  final String? partnerUserId;

  const ChatSession({
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.listingTitle,
    this.listingId,
    required this.messages,
    this.unreadCount = 0,
    this.contactRevealed = false,
    this.totalMessages = 0,
    this.partnerPhone,
    this.partnerUserId,
  });

  ChatSession copyWith({
    String? id,
    String? partnerName,
    String? partnerAvatar,
    String? listingTitle,
    String? listingId,
    List<ChatMessage>? messages,
    int? unreadCount,
    bool? contactRevealed,
    int? totalMessages,
    String? partnerPhone,
    String? partnerUserId,
  }) {
    return ChatSession(
      id: id ?? this.id,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      listingTitle: listingTitle ?? this.listingTitle,
      listingId: listingId ?? this.listingId,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      contactRevealed: contactRevealed ?? this.contactRevealed,
      totalMessages: totalMessages ?? this.totalMessages,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      partnerUserId: partnerUserId ?? this.partnerUserId,
    );
  }
}
