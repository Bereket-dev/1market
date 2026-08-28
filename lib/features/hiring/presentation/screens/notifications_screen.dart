import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';

/// In-app notifications screen.
///
/// Shows all notifications for the current user, newest first.
/// Each notification is labelled with its type (new application vs status
/// change) and can be tapped to deep-link to the relevant screen:
///   - 'new_application' → HiringApplicantListScreen for that post.
///   - 'status_changed'  → MyApplicationsScreen.
///
/// Unread notifications are highlighted; tapping marks them read.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final notifications = state.notifications;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.notificationsTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.notificationsEmpty,
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(notification: n);
              },
            ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    final id = notification['id'] as String? ?? '';
    final type = notification['type'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['is_read'] as bool? ?? false;
    final createdAt = notification['created_at'] as String?;
    final payload =
        (notification['payload'] as Map<String, dynamic>?) ?? {};

    // Icon and colour per notification type.
    final IconData icon;
    final Color iconColor;
    switch (type) {
      case 'new_application':
        icon = Icons.person_add_outlined;
        iconColor = cs.primary;
      case 'new_listing_nearby':
        icon = Icons.location_on_outlined;
        iconColor = cs.secondary;
      case 'new_message':
        icon = Icons.chat_bubble_outline;
        iconColor = cs.tertiary;
      default: // status_changed and any future types
        icon = Icons.update_outlined;
        iconColor = cs.tertiary;
    }

    return InkWell(
      onTap: () {
        // Mark read first.
        if (!isRead && id.isNotEmpty) {
          state.markNotificationRead(id);
        }
        // Deep-link based on payload.
        final screen = payload['screen'] as String?;
        if (screen == 'listing_detail') {
          final listingId = payload['listingId'] as String?;
          if (listingId != null && listingId.isNotEmpty) {
            state.pushScreen(ListingDetailScreenRoute(listingId));
          }
        } else if (screen == 'chat') {
          final threadId = payload['threadId'] as String?;
          if (threadId != null && threadId.isNotEmpty) {
            final index =
                state.chatSessions.indexWhere((s) => s.id == threadId);
            if (index != -1) {
              state.pushScreen(ActiveChatScreenRoute(index));
            }
          }
        } else if (screen == 'applicantList') {
          final postId = payload['hiringPostId'] as String?;
          if (postId != null && postId.isNotEmpty) {
            state.pushScreen(HiringApplicantListScreenRoute(postId));
          }
        } else if (screen == 'myApplications') {
          state.pushScreen(MyApplicationsScreenRoute());
        } else if (screen == 'hiring_detail') {
          final postId = payload['postId'] as String?;
          if (postId != null && postId.isNotEmpty) {
            state.pushScreen(HiringDetailScreenRoute(postId));
          }
        } else if (screen == 'service_detail') {
          final serviceId = payload['serviceId'] as String?;
          if (serviceId != null && serviceId.isNotEmpty) {
            state.pushScreen(ServiceDetailScreenRoute(serviceId));
          }
        }
      },
      child: Container(
        color: isRead
            ? Colors.transparent
            : cs.primaryContainer.withValues(alpha: 0.12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ────────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // ── Text content ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — also acts as the text label so the control
                  // is never icon-only.
                  Text(
                    title.isNotEmpty ? title : s.notificationsTitle,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt, state.s),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Unread dot ──────────────────────────────────────────
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            // ── Mark-read button (labelled for accessibility) ───────
            if (!isRead && id.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => state.markNotificationRead(id),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  s.notificationMarkRead,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso, AppStrings s) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return s.reviewsTimeAgoJustNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
