part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyBar extends StatefulWidget {
  final Listing listing;
  final OnemarketAppState state;
  const _StickyBar({required this.listing, required this.state});

  @override
  State<_StickyBar> createState() => _StickyBarState();
}

class _StickyBarState extends State<_StickyBar> {
  bool _chatLoading = false;

  Future<void> _openChat() async {
    final state = widget.state;
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
      if (idx != -1) {
        state.pushScreen(ActiveChatScreenRoute(idx));
        return;
      }
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
      builder: (_) =>
          _ViewingRequestSheet(listing: widget.listing, state: widget.state),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.state.s;
    final listing = widget.listing;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.detailTrustChat,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                      color: cs.primary,
                    ),
                    label: Text(
                      listing.category == 'SKILLS'
                          ? s.detailRequestHire
                          : s.detailViewProperty,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _chatLoading ? null : _openChat,
                    icon: _chatLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      s.detailChat,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerListingActions extends StatelessWidget {
  final Listing listing;
  final OnemarketAppState state;

  const _OwnerListingActions({required this.listing, required this.state});

  Future<void> _toggleAvailability(BuildContext context) async {
    final hidden = !listing.isHidden;
    if (hidden) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(state.s.listingUnlistAction),
          content: Text(state.s.listingUnavailableBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(state.s.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(state.s.listingUnlistAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await state.setListingHidden(listing.id, hidden);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.s.deleteListingTitle),
        content: Text(state.s.deleteListingBody(listing.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.s.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(state.s.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteListing(listing.id);
      if (context.mounted) state.popScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = listing.isHidden
        ? state.s.listingListAction
        : state.s.listingUnlistAction;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.s.listingMyAd,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _toggleAvailability(context),
            icon: Icon(
              listing.isHidden
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _delete(context),
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            label: Text(
              state.s.commonDelete,
              style: TextStyle(color: cs.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
