import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Small pill badge that signals a verified listing or seller.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: kVerifiedColor, size: 14),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
    return const CircleAvatar(
      radius: 9,
      backgroundColor: kVerifiedColor,
      child: Icon(Icons.check, size: 11, color: Colors.white),
    );
  }
}
