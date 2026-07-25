part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyBar extends StatefulWidget {
  final Listing listing;
  final KoolanAppState state;
  const _StickyBar({required this.listing, required this.state});

  @override
  State<_StickyBar> createState() => _StickyBarState();
}

class _StickyBarState extends State<_StickyBar> {
  bool _chatLoading = false;

  Future<void> _openChat() async {
    final state   = widget.state;
    final listing = widget.listing;

    if (!state.isSignedIn) {
      if (!mounted) return;
      showAuthGateSheet(context, reason: AuthGateReason.chat);
      return;
    }

    // Fast path: thread already exists.
    final existing = state.getSessionForListing(listing.id);
    if (existing != null) {
      final idx = state.chatSessions.indexWhere((s) => s.id == existing.id);
      if (idx != -1) { state.pushScreen(ActiveChatScreenRoute(idx)); return; }
    }

    // Slow path: create thread.
    if (!mounted) return;
    setState(() => _chatLoading = true);
    final threadId = await state.startChatForListing(listing.id);
    if (!mounted) return;
    setState(() => _chatLoading = false);
    if (threadId != null) {
      final idx = state.chatSessions.indexWhere((s) => s.id == threadId);
      if (idx != -1) state.pushScreen(ActiveChatScreenRoute(idx));
    }
  }

  Future<void> _openViewingSheet() async {
    if (!widget.state.isSignedIn) {
      showAuthGateSheet(context, reason: AuthGateReason.chat);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ViewingRequestSheet(
        listing: widget.listing,
        state: widget.state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final s       = widget.state.s;
    final listing = widget.listing;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
              top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chatLoading ? null : _openChat,
                icon: _chatLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      )
                    : Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: cs.primary),
                label: Text(s.detailChat,
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: cs.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: listing.category == 'SKILLS'
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.detailRequestLogged)),
                        )
                    : _openViewingSheet,
                icon: Icon(
                  listing.category == 'SKILLS'
                      ? Icons.handshake_outlined
                      : Icons.calendar_month_outlined,
                  size: 18,
                ),
                label: Text(
                  listing.category == 'SKILLS'
                      ? s.detailRequestHire
                      : s.detailViewProperty,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
