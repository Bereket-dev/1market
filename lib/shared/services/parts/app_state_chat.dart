// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Chat & reports ────────────────────────────────────────────────────────────

extension AppStateChat on KoolanAppState {
  /// Total unread messages across non-archived threads (for nav badge / filters).
  int get totalUnreadChatCount => chatSessions
      .where((s) => !s.isArchived)
      .fold<int>(0, (sum, s) => sum + s.unreadCount);

  /// Applies per-device last-read + archived flags to freshly fetched sessions.
  Future<List<ChatSession>> _enrichChatSessions(
    List<ChatSession> sessions,
  ) async {
    final lastRead = await app_local.LocalStorage.getChatLastReadMap();
    final archived = await app_local.LocalStorage.getArchivedChatIds();
    final seeds = <String, int>{};

    final enriched = sessions.map((session) {
      final isArchived = archived.contains(session.id);

      if (!lastRead.containsKey(session.id)) {
        // First time on this device — treat existing history as read so we
        // don't flood the Unread tab. Seed last-read to the newest message.
        final seedMs = session.messages.isEmpty
            ? DateTime.now().millisecondsSinceEpoch
            : session.messages.last.localUpdatedAt.millisecondsSinceEpoch;
        seeds[session.id] = seedMs;
        return session.copyWith(unreadCount: 0, isArchived: isArchived);
      }

      // Compare in epoch-ms so UTC/local DateTime variants stay consistent.
      final readMs = lastRead[session.id]!;
      final unread = session.messages
          .where(
            (m) =>
                !m.isMe &&
                m.localUpdatedAt.millisecondsSinceEpoch > readMs,
          )
          .length;
      return session.copyWith(
        unreadCount: unread,
        isArchived: isArchived,
      );
    }).toList();

    for (final entry in seeds.entries) {
      await app_local.LocalStorage.setChatLastRead(entry.key, entry.value);
    }

    return enriched;
  }

  Future<void> refreshChatSessions() async {
    if (_repo == null) return;
    try {
      final raw = await _repo!.fetchChatSessions();
      chatSessions = await _enrichChatSessions(raw);
      notifyListeners();
    } catch (e) {
      reportDataError(e);
      notifyListeners();
    }
  }

  /// Marks a thread as read up to the latest message (clears unread badge).
  Future<void> markChatThreadRead(String sessionId) async {
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = chatSessions[index];

    final lastMsgMs = session.messages.isEmpty
        ? 0
        : session.messages.last.localUpdatedAt.millisecondsSinceEpoch;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Use the later of "now" and last message so clock skew can't leave a
    // just-opened thread stuck with an unread badge.
    final readMs = nowMs > lastMsgMs ? nowMs : lastMsgMs;
    await app_local.LocalStorage.setChatLastRead(sessionId, readMs);

    if (session.unreadCount == 0) return;
    chatSessions[index] = session.copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// Archives a thread so it leaves All/Unread and appears under Archived.
  Future<void> archiveChatThread(String sessionId) async {
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    await app_local.LocalStorage.setChatArchived(sessionId, true);
    chatSessions[index] = chatSessions[index].copyWith(isArchived: true);
    notifyListeners();
  }

  /// Restores an archived thread back into All/Unread.
  Future<void> unarchiveChatThread(String sessionId) async {
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    await app_local.LocalStorage.setChatArchived(sessionId, false);
    chatSessions[index] = chatSessions[index].copyWith(isArchived: false);
    notifyListeners();
  }

  Future<void> sendChatMessage(String sessionId, String text) async {
    if (text.trim().isEmpty) return;
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    try {
      if (_repo == null) {
        dataError = s.errorSupabaseUnavailable;
        notifyListeners();
        return;
      }
      final msg = await _repo!.sendMessage(threadId: sessionId, text: text);
      final session = chatSessions[index];
      // Own messages don't create unread; bump last-read so the thread stays read.
      await app_local.LocalStorage.setChatLastRead(
        sessionId,
        DateTime.now().millisecondsSinceEpoch,
      );
      chatSessions[index] = session.copyWith(
        messages: [...session.messages, msg],
        unreadCount: 0,
      );
      notifyListeners();
    } catch (e) {
      reportDataError(e);
      notifyListeners();
      rethrow;
    }
  }

  ChatSession? getSessionForListing(String listingId) {
    try {
      return chatSessions.firstWhere((s) => s.listingId == listingId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> startChatForListing(String listingId) async {
    final listing = getListingById(listingId);
    if (listing == null || listing.sellerId == null) return null;
    try {
      if (_repo == null) {
        dataError = s.errorSupabaseUnavailable;
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateThread(
        listingId: listingId,
        sellerId: listing.sellerId!,
      );
      final raw = await _repo!.fetchChatSessions();
      chatSessions = await _enrichChatSessions(raw);
      notifyListeners();
      return threadId;
    } catch (e) {
      reportDataError(e);
      notifyListeners();
      return null;
    }
  }

  /// Opens (or reuses) the chat thread for [listingId], then sends a
  /// pre-formatted viewing-request message with the chosen [date] and [time].
  Future<bool> sendViewingRequest({
    required String listingId,
    required DateTime date,
    required TimeOfDay time,
    required String messageTemplate,
  }) async {
    try {
      final threadId = await startChatForListing(listingId);
      if (threadId == null) return false;

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute';

      final text = messageTemplate
          .replaceAll('{date}', dateStr)
          .replaceAll('{time}', timeStr);
      await sendChatMessage(threadId, text);
      return true;
    } catch (e) {
      reportDataError(e);
      notifyListeners();
      return false;
    }
  }

  /// Opens (or reuses) a direct chat thread between the poster and an
  /// applicant for a hiring application.
  Future<String?> startChatForApplication({
    required String applicantId,
    required String posterId,
  }) async {
    try {
      if (_repo == null) {
        dataError = s.errorSupabaseUnavailable;
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateApplicationThread(
        applicantId: applicantId,
        posterId: posterId,
      );
      final raw = await _repo!.fetchChatSessions();
      chatSessions = await _enrichChatSessions(raw);
      notifyListeners();
      return threadId;
    } catch (e) {
      reportDataError(e);
      notifyListeners();
      return null;
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String reason,
    String? listingId,
    String? serviceId,
    String? hiringPostId,
    String? reportedUserId,
    String? targetType,
    String? details,
  }) async {
    if (_repo == null) return;
    await _repo!.submitReport(
      reason: reason,
      listingId: listingId,
      serviceId: serviceId,
      hiringPostId: hiringPostId,
      reportedUserId: reportedUserId,
      targetType: targetType,
      details: details,
    );
  }
}
