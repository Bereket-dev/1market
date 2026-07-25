part of '../hiring_applicant_detail_screen.dart';

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: cs.primary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    final color = switch (status) {
      ApplicationStatus.submitted => cs.primary,
      ApplicationStatus.reviewed => cs.tertiary,
      ApplicationStatus.accepted => Colors.green,
      ApplicationStatus.rejected => cs.error,
    };
    final icon = switch (status) {
      ApplicationStatus.submitted => Icons.send_outlined,
      ApplicationStatus.reviewed => Icons.visibility_outlined,
      ApplicationStatus.accepted => Icons.check_circle_outline,
      ApplicationStatus.rejected => Icons.cancel_outlined,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                s.applicationStatusLabel(status.name),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String applicantName;
  final String? avatarUrl;
  final UserProfile? profile;
  final DateTime submittedAt;
  final String submittedLabel;

  const _ProfileCard({
    required this.applicantName,
    this.avatarUrl,
    this.profile,
    required this.submittedAt,
    required this.submittedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = applicantName.isNotEmpty
        ? applicantName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedImageWidget(
                    imageUrl: avatarUrl!,
                    width: 60,
                    height: 60,
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        cs.primaryContainer.withValues(alpha: 0.5),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verification
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        applicantName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Profile rating if available
                    if (profile != null && profile!.rating > 0) ...[
                      RatingStars(
                        rating: profile!.rating,
                        reviewCount: profile!.reviewsCount,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // City if available
                if (profile?.city != null && profile!.city!.isNotEmpty)
                  Text(
                    profile!.city!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                // Submitted date
                Text(
                  '$submittedLabel: ${_formatDate(submittedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Service service;
  final String cvLabel;
  final String viewCvLabel;
  final String noCvLabel;
  final String experienceLabel;
  final void Function(String url) onViewCv;

  const _ServiceCard({
    required this.service,
    required this.cvLabel,
    required this.viewCvLabel,
    required this.noCvLabel,
    required this.experienceLabel,
    required this.onViewCv,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + category
          Text(
            service.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Chip(label: service.category, color: cs.primary),
              const SizedBox(width: 8),
              if (service.availability)
                _Chip(
                  label: '✓ Available',
                  color: Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          if (service.description.isNotEmpty) ...[
            Text(
              service.description,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Cover description / pitch
          if (service.coverDescription.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                '"${service.coverDescription}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Detail rows
          _LabelValue(
            label: experienceLabel,
            value: '${service.yearsOfExperience} yrs',
          ),
          const SizedBox(height: 4),
          _LabelValue(
            label: 'Price',
            value: service.priceRange,
          ),
          const SizedBox(height: 4),
          _LabelValue(
            label: 'Location',
            value: service.location,
          ),
          const SizedBox(height: 12),
          // CV row
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                cvLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (service.cvFileUrl != null &&
                  service.cvFileUrl!.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => onViewCv(service.cvFileUrl!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(viewCvLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                )
              else
                Text(
                  noCvLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Review row ────────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final ServiceReview review;
  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = review.reviewerName ?? 'User';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
              backgroundImage: review.reviewerAvatarUrl != null
                  ? NetworkImage(review.reviewerAvatarUrl!)
                  : null,
              child: review.reviewerAvatarUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Star rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 13,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

