import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// A soft dismissible banner that re-prompts the user to grant location
/// permission after they skipped during onboarding.
///
/// Visibility is controlled entirely by [KoolanAppState.showLocationCta].
/// Dismissed state is persisted via [KoolanAppState.snoozeLocationCta]
/// (3-day snooze) so the banner doesn't spam the user on every open.
///
/// Usage: place this widget near the top of the scrollable home body.
/// It renders nothing when [showLocationCta] is false.
class LocationCtaBanner extends StatefulWidget {
  const LocationCtaBanner({super.key});

  @override
  State<LocationCtaBanner> createState() => _LocationCtaBannerState();
}

class _LocationCtaBannerState extends State<LocationCtaBanner> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Check snooze state after first frame so SharedPreferences can be read
    // without blocking the build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        KoolanAppStateScope.of(context).checkLocationCtaVisibility();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);

    if (!state.showLocationCta) return const SizedBox.shrink();

    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location icon ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_rounded,
                  color: cs.onSecondaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ── Text + action buttons ─────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.locationCtaTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.locationCtaBody,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSecondaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Allow button
                        FilledButton.tonal(
                          onPressed: _loading ? null : () => _onAllow(state),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600),
                          ),
                          child: _loading
                              ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onSecondaryContainer,
                                  ),
                                )
                              : Text(s.locationCtaAllow),
                        ),
                        const SizedBox(width: 8),
                        // Not now button
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => state.snoozeLocationCta(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500),
                            foregroundColor: cs.onSecondaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          child: Text(s.locationCtaDismiss),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Close icon (same as Dismiss) ──────────────────────────────
              IconButton(
                icon: Icon(Icons.close,
                    size: 18,
                    color: cs.onSecondaryContainer.withValues(alpha: 0.6)),
                onPressed: _loading ? null : () => state.snoozeLocationCta(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAllow(KoolanAppState state) async {
    setState(() => _loading = true);
    await state.grantLocationFromCta();
    if (mounted) setState(() => _loading = false);
  }
}
