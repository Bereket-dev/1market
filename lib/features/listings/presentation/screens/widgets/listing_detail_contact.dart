part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Contact actions card — Call + Request Call
// ─────────────────────────────────────────────────────────────────────────────

class _ContactActions extends StatefulWidget {
  final Listing listing;
  final String? resolvedPhone;
  final bool fetchingPhone;

  const _ContactActions({
    required this.listing,
    required this.resolvedPhone,
    required this.fetchingPhone,
  });

  @override
  State<_ContactActions> createState() => _ContactActionsState();
}

class _ContactActionsState extends State<_ContactActions> {
  bool _requestCallLoading = false;

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.listing.sellerPhone ?? phone)),
      );
    }
  }

  Future<void> _requestCall() async {
    final state = OnemarketAppStateScope.of(context);
    final s     = state.s;

    if (!state.isSignedIn) {
      showAuthGateSheet(context, reason: AuthGateReason.requestCall);
      return;
    }

    setState(() => _requestCallLoading = true);

    String? threadId =
        state.getSessionForListing(widget.listing.id)?.id;
    threadId ??= await state.startChatForListing(widget.listing.id);

    if (!mounted) return;

    if (threadId == null) {
      setState(() => _requestCallLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.detailRequestCallFailed)));
      return;
    }

    try {
      await state.sendChatMessage(threadId, s.detailRequestCallMessage);
      if (!mounted) return;
      setState(() => _requestCallLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.detailRequestCallSent)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _requestCallLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.detailRequestCallFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final s     = OnemarketAppStateScope.of(context).s;
    final phone = widget.resolvedPhone;

    if (!widget.fetchingPhone && (phone == null || phone.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone_rounded,
                    color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(s.detailContactDetailsTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.fetchingPhone)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(s.detailFetchingPhone,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 15, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(phone!,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                  ],
                ),
              ),
            if (!widget.fetchingPhone && phone != null && phone.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(s.detailCallSeller,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _requestCallLoading ? null : _requestCall,
                      icon: _requestCallLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: cs.primary),
                            )
                          : Icon(Icons.phone_callback_rounded,
                              size: 18, color: cs.primary),
                      label: Text(s.detailRequestCall,
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: cs.primary),
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
