import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/application.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/sync_status_badge.dart';

/// Shows all applicants for a specific hiring post (poster's view).
///
/// Tapping a row opens [HiringApplicantDetailScreen] and auto-marks the
/// application as "reviewed" (if it was still "submitted").
/// Status changes (accept / reject / back-to-review) are done from the
/// detail screen only — the list only shows the current status as a badge.
class HiringApplicantListScreen extends StatefulWidget {
  final String postId;
  const HiringApplicantListScreen({super.key, required this.postId});

  @override
  State<HiringApplicantListScreen> createState() =>
      _HiringApplicantListScreenState();
}

class _HiringApplicantListScreenState
    extends State<HiringApplicantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;
  bool _loadStarted = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final state = KoolanAppStateScope.of(context);
    final hasCached =
        state.getApplicationsForPost(widget.postId).isNotEmpty;
    setState(() {
      _loading = !hasCached;
      _errorMessage = null;
    });
    try {
      final apps = await state.loadApplicationsForPost(widget.postId);
      if (apps.isNotEmpty) {
        state.updateHiringPostApplicantCount(widget.postId, apps.length);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens the detail screen. If the application was "submitted", auto-mark
  /// it as "reviewed" so the poster's action is recorded.
  Future<void> _openDetail(
    KoolanAppState state,
    Application app,
  ) async {
    if (app.status == ApplicationStatus.submitted) {
      await state.updateApplicationStatus(
        applicationId: app.id,
        hiringPostId: widget.postId,
        newStatus: ApplicationStatus.reviewed,
      );
    }
    if (mounted) {
      state.pushScreen(
        HiringApplicantDetailScreenRoute(
          applicationId: app.id,
          postId: widget.postId,
        ),
      );
    }
  }

  List<Application> _filter(List<Application> apps) {
    if (_searchQuery.isEmpty) return apps;
    final q = _searchQuery.toLowerCase();
    return apps.where((a) {
      return (a.applicantName ?? '').toLowerCase().contains(q) ||
          (a.serviceName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final post = state.getHiringPostById(widget.postId);
    final applications =
        _filter(state.getApplicationsForPost(widget.postId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.hiringApplicantListTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Post title hint ───────────────────────────────────────────
          if (post != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
            ),
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: s.hiringBrowseSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
            ),
          ),
          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && applications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off,
                                  size: 48,
                                  color: cs.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                s.hiringNoApplicantsYet,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  _loadStarted = false;
                                  _load();
                                },
                                icon: const Icon(Icons.refresh,
                                    size: 18),
                                label: Text(s.commonRetry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : applications.isEmpty
                        ? Center(
                            child: Text(
                              s.hiringNoApplicantsYet,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: applications.length,
                            separatorBuilder: (context2, idx) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _ApplicantRow(
                              application: applications[index],
                              onTap: () => _openDetail(
                                state,
                                applications[index],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Applicant row ─────────────────────────────────────────────────────────────

class _ApplicantRow extends StatelessWidget {
  final Application application;
  final VoidCallback onTap;

  const _ApplicantRow({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final displayName =
        application.applicantName ?? s.reviewsFallbackUserName;
    final serviceName =
        application.serviceName ?? s.profileMyServices;

    final statusColor = switch (application.status) {
      ApplicationStatus.submitted => cs.primary,
      ApplicationStatus.reviewed => cs.tertiary,
      ApplicationStatus.accepted => Colors.green,
      ApplicationStatus.rejected => cs.error,
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    cs.primaryContainer.withValues(alpha: 0.4),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + service
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.applicationStatusLabel(application.status.name),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SyncStatusBadge(status: application.syncStatus),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
