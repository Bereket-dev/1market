import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/permission_service.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Icon ─────────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: cs.primary, size: 36),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              Text(
                s.locationTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Body copy ────────────────────────────────────────────────
              Text(
                s.locationBody,
                style:
                    TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              // ── Notification permission note ──────────────────────────────
              _PermissionRow(
                icon: Icons.notifications_active_outlined,
                label: 'Receive alerts for new listings and messages',
                cs: cs,
              ),
              const SizedBox(height: 8),
              _PermissionRow(
                icon: Icons.near_me_rounded,
                label: 'Show nearby listings relevant to you',
                cs: cs,
              ),

              const Spacer(),

              // ── Allow button ─────────────────────────────────────────────
              FilledButton(
                onPressed: _isRequesting ? null : () => _onAllow(state),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.locationContinue),
              ),
              const SizedBox(height: 12),

              // ── Skip button ───────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: _isRequesting
                      ? null
                      : () => state.completeLocationOnboarding(),
                  child: Text(s.locationSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAllow(OnemarketAppState state) async {
    setState(() => _isRequesting = true);

    // Request location permission and GPS position.
    final position =
        await PermissionService.requestLocationPermissionAndGetPosition();

    // Request notification permission (token stored later in _initPushNotifications).
    final token =
        await PermissionService.requestNotificationPermissionAndGetToken();
    if (token == null) {
      await state.toggleNotifPush(false);
    }

    if (!mounted) return;
    setState(() => _isRequesting = false);

    // Pass real GPS coordinates to app_state.
    await state.completeLocationOnboarding(
      lat: position?.latitude,
      lng: position?.longitude,
      fcmToken: token,
    );
  }
}

// ── Small permission bullet row ───────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
