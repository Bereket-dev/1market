import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

/// Small horizontal card showing a recent verified activity in the community.
class TrustBadgeCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const TrustBadgeCard({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const Positioned(
                bottom: -2,
                right: -2,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: kVerifiedColor,
                  child: Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
