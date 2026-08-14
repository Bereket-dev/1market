import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_strings.dart';
import '../services/app_state.dart';

/// Stale-while-revalidate banner shown below the home app bar.
///
/// States:
/// - **Refreshing**: subtle grey chip with a tiny spinner — "Refreshing…"
/// - **Offline + stale**: amber chip — "Offline · saved listings"
/// - **Just synced**: brief green chip — "Updated just now" (auto-fades after 3 s)
/// - **Hidden**: renders nothing (initial load or data is fresh and idle)
///
/// The banner is intentionally low-height and non-intrusive.  It does not
/// block the content beneath it.
///
/// Usage — place directly inside the home screen body above the feed:
/// ```dart
/// const SyncStatusBanner(),
/// ```
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner>
    with SingleTickerProviderStateMixin {
  Timer? _fadeTimer;
  bool _showJustSynced = false;

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s     = state.s;
    final cs    = Theme.of(context).colorScheme;
    final isDark = state.isDarkMode;

    // ── Refreshing ────────────────────────────────────────────────────────
    if (state.isRefreshing) {
      return _Chip(
        icon: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
        label: s.syncBannerRefreshing,
        bg: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.7)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        fg: cs.onSurfaceVariant,
      );
    }

    // ── Offline with cached data ──────────────────────────────────────────
    // dataError contains errorOfflineCached when serving from cache offline.
    if (state.dataError == s.errorOfflineCached) {
      return _Chip(
        icon: Icon(Icons.wifi_off_rounded,
            size: 13, color: cs.onTertiaryContainer),
        label: s.syncBannerOffline,
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
      );
    }

    // ── Just synced flash ─────────────────────────────────────────────────
    // Trigger when lastSuccessfulSyncAt is within 4 seconds of now.
    final lastSync = state.lastSuccessfulSyncAt;
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inSeconds < 4) {
      if (!_showJustSynced) {
        _showJustSynced = true;
        _fadeTimer?.cancel();
        _fadeTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showJustSynced = false);
        });
      }
    }
    if (_showJustSynced) {
      return _Chip(
        icon: Icon(Icons.check_circle_outline_rounded,
            size: 13, color: cs.onSecondaryContainer),
        label: _updatedAgoLabel(lastSync, s),
        bg: cs.secondaryContainer,
        fg: cs.onSecondaryContainer,
      );
    }

    // ── Nothing to show ───────────────────────────────────────────────────
    return const SizedBox.shrink();
  }

  String _updatedAgoLabel(DateTime? ts, AppStrings s) {
    if (ts == null) return s.syncBannerJustUpdated;
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return s.syncBannerJustUpdated;
    if (diff.inMinutes < 60) {
      return s.syncBannerUpdatedMinutesAgo(diff.inMinutes);
    }
    return s.syncBannerJustUpdated;
  }
}

/// Internal pill-shaped chip used by [SyncStatusBanner].
class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final Widget icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    height: 1.1,
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
