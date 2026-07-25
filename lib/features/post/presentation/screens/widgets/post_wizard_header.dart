part of '../post_wizard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PostFormHeader extends StatelessWidget {
  final KoolanAppState state;
  final double top;
  const _PostFormHeader({required this.state, required this.top});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(4, top + 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            tooltip: state.s.wizardBack,
            onPressed: () => state.popScreen(),
          ),
          Expanded(
            child: Text(
              state.s.wizardTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Sync status badge — shows draft/pending/synced state
          if (state.isUploadingListingImages)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SyncStatusBadge(status: SyncStatus.pending),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section wrapper — renders a titled card-like grouping
// ─────────────────────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _FormSection({
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // required indicator: use the AppStrings getter (goes through _t)
    final s = KoolanAppStateScope.of(context).s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
            if (required)
              Text(
                s.wizardRequired,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DropdownOrOther
//
// A dropdown that shows a list of translated options plus a final "Other…"
// option. When "Other…" is selected the dropdown collapses and a TextFormField
// appears so the user can type a custom value.
//
// The [value] / [onChanged] pair track the *internal* state value — the caller
// stores it in AppState. When value equals [_otherSentinel] the free-text
// field is active.
// ─────────────────────────────────────────────────────────────────────────────

const String _otherSentinel = '__other__';

