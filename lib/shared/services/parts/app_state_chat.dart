// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Chat & reports ────────────────────────────────────────────────────────────

extension AppStateChat on KoolanAppState {
  Future<void> sendChatMessage(String sessionId, String text) async {
    if (text.trim().isEmpty) return;
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }
      final msg = await _repo!.sendMessage(threadId: sessionId, text: text);
      final session = chatSessions[index];
      final newTotal = session.totalMessages + 1;
      final shouldReveal = !session.contactRevealed && newTotal >= 3;
      chatSessions[index] = session.copyWith(
        messages: [...session.messages, msg],
        unreadCount: 0,
        totalMessages: newTotal,
        contactRevealed: shouldReveal ? true : session.contactRevealed,
      );
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Explicitly reveals contact details for [sessionId].
  void revealContactForThread(String sessionId) {
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = chatSessions[index];
    if (session.contactRevealed) return;
    chatSessions[index] = session.copyWith(contactRevealed: true);
    notifyListeners();
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
        dataError = 'Supabase unavailable';
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateThread(
        listingId: listingId,
        sellerId: listing.sellerId!,
      );
      chatSessions = await _repo!.fetchChatSessions();
      notifyListeners();
      return threadId;
    } catch (e) {
      dataError = e.toString();
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
      dataError = e.toString();
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
        dataError = 'Supabase unavailable';
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateApplicationThread(
        applicantId: applicantId,
        posterId: posterId,
      );
      chatSessions = await _repo!.fetchChatSessions();
      notifyListeners();
      return threadId;
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String reason,
    String? listingId,
    String? reportedUserId,
    String? details,
  }) async {
    if (_repo == null) return;
    await _repo!.submitReport(
      reason: reason,
      listingId: listingId,
      reportedUserId: reportedUserId,
      details: details,
    );
  }
}
