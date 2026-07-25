import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
part 'widgets/service_management_list.dart';
part 'widgets/service_management_empty.dart';
part 'widgets/service_management_actions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ServiceManagementScreen
//
// This is the hub for a professional user's service profile.
//
// Context for first-time users:
//   A "service" on Koolan is your professional profile card — it tells
//   employers and clients what you do, your rate, and whether you are
//   currently available for hire. Toggling availability instantly makes you
//   discoverable (or hidden) in the marketplace search results.
//
// From here a user can:
//   • Create a new service profile
//   • Toggle availability ON/OFF for any service without opening the editor
//   • Tap a card to open the full editor (title, rate, description, CV, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class ServiceManagementScreen extends StatelessWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state    = KoolanAppStateScope.of(context);
    final s        = state.s;
    final cs       = Theme.of(context).colorScheme;
    final services = state.getMyServices();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(
          s.servicesTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => state.pushScreen(ServiceEditScreenRoute(null)),
            icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
            label: Text(
              'New Service',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ),
        ],
      ),
      body: services.isEmpty
          ? _EmptyServicesState(state: state, cs: cs)
          : _ServiceList(services: services, state: state, cs: cs),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — explains what a service is before any are created
// ─────────────────────────────────────────────────────────────────────────────
