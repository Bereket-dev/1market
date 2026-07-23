import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ToastBanner
//
// A self-dismissing floating toast that:
//   • Slides in from the top with a spring curve.
//   • Shows a hairline progress bar that drains over [duration].
//   • Has an X button to dismiss immediately.
//   • Calls [onDismiss] when it goes away (either automatically or manually).
// ─────────────────────────────────────────────────────────────────────────────

enum ToastType { error, warning, info, success }

class ToastBanner extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ToastBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.type = ToastType.error,
    this.duration = const Duration(seconds: 5),
    this.actionLabel,
    this.onAction,
  });

  @override
  State<ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<ToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  // Tracks how much of the progress bar has drained (1.0 → 0.0).
  double _progress = 1.0;
  Timer? _drainTimer;
  Timer? _dismissTimer;
  bool _dismissing = false;

  static const _tickMs = 30; // update every 30 ms

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();
    _startDrain();
  }

  void _startDrain() {
    final totalTicks =
        widget.duration.inMilliseconds ~/ _tickMs;
    int ticks = 0;

    _drainTimer = Timer.periodic(
      Duration(milliseconds: _tickMs),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        ticks++;
        setState(() {
          _progress = 1.0 - (ticks / totalTicks).clamp(0.0, 1.0);
        });
        if (ticks >= totalTicks) {
          t.cancel();
          _dismiss();
        }
      },
    );
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _drainTimer?.cancel();
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _drainTimer?.cancel();
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bgColor, barColor, iconData) = switch (widget.type) {
      ToastType.error   => (
          isDark
              ? const Color(0xFF3B1A1A)
              : const Color(0xFFFFF0F0),
          cs.error,
          Icons.wifi_off_rounded,
        ),
      ToastType.warning => (
          isDark
              ? const Color(0xFF2E2500)
              : const Color(0xFFFFF9E6),
          Colors.orange,
          Icons.warning_amber_rounded,
        ),
      ToastType.info    => (
          isDark
              ? const Color(0xFF0D1F35)
              : const Color(0xFFEFF6FF),
          cs.primary,
          Icons.info_outline_rounded,
        ),
      ToastType.success => (
          isDark
              ? const Color(0xFF0A2318)
              : const Color(0xFFEDFDF5),
          Colors.green,
          Icons.check_circle_outline_rounded,
        ),
    };

    final borderColor = barColor.withValues(alpha: isDark ? 0.35 : 0.25);
    final textColor   = isDark ? Colors.white : cs.onSurface;
    final subColor    = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : cs.onSurfaceVariant;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Body row ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData,
                              color: barColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        // Message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.actionLabel != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    widget.onAction?.call();
                                    _dismiss();
                                  },
                                  child: Text(
                                    widget.actionLabel!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: barColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // X button
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 15, color: subColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Draining progress bar ─────────────────────────────
                  SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: barColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
