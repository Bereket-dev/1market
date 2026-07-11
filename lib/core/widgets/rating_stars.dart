import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Displays a star rating with optional review count.
class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final String? reviewLabel;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.reviewLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          reviewCount != null
              ? '$rating (${reviewCount!} ${reviewLabel ?? 'reviews'})'
              : '$rating',
          style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant),
        ),
      ],
    );
  }
}
