import 'package:flutter/material.dart';

/// Small pill badge that signals a verified listing or seller.
/// Uses a semi-transparent surface so it reads over any photo.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // Semi-transparent surface — visible on both light and dark photos
        color: cs.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: cs.tertiary, size: 14),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact circular verified checkmark overlay (for card thumbnails).
class VerifiedDot extends StatelessWidget {
  const VerifiedDot({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 9,
      backgroundColor: cs.tertiary,
      child: Icon(Icons.check, size: 11, color: cs.onTertiary),
    );
  }
}
