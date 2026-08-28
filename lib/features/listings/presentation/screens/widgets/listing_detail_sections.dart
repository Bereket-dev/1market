part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Info section  – price, title, location, verified badge
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Listing listing;
  final OnemarketAppState state;
  const _InfoSection({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Price + verified ───────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  listing.price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimary,
                  ),
                ),
              ),
              if (listing.verified) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kVerifiedBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kVerifiedColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 15, color: kVerifiedColor),
                      const SizedBox(width: 4),
                      Text(
                        state.s.detailVerified,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kVerifiedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Title (+ translated badge if applicable) ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.titleForLocale(state.locale),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              if (listing.isTranslatedFor(state.locale)) ...[
                const SizedBox(width: 8),
                _TranslatedBadge(s: state.s),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Location ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specs bento grid  – renders only the spec slots that have data (up to 4)
// ─────────────────────────────────────────────────────────────────────────────

class _SpecsSection extends StatelessWidget {
  final Listing listing;
  const _SpecsSection({required this.listing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = OnemarketAppStateScope.of(context).s;

    // Collect only the slots that are fully populated
    final specs = <({String label, String value})>[];
    void add(String? l, String? v) {
      if (l != null && l.isNotEmpty && v != null && v.isNotEmpty) {
        specs.add((label: l, value: v));
      }
    }

    add(listing.spec1Label, listing.spec1Value);
    add(listing.spec2Label, listing.spec2Value);
    add(listing.spec3Label, listing.spec3Value);
    add(listing.spec4Label, listing.spec4Value);

    if (specs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailSpecs,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Pair specs into rows of 2
          for (int i = 0; i < specs.length; i += 2) ...[
            Row(
              children: [
                Expanded(
                  child: _BentoBox(
                    label: specs[i].label,
                    value: specs[i].value,
                    icon: iconForSpec(specs[i].label),
                  ),
                ),
                if (i + 1 < specs.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoBox(
                      label: specs[i + 1].label,
                      value: specs[i + 1].value,
                      icon: iconForSpec(specs[i + 1].label),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
            if (i + 2 < specs.length) const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description section
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final Listing listing;
  final OnemarketAppState state;
  const _DescriptionSection({required this.listing, required this.state});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final s    = widget.state.s;
    final text = widget.listing
        .descriptionForLocale(widget.state.locale)
        .trim();

    if (text.isEmpty) return const SizedBox.shrink();

    const kCollapsedLines = 4;
    final isLong = text.length > 200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailDescription,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            maxLines: _expanded ? null : kCollapsedLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map section  – schematic map + location label + open-in-maps action
// ─────────────────────────────────────────────────────────────────────────────

class _MapSection extends StatelessWidget {
  final Listing listing;
  final OnemarketAppState state;
  const _MapSection({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = state.s;

    if (listing.location.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailLocationLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    listing.location,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
