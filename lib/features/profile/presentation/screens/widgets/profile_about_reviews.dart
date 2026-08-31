part of '../profile_screen.dart';

// ── About section (always visible in profile header) ─────────────────────────

class _ProfileAboutSection extends StatelessWidget {
  final String? bio;
  final String? preferredCategory;
  final VoidCallback onEdit;

  const _ProfileAboutSection({
    required this.bio,
    required this.preferredCategory,
    required this.onEdit,
  });

  String? _categoryLabel(dynamic s, String? code) {
    if (code == null || code.isEmpty) return null;
    return switch (code) {
      'CARS' => s.homeCategoryCars,
      'HOUSES' => s.homeCategoryHouses,
      'LAND' => s.homeCategoryLand,
      'SKILLS' => s.homeCategorySkills,
      'OTHERS' => s.homeCategoryOthers,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;
    final hasBio = bio != null && bio!.trim().isNotEmpty;
    final categoryLabel = _categoryLabel(s, preferredCategory);

    final tags = <String>[
      ?categoryLabel,
      s.profileVerifiedBadge,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              hasBio ? bio!.trim() : s.profileAddBio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: hasBio
                    ? cs.onSurfaceVariant
                    : cs.onSurfaceVariant.withValues(alpha: 0.65),
                fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: Icon(Icons.edit_outlined, size: 14, color: cs.primary),
          label: Text(
            s.editProfileTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reviews tab (real data) ───────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final OnemarketAppState state;
  const _ReviewsTab({required this.state});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  bool _loading = false;
  List<ServiceReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final services = widget.state.getMyServices();
    if (services.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Fetch all services' reviews in parallel — one await for all.
    final results = await Future.wait(
      services.map((svc) => widget.state.loadReviewsForService(svc.id)),
    );
    final all = results.expand((r) => r).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() { _reviews = all; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.state.s;

    if (_loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    if (_reviews.isEmpty) {
      return Column(children: [
        const SizedBox(height: 24),
        Icon(Icons.rate_review_outlined,
            size: 48, color: cs.primary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(s.reviewsEmpty,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
      ]);
    }

    return Column(
      children: _reviews.map((review) {
        final name = review.reviewerName ?? s.reviewsFallbackUserName;
        final timeAgo = _formatTime(review.createdAt, s);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ReviewCard(
            name: name,
            date: timeAgo,
            comment: review.comment,
            rating: review.rating.toDouble(),
            avatarUrl: review.reviewerAvatarUrl,
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt, s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return s.reviewsTimeAgoYears(diff.inDays ~/ 365);
    if (diff.inDays >= 30) return s.reviewsTimeAgoMonths(diff.inDays ~/ 30);
    if (diff.inDays >= 1) return s.reviewsTimeAgoDays(diff.inDays);
    if (diff.inHours >= 1) return s.reviewsTimeAgoHours(diff.inHours);
    return s.reviewsTimeAgoJustNow;
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String comment;
  final double rating;
  final String? avatarUrl;

  const _ReviewCard({
    required this.name,
    required this.date,
    required this.comment,
    required this.rating,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.35),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Text(name[0].toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: cs.primary))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: cs.onSurface)),
                  Text(date,
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                ]),
              ]),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: cs.onSurface)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
        ]),
      ),
    );
  }
}

// ── Profile action row ────────────────────────────────────────────────────────

class _ProfileActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ProfileActionRow({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface)),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

