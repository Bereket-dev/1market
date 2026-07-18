import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/services/app_state.dart';

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
    final state = KoolanAppStateScope.of(context);
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
              Text(
                s.locationTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.locationBody,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isRequesting
                    ? null
                    : () async {
                        setState(() => _isRequesting = true);
                        await _requestLocationPermission();
                        if (!mounted) return;
                        setState(() => _isRequesting = false);
                        await state.completeLocationOnboarding();
                      },
                child: Text(_isRequesting ? s.locationRequesting : s.locationContinue),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isRequesting
                      ? null
                      : () async {
                          await state.completeLocationOnboarding();
                        },
                  child: Text(s.locationSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      return;
    }
  }
}
